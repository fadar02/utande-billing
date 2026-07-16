import { Request, Response } from 'express';
import prisma from '../config/database';
import { AuthRequest } from '../middleware/auth';
import { sendEmail } from '../services/emailService';
import logger from '../utils/logger';

export class CustomerController {
  static async create(req: Request, res: Response) {
    try {
      const { firstName, lastName, email, phone, notes } = req.body;

      const existingEmail = await prisma.customer.findUnique({ where: { email } });
      if (existingEmail) return res.status(400).json({ error: 'Email already registered' });

      const lastCustomer = await prisma.customer.findFirst({
        orderBy: { customerCode: 'desc' },
      });

      let sequence = 1;
      if (lastCustomer) {
        const lastSeq = parseInt(lastCustomer.customerCode.replace('CUST-', ''), 10);
        sequence = lastSeq + 1;
      }
      const customerCode = `CUST-${sequence.toString().padStart(5, '0')}`;

      const customer = await prisma.customer.create({
        data: { customerCode, firstName, lastName, email, phone, notes },
      });

      res.status(201).json(customer);
    } catch (error: any) {
      logger.error(`Create customer error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getAll(req: Request, res: Response) {
    try {
      const { search, status, page = '1', limit = '20' } = req.query;
      const pageNum = parseInt(page as string, 10);
      const limitNum = parseInt(limit as string, 10);
      const skip = (pageNum - 1) * limitNum;

      const where: any = {};
      if (status) where.status = status;
      if (search) {
        where.OR = [
          { firstName: { contains: search as string, mode: 'insensitive' } },
          { lastName: { contains: search as string, mode: 'insensitive' } },
          { email: { contains: search as string, mode: 'insensitive' } },
          { customerCode: { contains: search as string, mode: 'insensitive' } },
          { phone: { contains: search as string } },
        ];
      }

      const [customers, total] = await Promise.all([
        prisma.customer.findMany({
          where,
          include: {
            services: { where: { status: 'ACTIVE' }, include: { service: true } },
            invoices: {
              where: { status: { in: ['PENDING', 'OVERDUE'] } },
              select: { total: true },
            },
            _count: { select: { invoices: true, payments: true } },
          },
          skip,
          take: limitNum,
          orderBy: { createdAt: 'desc' },
        }),
        prisma.customer.count({ where }),
      ]);

      const customersWithBalance = customers.map(c => ({
        ...c,
        balance: c.invoices.reduce((sum, inv) => sum + Number(inv.total), 0),
      }));

      res.json({
        customers: customersWithBalance,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          pages: Math.ceil(total / limitNum),
        },
      });
    } catch (error: any) {
      logger.error(`Get customers error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const customer = await prisma.customer.findUnique({
        where: { id },
        include: {
          services: { include: { service: true } },
          invoices: { orderBy: { createdAt: 'desc' }, take: 10 },
          payments: { orderBy: { createdAt: 'desc' }, take: 10 },
        },
      });

      if (!customer) return res.status(404).json({ error: 'Customer not found' });
      res.json(customer);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async update(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { firstName, lastName, email, phone, status, notes } = req.body;

      const customer = await prisma.customer.update({
        where: { id },
        data: { firstName, lastName, email, phone, status, notes },
      });

      res.json(customer);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async delete(req: Request, res: Response) {
    try {
      const { id } = req.params;
      await prisma.customer.delete({ where: { id } });
      res.json({ message: 'Customer deleted successfully' });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getStatement(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { startDate, endDate } = req.query;

      const customer = await prisma.customer.findUnique({ where: { id } });
      if (!customer) return res.status(404).json({ error: 'Customer not found' });

      const where: any = { customerId: id };
      if (startDate || endDate) {
        where.createdAt = {};
        if (startDate) where.createdAt.gte = new Date(startDate as string);
        if (endDate) where.createdAt.lte = new Date(endDate as string);
      }

      const [invoices, payments] = await Promise.all([
        prisma.invoice.findMany({ where, orderBy: { createdAt: 'desc' } }),
        prisma.payment.findMany({ where, orderBy: { createdAt: 'desc' } }),
      ]);

      const totalInvoiced = invoices.reduce((sum, inv) => sum + Number(inv.total), 0);
      const totalPaid = payments.reduce((sum, pay) => sum + Number(pay.amount), 0);

      res.json({
        customer,
        summary: { totalInvoiced, totalPaid, balance: totalInvoiced - totalPaid },
        invoices,
        payments,
      });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async sendEmail(req: AuthRequest, res: Response) {
    try {
      const { id } = req.params;
      const { subject, message } = req.body;

      const customer = await prisma.customer.findUnique({ where: { id } });
      if (!customer) return res.status(404).json({ error: 'Customer not found' });

      const html = `
        <div style="font-family:Arial,Helvetica,sans-serif;max-width:600px;margin:0 auto;background:#ffffff;border:1px solid #e2e8f0;border-radius:8px;overflow:hidden;">
          <div style="background:#1a2332;padding:24px;text-align:center;">
            <img src="http://localhost:3000/assets/logo.png" alt="Utande" style="height:48px;margin:0 auto 8px;display:block;" />
            <div style="color:#ffffff;font-size:20px;font-weight:700;margin:0;">Utande Billing</div>
            <div style="color:#a0aec0;font-size:12px;margin:4px 0 0;">Smart Billing System</div>
          </div>
          <div style="background:#4299e1;color:#ffffff;padding:16px 24px;">
            <div style="font-size:16px;font-weight:600;">${subject}</div>
          </div>
          <div style="padding:24px;">
            <p style="color:#2d3748;font-size:14px;margin:0 0 12px;">Dear ${customer.firstName} ${customer.lastName},</p>
            <div style="color:#4a5568;font-size:14px;line-height:1.6;white-space:pre-wrap;">${message}</div>
          </div>
          <div style="padding:12px 24px;text-align:center;border-top:1px solid #e2e8f0;">
            <div style="color:#a0aec0;font-size:11px;">Utande Smart Billing System | This is an automated email, please do not reply.</div>
          </div>
        </div>
      `;

      const sent = await sendEmail({
        to: customer.email,
        subject,
        html,
        emailType: 'MANUAL',
        relatedId: id,
      });

      if (sent) {
        res.json({ message: 'Email sent successfully' });
      } else {
        res.status(500).json({ error: 'Failed to send email' });
      }
    } catch (error: any) {
      logger.error(`Send email error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
