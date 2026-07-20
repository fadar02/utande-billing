import prisma from '../config/database';
import { sendEmail, emailTemplates } from './emailService';
import logger from '../utils/logger';

export class ServiceManagementService {
  static async suspendOverdueAccounts(): Promise<void> {
    const overdueInvoices = await prisma.invoice.findMany({
      where: {
        status: { in: ['PENDING', 'PARTIALLY_PAID', 'OVERDUE'] },
        dueDate: { lt: new Date() },
      },
      include: {
        customer: true,
        customerService: { include: { service: true } },
      },
    });

    const suspendedServices = new Set<string>();

    for (const invoice of overdueInvoices) {
      if (!invoice.customerService) continue;

      const key = `${invoice.customerId}-${invoice.customerServiceId}`;
      if (suspendedServices.has(key)) continue;

      const customerService = await prisma.customerService.findUnique({
        where: { id: invoice.customerServiceId! },
      });

      if (customerService && customerService.status === 'ACTIVE') {
        await prisma.customerService.update({
          where: { id: invoice.customerServiceId! },
          data: {
            status: 'SUSPENDED',
            suspendedAt: new Date(),
          },
        });

        await prisma.invoice.update({
          where: { id: invoice.id },
          data: { status: 'OVERDUE' },
        });

        await sendEmail({
          to: invoice.customer.email,
          ...emailTemplates.serviceSuspended(
            `${invoice.customer.firstName} ${invoice.customer.lastName}`,
            invoice.customerService?.service.name || 'Service'
          ),
          emailType: 'SERVICE_SUSPENSION',
          relatedId: invoice.customerServiceId!,
        });

        suspendedServices.add(key);
        logger.info(`Suspended service for customer ${invoice.customer.customerCode}`);
      }
    }

    logger.info(`Suspended ${suspendedServices.size} overdue services`);
  }

  static async restoreServicesAfterPayment(customerId: string): Promise<void> {
    const pendingInvoices = await prisma.invoice.findMany({
      where: {
        customerId,
        status: { in: ['PENDING', 'PARTIALLY_PAID', 'OVERDUE'] },
      },
    });

    if (pendingInvoices.length > 0) return;

    const suspendedServices = await prisma.customerService.findMany({
      where: {
        customerId,
        status: 'SUSPENDED',
      },
      include: { service: true },
    });

    for (const cs of suspendedServices) {
      await prisma.customerService.update({
        where: { id: cs.id },
        data: {
          status: 'ACTIVE',
          suspendedAt: null,
          restoreReason: 'Payment received - all invoices settled',
        },
      });

      const customer = await prisma.customer.findUnique({ where: { id: customerId } });
      if (customer) {
        await sendEmail({
          to: customer.email,
          ...emailTemplates.serviceRestored(
            `${customer.firstName} ${customer.lastName}`,
            cs.service.name
          ),
          emailType: 'SERVICE_RESTORE',
          relatedId: cs.id,
        });
      }

      logger.info(`Restored service ${cs.service.name} for customer ${customerId}`);
    }
  }
}
