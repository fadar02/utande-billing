import prisma from '../config/database';
import { sendEmail, emailTemplates } from './emailService';
import logger from '../utils/logger';

const ADMIN_EMAIL = 'admin@utande.com';

export class ReminderService {
  static async getReminderConfig() {
    let config = await prisma.reminderConfig.findFirst();
    if (!config) {
      config = await prisma.reminderConfig.create({ data: {} });
    }
    return config;
  }

  static async updateReminderConfig(data: {
    sevenDaysEnabled?: boolean;
    threeDaysEnabled?: boolean;
    oneDayEnabled?: boolean;
    onDueDateEnabled?: boolean;
    overdueEnabled?: boolean;
    overdueIntervalDays?: number;
    maxRetries?: number;
  }) {
    const existing = await this.getReminderConfig();
    return prisma.reminderConfig.update({
      where: { id: existing.id },
      data,
    });
  }

  static async shouldSendReminder(invoiceId: string, reminderType: string): Promise<boolean> {
    if (reminderType.startsWith('OVERDUE_')) {
      return true;
    }
    const existingReminder = await prisma.reminderLog.findFirst({
      where: {
        invoiceId,
        reminderType,
        status: { in: ['SENT', 'PENDING'] },
      },
    });
    return !existingReminder;
  }

  static async sendReminder(invoiceId: string, reminderType: string): Promise<boolean> {
    const canSend = await this.shouldSendReminder(invoiceId, reminderType);
    if (!canSend) {
      logger.debug(`Reminder already sent for invoice ${invoiceId}, type ${reminderType}`);
      return false;
    }

    const invoice = await prisma.invoice.findUnique({
      where: { id: invoiceId },
      include: { customer: true, customerService: { include: { service: true } }, items: true },
    });

    if (!invoice || invoice.status === 'PAID' || invoice.status === 'CANCELLED') {
      return false;
    }

    const reminderLog = await prisma.reminderLog.create({
      data: {
        invoiceId,
        reminderType,
        recipientEmail: invoice.customer.email,
        subject: `Payment Reminder - Invoice ${invoice.invoiceNumber}`,
      },
    });

    const reminderLabels: Record<string, string> = {
      SEVEN_DAYS_BEFORE: 'due in 7 days',
      THREE_DAYS_BEFORE: 'due in 3 days',
      ONE_DAY_BEFORE: 'due tomorrow',
      ON_DUE_DATE: 'due today',
    };
    const label = reminderLabels[reminderType] || (reminderType.startsWith('OVERDUE') ? 'overdue' : reminderType.replace(/_/g, ' ').toLowerCase());

    const serviceName = invoice.customerService?.service?.name || '';
    const items = invoice.items.map((item: any) => ({ description: item.description, quantity: item.quantity, unitPrice: Number(item.unitPrice), amount: Number(item.amount) }));
    const balance = (Number(invoice.total) - Number(invoice.amountPaid)).toString();
    const now = new Date();
    const diffMs = now.getTime() - new Date(invoice.dueDate).getTime();
    const daysOverdue = diffMs > 0 ? Math.ceil(diffMs / (1000 * 60 * 60 * 24)) : 0;

    const template = emailTemplates.paymentReminder(
      `${invoice.customer.firstName} ${invoice.customer.lastName}`,
      invoice.invoiceNumber,
      invoice.total.toString(),
      invoice.dueDate.toLocaleDateString(),
      label,
      invoiceId,
      serviceName,
      items,
      balance,
      daysOverdue
    );

    const sent = await sendEmail({
      to: invoice.customer.email,
      cc: ADMIN_EMAIL,
      subject: template.subject,
      html: template.html,
      emailType: 'REMINDER',
      relatedId: invoiceId,
    });

    await prisma.reminderLog.update({
      where: { id: reminderLog.id },
      data: {
        status: sent ? 'SENT' : 'FAILED',
        sentAt: sent ? new Date() : null,
        failedAt: sent ? null : new Date(),
      },
    });

    logger.info(`Reminder ${reminderType} for invoice ${invoice.invoiceNumber}: ${sent ? 'sent' : 'failed'}`);
    return sent;
  }

