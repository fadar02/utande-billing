import { Response } from 'express';
import prisma from '../config/database';
import { AuthRequest } from '../middleware/auth';

export class DashboardController {
  static async getStats(req: AuthRequest, res: Response) {
    try {
      const [
        totalCustomers,
        activeCustomers,
        suspendedCustomers,
        totalServices,
        activeServices,
        pendingInvoices,
        overdueInvoices,
        paidInvoices,
        totalRevenue,
        recentPayments,
        recentActivity,
      ] = await Promise.all([
        prisma.customer.count(),
        prisma.customer.count({ where: { status: 'ACTIVE' } }),
        prisma.customer.count({ where: { status: 'SUSPENDED' } }),
        prisma.service.count({ where: { isActive: true } }),
        prisma.customerService.count({ where: { status: 'ACTIVE' } }),
        prisma.invoice.count({ where: { status: { in: ['PENDING', 'PARTIALLY_PAID'] } } }),
        prisma.invoice.count({ where: { status: 'OVERDUE' } }),
        prisma.invoice.count({ where: { status: 'PAID' } }),
        prisma.payment.aggregate({ _sum: { amount: true } }),
        prisma.payment.findMany({
          take: 5,
          orderBy: { createdAt: 'desc' },
          include: { customer: true },
        }),
        prisma.auditLog.findMany({
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: { user: { select: { firstName: true, lastName: true } } },
        }),
      ]);

      const outstandingAmount = await prisma.invoice.findMany({
        where: { status: { in: ['PENDING', 'PARTIALLY_PAID', 'OVERDUE'] } },
      });
      const totalOutstanding = outstandingAmount.reduce(
        (sum, inv) => sum + Number(inv.total) - Number(inv.amountPaid),
        0
      );

      res.json({
        customers: { total: totalCustomers, active: activeCustomers, suspended: suspendedCustomers },
        services: { total: totalServices, active: activeServices },
        invoices: { pending: pendingInvoices, overdue: overdueInvoices, paid: paidInvoices },
        revenue: { total: Number(totalRevenue._sum.amount || 0), outstanding: totalOutstanding },
        recentPayments,
        recentActivity,
      });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getRevenueChart(req: AuthRequest, res: Response) {
    try {
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

      const payments = await prisma.payment.findMany({
        where: { paymentDate: { gte: sixMonthsAgo } },
      });

      const monthlyRevenue: Record<string, number> = {};
      for (let i = 5; i >= 0; i--) {
        const d = new Date();
        d.setMonth(d.getMonth() - i);
        const key = d.toISOString().slice(0, 7);
        monthlyRevenue[key] = 0;
      }

      payments.forEach(p => {
        const month = p.paymentDate.toISOString().slice(0, 7);
        if (monthlyRevenue[month] !== undefined) {
          monthlyRevenue[month] += Number(p.amount);
        }
      });

      res.json(monthlyRevenue);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getAuditLogs(req: AuthRequest, res: Response) {
    try {
      const { page = '1', limit = '50' } = req.query;
      const pageNum = parseInt(page as string, 10);
      const limitNum = parseInt(limit as string, 10);
      const skip = (pageNum - 1) * limitNum;

      const [logs, total] = await Promise.all([
        prisma.auditLog.findMany({
          include: { user: { select: { firstName: true, lastName: true, email: true } } },
          skip,
          take: limitNum,
          orderBy: { createdAt: 'desc' },
        }),
        prisma.auditLog.count(),
      ]);

      res.json({ logs, pagination: { page: pageNum, limit: limitNum, total, pages: Math.ceil(total / limitNum) } });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
