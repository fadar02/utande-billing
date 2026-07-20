import { Router, Request, Response } from 'express';
import prisma from '../config/database';

const router = Router();

router.get('/invoices/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const invoice = await prisma.invoice.findUnique({
      where: { id },
      include: {
        customer: { select: { firstName: true, lastName: true, email: true, phone: true, customerCode: true } },
        customerService: { include: { service: { select: { name: true, type: true } } } },
        items: true,
        payments: { select: { id: true, amount: true, paymentMethod: true, paymentDate: true, paymentNumber: true } },
      },
    });
    if (!invoice) return res.status(404).json({ error: 'Invoice not found' });

    const totalPaid = invoice.payments.reduce((sum: number, p: any) => sum + Number(p.amount), 0);

    res.json({
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      status: invoice.status,
      total: invoice.total,
      taxRate: invoice.taxRate,
      taxAmount: invoice.taxAmount,
      description: invoice.description,
      dueDate: invoice.dueDate,
      billingPeriodStart: invoice.billingPeriodStart,
      billingPeriodEnd: invoice.billingPeriodEnd,
      createdAt: invoice.createdAt,
      items: invoice.items.map((item: any) => ({
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        amount: item.amount,
      })),
      customer: invoice.customer,
      serviceName: invoice.customerService?.service?.name || '',
      payments: invoice.payments.map((p: any) => ({
        number: p.paymentNumber,
        amount: p.amount,
        method: p.paymentMethod,
        date: p.paymentDate,
      })),
      balance: Number(invoice.total) - totalPaid,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/invoices/:id/pay', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { amount, paymentMethod, reference } = req.body;

    const invoice = await prisma.invoice.findUnique({
      where: { id },
      include: { payments: true, customer: true, customerService: true },
    });
    if (!invoice) return res.status(404).json({ error: 'Invoice not found' });
    if (invoice.status === 'PAID' || invoice.status === 'CANCELLED') {
      return res.status(400).json({ error: `Invoice is already ${invoice.status.toLowerCase()}` });
    }

    const totalPaid = invoice.payments.reduce((sum: number, p: any) => sum + Number(p.amount), 0);
    const balance = Number(invoice.total) - totalPaid;
    const payAmount = parseFloat(amount);
    if (isNaN(payAmount) || payAmount <= 0) return res.status(400).json({ error: 'Invalid payment amount' });
    if (payAmount > balance) return res.status(400).json({ error: `Payment exceeds balance of MWK ${balance.toFixed(2)}` });

    const lastPayment = await prisma.payment.findFirst({ orderBy: { createdAt: 'desc' } });
    let sequence = 1;
    if (lastPayment) {
      const lastSeq = parseInt(lastPayment.paymentNumber.replace('PAY-', ''), 10);
      sequence = lastSeq + 1;
    }
    const paymentNumber = `PAY-${sequence.toString().padStart(5, '0')}`;

    const payment = await prisma.payment.create({
      data: {
        paymentNumber,
        customerId: invoice.customerId,
        invoiceId: invoice.id,
        amount: payAmount,
        paymentMethod: paymentMethod || 'CASH',
        reference: reference || null,
      },
    });

    const newTotalPaid = totalPaid + payAmount;
    const newStatus = newTotalPaid >= Number(invoice.total) ? 'PAID' : 'PARTIALLY_PAID';
    await prisma.invoice.update({
      where: { id },
      data: {
        status: newStatus,
        amountPaid: newTotalPaid,
        paidDate: newStatus === 'PAID' ? new Date() : null,
      },
    });

    res.status(201).json({ payment, message: 'Payment successful' });
  } catch (error: any) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