  static async processAllDueReminders(): Promise<void> {
    const now = new Date();
    const config = await this.getReminderConfig();

    const unpaidInvoices = await prisma.invoice.findMany({
      where: {
        status: { in: ['PENDING', 'PARTIALLY_PAID', 'OVERDUE'] },
      },
      include: { customer: true },
    });

    for (const invoice of unpaidInvoices) {
      const dueDate = new Date(invoice.dueDate);
      const diffTime = dueDate.getTime() - now.getTime();
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      try {
        if (config.sevenDaysEnabled && diffDays <= 7 && diffDays > 3) {
          await this.sendReminder(invoice.id, 'SEVEN_DAYS_BEFORE');
        }
        if (config.threeDaysEnabled && diffDays <= 3 && diffDays > 1) {
          await this.sendReminder(invoice.id, 'THREE_DAYS_BEFORE');
        }
        if (config.oneDayEnabled && diffDays === 1) {
          await this.sendReminder(invoice.id, 'ONE_DAY_BEFORE');
        }
        if (config.onDueDateEnabled && diffDays === 0) {
          await this.sendReminder(invoice.id, 'ON_DUE_DATE');
        }

        // Overdue: send immediately when past due, then periodically
        if (config.overdueEnabled && diffDays < 0) {
          const daysOverdue = Math.abs(diffDays);
          // Send on first day overdue, then every N days
          if (daysOverdue === 1 || daysOverdue % config.overdueIntervalDays === 0) {
            const reminderNumber = daysOverdue === 1 ? 1 : Math.floor(daysOverdue / config.overdueIntervalDays);
            await this.sendReminder(invoice.id, `OVERDUE_${reminderNumber}`);
          }
        }
      } catch (error: any) {
        logger.error(`Error processing reminder for invoice ${invoice.invoiceNumber}: ${error.message}`);
      }
    }

    logger.info(`Reminder check completed - processed ${unpaidInvoices.length} invoices`);
  }

  static async retryFailedReminders(): Promise<void> {
    const config = await this.getReminderConfig();

    const failedReminders = await prisma.reminderLog.findMany({
      where: {
        status: 'FAILED',
        retryCount: { lt: config.maxRetries },
      },
      include: { invoice: { include: { customer: true, customerService: { include: { service: true } }, items: true } } },
    });

    for (const reminder of failedReminders) {
      try {
        const serviceName = reminder.invoice.customerService?.service?.name || '';
        const items = reminder.invoice.items.map((item: any) => ({ description: item.description, quantity: item.quantity, unitPrice: Number(item.unitPrice), amount: Number(item.amount) }));
        const balance = (Number(reminder.invoice.total) - Number(reminder.invoice.amountPaid)).toString();
        const retryNow = new Date();
        const retryDiffMs = retryNow.getTime() - new Date(reminder.invoice.dueDate).getTime();
        const retryDaysOverdue = retryDiffMs > 0 ? Math.ceil(retryDiffMs / (1000 * 60 * 60 * 24)) : 0;

        const template = emailTemplates.paymentReminder(
          `${reminder.invoice.customer.firstName} ${reminder.invoice.customer.lastName}`,
          reminder.invoice.invoiceNumber,
          reminder.invoice.total.toString(),
          reminder.invoice.dueDate.toLocaleDateString(),
          reminder.reminderType.replace(/_/g, ' ').toLowerCase(),
          reminder.invoiceId,
          serviceName,
          items,
          balance,
          retryDaysOverdue
        );

        const sent = await sendEmail({
          to: reminder.recipientEmail,
          cc: ADMIN_EMAIL,
          subject: template.subject,
          html: template.html,
          emailType: 'REMINDER_RETRY',
          relatedId: reminder.invoiceId,
        });

        await prisma.reminderLog.update({
          where: { id: reminder.id },
          data: {
            status: sent ? 'SENT' : 'FAILED',
            sentAt: sent ? new Date() : undefined,
            retryCount: reminder.retryCount + 1,
            errorMessage: sent ? null : 'Retry failed',
          },
        });
      } catch (error: any) {
        await prisma.reminderLog.update({
          where: { id: reminder.id },
          data: {
            retryCount: reminder.retryCount + 1,
            errorMessage: error.message,
          },
        });
      }
    }

    logger.info(`Retried ${failedReminders.length} failed reminders`);
  }

  static async getReminderHistory(invoiceId: string) {
    return prisma.reminderLog.findMany({
      where: { invoiceId },
      orderBy: { createdAt: 'desc' },
    });
  }

  static async cancelAllRemindersForInvoice(invoiceId: string) {
    await prisma.reminderLog.updateMany({
      where: {
        invoiceId,
        status: 'PENDING',
      },
      data: { status: 'CANCELLED' },
    });
  }
}
