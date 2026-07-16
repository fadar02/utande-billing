import cron from 'node-cron';
import { ReminderService } from '../services/reminderService';
import { InvoiceService } from '../services/invoiceService';
import { ServiceManagementService } from '../services/serviceManagementService';
import { retryFailedEmails } from '../services/emailService';
import logger from '../utils/logger';

export const startScheduler = () => {
  // Every hour - Check for overdue invoices and send emails
  cron.schedule('0 * * * *', async () => {
    logger.info('Running hourly overdue invoice check...');
    try {
      await InvoiceService.markOverdueInvoices();
      await ReminderService.processAllDueReminders();
    } catch (error: any) {
      logger.error(`Hourly reminder error: ${error.message}`);
    }
  });

  // Every 6 hours - Retry failed reminders
  cron.schedule('0 */6 * * *', async () => {
    logger.info('Retrying failed reminders...');
    try {
      await ReminderService.retryFailedReminders();
    } catch (error: any) {
      logger.error(`Reminder retry error: ${error.message}`);
    }
  });

  // Every 6 hours - Retry failed emails
  cron.schedule('30 */6 * * *', async () => {
    logger.info('Retrying failed emails...');
    try {
      await retryFailedEmails();
    } catch (error: any) {
      logger.error(`Email retry error: ${error.message}`);
    }
  });

  // Every hour - Suspend overdue accounts
  cron.schedule('15 * * * *', async () => {
    logger.info('Checking for overdue accounts...');
    try {
      await ServiceManagementService.suspendOverdueAccounts();
    } catch (error: any) {
      logger.error(`Account suspension error: ${error.message}`);
    }
  });

  // 1st of each month at 5:00 AM - Auto-generate monthly invoices
  cron.schedule('0 5 1 * *', async () => {
    logger.info('Generating monthly invoices...');
    try {
      await InvoiceService.autoGenerateMonthlyInvoices();
    } catch (error: any) {
      logger.error(`Invoice generation error: ${error.message}`);
    }
  });

  // Daily at 9 AM - Final overdue check and suspension
  cron.schedule('0 9 * * *', async () => {
    logger.info('Running daily overdue check...');
    try {
      await InvoiceService.markOverdueInvoices();
      await ReminderService.processAllDueReminders();
      await ServiceManagementService.suspendOverdueAccounts();
    } catch (error: any) {
      logger.error(`Daily overdue error: ${error.message}`);
    }
  });

  logger.info('Scheduler started - overdue emails check every hour');
};
