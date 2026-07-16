import { Response } from 'express';
import prisma from '../config/database';
import { InvoiceService } from '../services/invoiceService';
import { PDFService } from '../services/pdfService';
import { sendEmail, emailTemplates } from '../services/emailService';
import { ServiceManagementService } from '../services/serviceManagementService';
import { AuthRequest } from '../middleware/auth';
import logger from '../utils/logger';

export class PaymentController {
  static async record(req: AuthRequest, res: Response) {
    try {
      const { invoiceId, customerId, amount, paymentMethod, reference, notes } = req.body;

      const result = await InvoiceService.recordPayment({
        invoiceId,
        customerId,
        amount,
        paymentMethod,
        reference,
        notes,
        receivedById: req.user!.id,
      });

      const customer = await prisma.customer.findUnique({ where: { id: customerId } });
      if (customer) {
        const template = emailTemplates.paymentReceipt(
          `${customer.firstName} ${customer.lastName}`,
          result.payment.paymentNumber,
          amount.toString(),
          paymentMethod,
          result.invoice.invoiceNumber
        );

        await sendEmail({
          to: customer.email,
          subject: template.subject,
          html: template.html,
          emailType: 'PAYMENT_RECEIPT',
          relatedId: result.payment.id,
        });

        await prisma.payment.update({
          where: { id: result.payment.id },
          data: { receiptSent: true },
        });
      }

      if (result.invoice.status === 'PAID') {
        await ServiceManagementService.restoreServicesAfterPayment(customerId);
      }

      res.status(201).json(result);
    } catch (error: any) {
      logger.error(`Record payment error: ${error.message}`);
      res.status(400).json({ error: error.message });
    }
  }

  static async getAll(req: AuthRequest, res: Response) {
    try {
      const { customerId, page = '1', limit = '20', startDate, endDate } = req.query;
      const pageNum = parseInt(page as string, 10);
      const limitNum = parseInt(limit as string, 10);
      const skip = (pageNum - 1) * limitNum;

      const where: any = {};
      if (customerId) where.customerId = customerId;
      if (startDate || endDate) {
        where.paymentDate = {};
        if (startDate) where.paymentDate.gte = new Date(startDate as string);
        if (endDate) where.paymentDate.lte = new Date(endDate as string);
      }

      const [payments, total] = await Promise.all([
        prisma.payment.findMany({
          where,
          include: { customer: true, invoice: true, receivedBy: true },
          skip,
          take: limitNum,
          orderBy: { createdAt: 'desc' },
        }),
        prisma.payment.count({ where }),
      ]);

      res.json({
        payments,
        pagination: { page: pageNum, limit: limitNum, total, pages: Math.ceil(total / limitNum) },
      });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getById(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;
      const payment = await prisma.payment.findUnique({
        where: { id },
        include: { customer: true, invoice: true, receivedBy: true },
      });
      if (!payment) return res.status(404).json({ error: 'Payment not found' });
      res.json(payment);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async downloadReceipt(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;
      const pdfBuffer = await PDFService.generatePaymentReceiptPDF(id);

      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename=receipt-${id}.pdf`);
      res.send(pdfBuffer);
    } catch (error: any) {
      logger.error(`Receipt PDF error: ${error.message}`);
      res.status(500).json({ error: 'Failed to generate receipt' });
    }
  }
}
