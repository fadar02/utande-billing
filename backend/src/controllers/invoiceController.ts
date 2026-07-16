import { Response } from 'express';
import prisma from '../config/database';
import { InvoiceService } from '../services/invoiceService';
import { PDFService } from '../services/pdfService';
import { sendEmail, emailTemplates } from '../services/emailService';
import { ReminderService } from '../services/reminderService';
import { AuthRequest } from '../middleware/auth';
import logger from '../utils/logger';

export class InvoiceController {
  static async create(req: AuthRequest, res: Response) {
    try {
      const { customerId, customerServiceId, items, taxRate, dueDate, description, billingPeriodStart, billingPeriodEnd } = req.body;

      const invoice = await InvoiceService.createInvoice({
        customerId,
        customerServiceId,
        items,
        taxRate,
        dueDate: new Date(dueDate),
        description,
        billingPeriodStart: billingPeriodStart ? new Date(billingPeriodStart) : undefined,
        billingPeriodEnd: billingPeriodEnd ? new Date(billingPeriodEnd) : undefined,
      });

      res.status(201).json(invoice);
    } catch (error: any) {
      logger.error(`Create invoice error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getAll(req: AuthRequest, res: Response) {
    try {
      const { status, customerId, page = '1', limit = '20', search } = req.query;
      const pageNum = parseInt(page as string, 10);
      const limitNum = parseInt(limit as string, 10);
      const skip = (pageNum - 1) * limitNum;

      // Mark overdue invoices first so query returns correct statuses
      await InvoiceService.markOverdueInvoices();

      const where: any = {};
      if (status) where.status = status;
      if (customerId) where.customerId = customerId;
      if (search) {
        where.OR = [
          { invoiceNumber: { contains: search as string, mode: 'insensitive' } },
          { customer: { firstName: { contains: search as string, mode: 'insensitive' } } },
          { customer: { lastName: { contains: search as string, mode: 'insensitive' } } },
        ];
      }

      const [invoices, total] = await Promise.all([
        prisma.invoice.findMany({
          where,
          include: { customer: true, items: true },
          skip,
          take: limitNum,
          orderBy: { createdAt: 'desc' },
        }),
        prisma.invoice.count({ where }),
      ]);

      // Background: send reminders for due/overdue invoices
      ReminderService.processAllDueReminders().catch((err: any) =>
        logger.error(`Background overdue check error: ${err.message}`)
      );

      res.json({
        invoices,
        pagination: { page: pageNum, limit: limitNum, total, pages: Math.ceil(total / limitNum) },
      });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getById(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;
      const invoice = await prisma.invoice.findUnique({
        where: { id },
        include: { customer: true, customerService: { include: { service: true } }, items: true, payments: true, reminderLogs: true },
      });
      if (!invoice) return res.status(404).json({ error: 'Invoice not found' });
      res.json(invoice);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async downloadPDF(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;
      const pdfBuffer = await PDFService.generateInvoicePDF(id);

      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename=invoice-${id}.pdf`);
      res.send(pdfBuffer);
    } catch (error: any) {
      logger.error(`PDF generation error: ${error.message}`);
      res.status(500).json({ error: 'Failed to generate PDF' });
    }
  }

  static async update(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;
      const { status, description, notes } = req.body;

      const invoice = await prisma.invoice.update({
        where: { id },
        data: { status, description, notes },
      });

      res.json(invoice);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async cancel(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;
      const invoice = await prisma.invoice.update({
        where: { id },
        data: { status: 'CANCELLED' },
      });

      await ReminderService.cancelAllRemindersForInvoice(id);
      res.json(invoice);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getReminderHistory(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;
      const history = await ReminderService.getReminderHistory(id);
      res.json(history);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async autoGenerate(req: AuthRequest, res: Response) {
    try {
      const invoices = await InvoiceService.autoGenerateMonthlyInvoices();
      res.json({ message: `Generated ${invoices.length} invoices`, invoices });
    } catch (error: any) {
      logger.error(`Auto-generate invoices error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
