import prisma from '../config/database';
import logger from '../utils/logger';

export class InvoiceService {
  static async generateInvoiceNumber(): Promise<string> {
    const now = new Date();
    const year = now.getFullYear().toString().slice(-2);
    const month = (now.getMonth() + 1).toString().padStart(2, '0');

    const lastInvoice = await prisma.invoice.findFirst({
      where: {
        invoiceNumber: { startsWith: `INV-${year}${month}` },
      },
      orderBy: { invoiceNumber: 'desc' },
    });

    let sequence = 1;
    if (lastInvoice) {
      const lastSeq = parseInt(lastInvoice.invoiceNumber.split('-')[2], 10);
      sequence = lastSeq + 1;
    }

    return `INV-${year}${month}-${sequence.toString().padStart(4, '0')}`;
  }

  static async createInvoice(data: {
    customerId: string;
    customerServiceId?: string;
    items: { description: string; quantity: number; unitPrice: number }[];
    taxRate?: number;
    dueDate: Date;
    description?: string;
    billingPeriodStart?: Date;
    billingPeriodEnd?: Date;
  }) {
    const subtotal = data.items.reduce(
      (sum, item) => sum + item.quantity * item.unitPrice,
      0
    );
    const taxRate = data.taxRate || 0;
    const taxAmount = subtotal * (taxRate / 100);
    const total = subtotal + taxAmount;

    const invoiceNumber = await this.generateInvoiceNumber();

    const invoice = await prisma.invoice.create({
      data: {
        invoiceNumber,
        customerId: data.customerId,
        customerServiceId: data.customerServiceId,
        subtotal,
        taxRate,
        taxAmount,
        total,
        dueDate: data.dueDate,
        description: data.description,
        billingPeriodStart: data.billingPeriodStart,
        billingPeriodEnd: data.billingPeriodEnd,
        status: 'PENDING',
        items: {
          create: data.items.map(item => ({
            description: item.description,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            amount: item.quantity * item.unitPrice,
          })),
        },
      },
      include: {
        items: true,
        customer: true,
      },
    });

    logger.info(`Invoice created: ${invoiceNumber} for customer ${data.customerId}`);
    return invoice;
  }

  static async recordPayment(data: {
    invoiceId: string;
    customerId: string;
    amount: number;
    paymentMethod: string;
    reference?: string;
    notes?: string;
    receivedById: string;
  }) {
    const invoice = await prisma.invoice.findUnique({
      where: { id: data.invoiceId },
      include: { customer: true, customerService: true },
    });

    if (!invoice) throw new Error('Invoice not found');
    if (invoice.status === 'PAID') throw new Error('Invoice already paid');

    const newAmountPaid = Number(invoice.amountPaid) + data.amount;
    const total = Number(invoice.total);

    let newStatus: string;
    if (newAmountPaid >= total) {
      newStatus = 'PAID';
    } else if (newAmountPaid > 0) {
      newStatus = 'PARTIALLY_PAID';
    } else {
      newStatus = invoice.status;
    }

    const paymentNumber = await this.generatePaymentNumber();

    const [payment] = await prisma.$transaction([
      prisma.payment.create({
        data: {
          paymentNumber,
          customerId: data.customerId,
          invoiceId: data.invoiceId,
          amount: data.amount,
          paymentMethod: data.paymentMethod as any,
          reference: data.reference,
          notes: data.notes,
          receivedById: data.receivedById,
        },
      }),
      prisma.invoice.update({
        where: { id: data.invoiceId },
        data: {
          amountPaid: newAmountPaid,
          status: newStatus,
          paidDate: newStatus === 'PAID' ? new Date() : null,
        },
      }),
    ]);

    if (newStatus === 'PAID' && invoice.customerService) {
      await prisma.customerService.update({
        where: { id: invoice.customerServiceId! },
        data: { status: 'ACTIVE', suspendedAt: null },
      });
    }

    logger.info(`Payment recorded: ${paymentNumber} for invoice ${invoice.invoiceNumber}`);
    return { payment, invoice: { ...invoice, status: newStatus, amountPaid: newAmountPaid } };
  }

  static async generatePaymentNumber(): Promise<string> {
    const now = new Date();
    const year = now.getFullYear().toString().slice(-2);
    const month = (now.getMonth() + 1).toString().padStart(2, '0');

    const lastPayment = await prisma.payment.findFirst({
      where: {
        paymentNumber: { startsWith: `PAY-${year}${month}` },
      },
      orderBy: { paymentNumber: 'desc' },
    });

    let sequence = 1;
    if (lastPayment) {
      const lastSeq = parseInt(lastPayment.paymentNumber.split('-')[2], 10);
      sequence = lastSeq + 1;
    }

    return `PAY-${year}${month}-${sequence.toString().padStart(4, '0')}`;
  }

  static async autoGenerateMonthlyInvoices() {
    const activeServices = await prisma.customerService.findMany({
      where: { status: 'ACTIVE' },
      include: { customer: true, service: true },
    });

    const now = new Date();
    const billingPeriodStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const billingPeriodEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    const dueDate = new Date(now.getFullYear(), now.getMonth(), 15);

    const createdInvoices = [];

    for (const cs of activeServices) {
      const existingInvoice = await prisma.invoice.findFirst({
        where: {
          customerId: cs.customerId,
          customerServiceId: cs.id,
          billingPeriodStart,
          billingPeriodEnd,
          status: { not: 'CANCELLED' },
        },
      });

      if (existingInvoice) continue;

      const rate = Number(cs.customRate || cs.monthlyRate);

      const invoice = await this.createInvoice({
        customerId: cs.customerId,
        customerServiceId: cs.id,
        items: [
          {
            description: `${cs.service.name} - Monthly Service`,
            quantity: 1,
            unitPrice: rate,
          },
        ],
        dueDate,
        billingPeriodStart,
        billingPeriodEnd,
        description: `Monthly billing for ${cs.service.name}`,
      });

      createdInvoices.push(invoice);
    }

    logger.info(`Auto-generated ${createdInvoices.length} invoices for the month`);
    return createdInvoices;
  }

  static async markOverdueInvoices(): Promise<number> {
    const now = new Date();
    const result = await prisma.invoice.updateMany({
      where: {
        status: 'PENDING',
        dueDate: { lt: now },
      },
      data: { status: 'OVERDUE' },
    });
    if (result.count > 0) {
      logger.info(`Marked ${result.count} invoice(s) as OVERDUE`);
    }
    return result.count;
  }
}
