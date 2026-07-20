import { Response } from 'express';
import prisma from '../config/database';
import { ReminderService } from '../services/reminderService';
import { AuthRequest } from '../middleware/auth';
import logger from '../utils/logger';

export class ReminderConfigController {
  static async getConfig(req: AuthRequest, res: Response) {
    try {
      const config = await ReminderService.getReminderConfig();
      res.json(config);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async updateConfig(req: AuthRequest, res: Response) {
    try {
      const config = await ReminderService.updateReminderConfig(req.body);
      res.json(config);
    } catch (error: any) {
      logger.error(`Update reminder config error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getReminderHistory(req: AuthRequest, res: Response) {
    try {
      const { invoiceId } = req.params;
      const history = await ReminderService.getReminderHistory(invoiceId);
      res.json(history);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getAllLogs(req: AuthRequest, res: Response) {
    try {
      const logs = await prisma.reminderLog.findMany({
        include: {
          invoice: {
            select: { invoiceNumber: true, total: true, status: true, dueDate: true, customer: { select: { firstName: true, lastName: true, email: true } } },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: 100,
      });
      res.json(logs);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async triggerNow(req: AuthRequest, res: Response) {
    try {
      await ReminderService.processAllDueReminders();
      res.json({ message: 'Reminder check completed' });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async sendManualReminder(req: AuthRequest, res: Response) {
    try {
      const { invoiceId, reminderType } = req.body;
      if (!invoiceId) {
        return res.status(400).json({ error: 'invoiceId is required' });
      }
      const type = reminderType || 'MANUAL';
      const sent = await ReminderService.sendReminder(invoiceId, type);
      if (sent) {
        res.json({ message: 'Reminder sent successfully' });
      } else {
        res.status(400).json({ error: 'Failed to send reminder' });
      }
    } catch (error: any) {
      logger.error(`Manual reminder error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
