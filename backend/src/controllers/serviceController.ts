import { Request, Response } from 'express';
import prisma from '../config/database';
import logger from '../utils/logger';

export class ServiceController {
  static async create(req: Request, res: Response) {
    try {
      const { name, description, type, monthlyRate, setupFee } = req.body;
      const service = await prisma.service.create({
        data: { name, description, type, monthlyRate, setupFee },
      });
      res.status(201).json(service);
    } catch (error: any) {
      logger.error(`Create service error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getAll(req: Request, res: Response) {
    try {
      const { type, isActive } = req.query;
      const where: any = {};
      if (type) where.type = type;
      if (isActive !== undefined) where.isActive = isActive === 'true';

      const services = await prisma.service.findMany({
        where,
        include: { _count: { select: { customerServices: true } } },
        orderBy: { createdAt: 'desc' },
      });
      res.json(services);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async getById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const service = await prisma.service.findUnique({
        where: { id },
        include: { customerServices: { include: { customer: true } } },
      });
      if (!service) return res.status(404).json({ error: 'Service not found' });
      res.json(service);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async update(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { name, description, type, monthlyRate, setupFee, isActive } = req.body;
      const service = await prisma.service.update({
        where: { id },
        data: { name, description, type, monthlyRate, setupFee, isActive },
      });
      res.json(service);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async assignToCustomer(req: Request, res: Response) {
    try {
      const { customerId, serviceId, customRate, monthlyRate } = req.body;

      const existing = await prisma.customerService.findUnique({
        where: { customerId_serviceId: { customerId, serviceId } },
      });
      if (existing) return res.status(400).json({ error: 'Service already assigned to this customer' });

      const service = await prisma.service.findUnique({ where: { id: serviceId } });
      if (!service) return res.status(404).json({ error: 'Service not found' });

      const customer = await prisma.customer.findUnique({ where: { id: customerId } });
      if (!customer) return res.status(404).json({ error: 'Customer not found' });

      const customerService = await prisma.customerService.create({
        data: {
          customerId,
          serviceId,
          monthlyRate: monthlyRate || service.monthlyRate,
          customRate,
        },
        include: { customer: true, service: true },
      });

      res.status(201).json(customerService);
    } catch (error: any) {
      logger.error(`Assign service error: ${error.message}`);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async updateCustomerService(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { status, customRate } = req.body;

      const customerService = await prisma.customerService.update({
        where: { id },
        data: { status, customRate },
        include: { customer: true, service: true },
      });

      res.json(customerService);
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async removeCustomerService(req: Request, res: Response) {
    try {
      const { id } = req.params;
      await prisma.customerService.delete({ where: { id } });
      res.json({ message: 'Service removed from customer' });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  static async delete(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const service = await prisma.service.findUnique({ where: { id }, include: { _count: { select: { customerServices: true } } } });
      if (!service) return res.status(404).json({ error: 'Package not found' });
      if (service._count.customerServices > 0) {
        return res.status(400).json({ error: `Cannot delete: ${service._count.customerServices} customer(s) still assigned to this package` });
      }
      await prisma.service.delete({ where: { id } });
      res.json({ message: 'Package deleted successfully' });
    } catch (error: any) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
