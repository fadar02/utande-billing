import { Request, Response } from 'express';
import prisma from '../config/database';
import logger from '../utils/logger';

const DEFAULT_SETTINGS: { key: string; value: string; description: string }[] = [
  { key: 'company_name', value: 'Utande', description: 'Company name used in invoices and emails' },
  { key: 'company_email', value: 'billing@utande.com', description: 'Company contact email' },
  { key: 'company_phone', value: '', description: 'Company phone number' },
  { key: 'company_address', value: '', description: 'Company physical address' },
  { key: 'currency', value: 'MWK', description: 'Default currency code' },
  { key: 'currency_symbol', value: 'MWK', description: 'Currency symbol displayed on invoices' },
  { key: 'tax_rate', value: '0', description: 'Default tax rate percentage applied to invoices' },
  { key: 'tax_enabled', value: 'false', description: 'Whether tax is enabled on invoices' },
  { key: 'default_payment_terms', value: '30', description: 'Default days until invoice payment is due' },
  { key: 'auto_generate_invoices', value: 'false', description: 'Automatically generate invoices monthly for active services' },
  { key: 'auto_generate_day', value: '1', description: 'Day of month to auto-generate invoices (1-28)' },
  { key: 'invoice_prefix', value: 'INV', description: 'Prefix for invoice numbers' },
  { key: 'payment_number_prefix', value: 'PAY', description: 'Prefix for payment receipt numbers' },
  { key: 'customer_code_prefix', value: 'CUST', description: 'Prefix for customer codes' },
  { key: 'overdue_threshold_days', value: '1', description: 'Days after due date to mark invoice as overdue' },
  { key: 'overdue_reminder_interval_days', value: '30', description: 'Days between overdue reminder re-sends' },
  { key: 'email_notifications_enabled', value: 'true', description: 'Enable email notifications for invoices and reminders' },
  { key: 'admin_email', value: 'admin@utande.com', description: 'Admin email to CC on all reminder emails' },
  { key: 'smtp_host', value: 'smtp.gmail.com', description: 'SMTP server host' },
  { key: 'smtp_port', value: '465', description: 'SMTP server port' },
  { key: 'smtp_user', value: '', description: 'SMTP username / email' },
  { key: 'smtp_from_name', value: 'Utande Billing', description: 'Sender name shown on outgoing emails' },
];

export class SettingsController {
  static async getAll(_req: Request, res: Response) {
    try {
      const settings = await prisma.systemSetting.findMany();
      const settingsMap: Record<string, string> = {};
      settings.forEach(s => { settingsMap[s.key] = s.value; });

      const result = DEFAULT_SETTINGS.map(ds => ({
        key: ds.key,
        value: settingsMap[ds.key] ?? ds.value,
        description: ds.description,
      }));

      res.json(result);
    } catch (error: any) {
      logger.error(`Get settings error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async get(req: Request, res: Response) {
    try {
      const { key } = req.params;
      const setting = await prisma.systemSetting.findUnique({ where: { key } });
      const defaultSetting = DEFAULT_SETTINGS.find(ds => ds.key === key);

      if (!setting && !defaultSetting) {
        return res.status(404).json({ error: 'Setting not found' });
      }

      res.json({
        key,
        value: setting?.value ?? defaultSetting?.value ?? '',
        description: defaultSetting?.description ?? '',
      });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async update(req: Request, res: Response) {
    try {
      const { settings } = req.body;
      if (!settings || !Array.isArray(settings)) {
        return res.status(400).json({ error: 'Settings array is required' });
      }

      const results = [];
      for (const item of settings) {
        if (!item.key || item.value === undefined) continue;
        const updated = await prisma.systemSetting.upsert({
          where: { key: item.key },
          update: { value: String(item.value) },
          create: { key: item.key, value: String(item.value) },
        });
        results.push(updated);
      }

      logger.info(`Settings updated: ${results.map(r => r.key).join(', ')}`);
      res.json({ message: 'Settings updated successfully', updated: results.length });
    } catch (error: any) {
      logger.error(`Update settings error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async reset(_req: Request, res: Response) {
    try {
      await prisma.systemSetting.deleteMany();
      logger.info('All system settings reset to defaults');
      res.json({ message: 'Settings reset to defaults' });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
