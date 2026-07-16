import { Response } from 'express';
import prisma from '../config/database';
import { AuthRequest } from '../middleware/auth';

export class ReportController {
  static async getOutstandingInvoices(req: AuthRequest, res: Response) {
    try {
      const invoices = await prisma.invoice.findMany({
        where: { status: { in: ['PENDING', 'PARTIALLY_PAID', 'OVERDUE'] } },
        include: { customer: true },
        orderBy: { dueDate: 'asc' },
      });

      const total = invoices.reduce((sum, inv) => sum + Number(inv.total) - Number(inv.amountPaid), 0);
      res.json({ invoices, total, count: invoices.length });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getPaidInvoices(req: AuthRequest, res: Response) {
    try {
      const { startDate, endDate } = req.query;
      const where: any = { status: 'PAID' };
      if (startDate || endDate) {
        where.paidDate = {};
        if (startDate) where.paidDate.gte = new Date(startDate as string);
        if (endDate) where.paidDate.lte = new Date(endDate as string);
      }

      const invoices = await prisma.invoice.findMany({
        where,
        include: { customer: true },
        orderBy: { paidDate: 'desc' },
      });

      const total = invoices.reduce((sum, inv) => sum + Number(inv.total), 0);
      res.json({ invoices, total, count: invoices.length });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getOverdueInvoices(req: AuthRequest, res: Response) {
    try {
      const invoices = await prisma.invoice.findMany({
        where: { status: { in: ['OVERDUE', 'PENDING', 'PARTIALLY_PAID'] }, dueDate: { lt: new Date() } },
        include: { customer: true },
        orderBy: { dueDate: 'asc' },
      });

      const total = invoices.reduce((sum, inv) => sum + Number(inv.total) - Number(inv.amountPaid), 0);
      res.json({ invoices, total, count: invoices.length });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getRevenueReport(req: AuthRequest, res: Response) {
    try {
      const { startDate, endDate } = req.query;
      const where: any = {};
      if (startDate || endDate) {
        where.paymentDate = {};
        if (startDate) where.paymentDate.gte = new Date(startDate as string);
        if (endDate) where.paymentDate.lte = new Date(endDate as string);
      }

      const payments = await prisma.payment.findMany({ where });

      const totalRevenue = payments.reduce((sum, pay) => sum + Number(pay.amount), 0);

      const byMethod = payments.reduce((acc: any, pay) => {
        acc[pay.paymentMethod] = (acc[pay.paymentMethod] || 0) + Number(pay.amount);
        return acc;
      }, {});

      const byMonth = payments.reduce((acc: any, pay) => {
        const month = pay.paymentDate.toISOString().slice(0, 7);
        acc[month] = (acc[month] || 0) + Number(pay.amount);
        return acc;
      }, {});

      res.json({ totalRevenue, byMethod, byMonth, count: payments.length });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getPaymentReport(req: AuthRequest, res: Response) {
    try {
      const payments = await prisma.payment.findMany({
        include: { customer: true, invoice: true },
        orderBy: { paymentDate: 'desc' },
        take: 100,
      });

      const total = payments.reduce((sum, pay) => sum + Number(pay.amount), 0);
      res.json({ payments, total, count: payments.length });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getEmailReport(req: AuthRequest, res: Response) {
    try {
      const emails = await prisma.emailLog.findMany({
        orderBy: { createdAt: 'desc' },
        take: 100,
      });

      const stats = {
        total: emails.length,
        sent: emails.filter(e => e.status === 'SENT').length,
        failed: emails.filter(e => e.status === 'FAILED').length,
        queued: emails.filter(e => e.status === 'QUEUED').length,
      };

      res.json({ emails, stats });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getReminderReport(req: AuthRequest, res: Response) {
    try {
      const reminders = await prisma.reminderLog.findMany({
        include: { invoice: { include: { customer: true } } },
        orderBy: { createdAt: 'desc' },
        take: 100,
      });

      const stats = {
        total: reminders.length,
        sent: reminders.filter(r => r.status === 'SENT').length,
        failed: reminders.filter(r => r.status === 'FAILED').length,
        pending: reminders.filter(r => r.status === 'PENDING').length,
        byType: reminders.reduce((acc: any, r) => {
          acc[r.reminderType] = (acc[r.reminderType] || 0) + 1;
          return acc;
        }, {}),
      };

      res.json({ reminders, stats });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
