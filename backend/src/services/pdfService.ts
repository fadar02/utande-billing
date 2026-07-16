import PDFDocument from 'pdfkit';
import prisma from '../config/database';
import { config } from '../config';
import logger from '../utils/logger';
import { PassThrough } from 'stream';

export class PDFService {
  static async generateInvoicePDF(invoiceId: string): Promise<Buffer> {
    const invoice = await prisma.invoice.findUnique({
      where: { id: invoiceId },
      include: {
        customer: true,
        customerService: { include: { service: true } },
        items: true,
        payments: true,
      },
    });

    if (!invoice) throw new Error('Invoice not found');

    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ size: 'A4', margin: 50 });
      const chunks: Buffer[] = [];

      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Header
      doc.fontSize(20).font('Helvetica-Bold').text('UTANDE', { align: 'left' });
      doc.fontSize(10).font('Helvetica').text('Smart Billing System', { align: 'left' });
      doc.moveDown(0.5);

      // Invoice Title
      doc.fontSize(16).font('Helvetica-Bold').text('INVOICE', { align: 'right' });
      doc.fontSize(10).font('Helvetica');
      doc.text(`Invoice #: ${invoice.invoiceNumber}`, { align: 'right' });
      doc.text(`Date: ${invoice.issuedDate.toLocaleDateString()}`, { align: 'right' });
      doc.text(`Due Date: ${invoice.dueDate.toLocaleDateString()}`, { align: 'right' });
      doc.text(`Status: ${invoice.status}`, { align: 'right' });
      doc.moveDown(1);

      // Bill To
      doc.fontSize(12).font('Helvetica-Bold').text('Bill To:');
      doc.fontSize(10).font('Helvetica');
      doc.text(`${invoice.customer.firstName} ${invoice.customer.lastName}`);
      doc.text(invoice.customer.email);
      doc.text(invoice.customer.phone);
      if (invoice.customer.address) doc.text(invoice.customer.address);
      doc.moveDown(1);

      // Service Info
      if (invoice.customerService) {
        doc.fontSize(10).font('Helvetica-Bold').text('Service:');
        doc.font('Helvetica').text(invoice.customerService.service.name);
        if (invoice.billingPeriodStart && invoice.billingPeriodEnd) {
          doc.text(`Billing Period: ${invoice.billingPeriodStart.toLocaleDateString()} - ${invoice.billingPeriodEnd.toLocaleDateString()}`);
        }
        doc.moveDown(0.5);
      }

      // Items Table
      const tableTop = doc.y;
      const itemMargin = 50;

      doc.fontSize(10).font('Helvetica-Bold');
      doc.text('Description', itemMargin, tableTop, { width: 280 });
      doc.text('Qty', itemMargin + 280, tableTop, { width: 60, align: 'right' });
      doc.text('Unit Price', itemMargin + 340, tableTop, { width: 80, align: 'right' });
      doc.text('Amount', itemMargin + 420, tableTop, { width: 80, align: 'right' });

      doc.moveDown(0.5);
      doc.moveTo(itemMargin, doc.y).lineTo(545, doc.y).stroke();
      doc.moveDown(0.5);

      doc.font('Helvetica');
      for (const item of invoice.items) {
        const y = doc.y;
        doc.text(item.description, itemMargin, y, { width: 280 });
        doc.text(item.quantity.toString(), itemMargin + 280, y, { width: 60, align: 'right' });
        doc.text(`$${Number(item.unitPrice).toFixed(2)}`, itemMargin + 340, y, { width: 80, align: 'right' });
        doc.text(`$${Number(item.amount).toFixed(2)}`, itemMargin + 420, y, { width: 80, align: 'right' });
        doc.moveDown(0.8);
      }

      doc.moveTo(itemMargin, doc.y).lineTo(545, doc.y).stroke();
      doc.moveDown(0.5);

      // Totals
      const totalsX = 380;
      doc.font('Helvetica-Bold');
      doc.text('Subtotal:', totalsX, doc.y, { width: 80, align: 'right' });
      doc.text(`$${Number(invoice.subtotal).toFixed(2)}`, totalsX + 80, doc.y - 13, { width: 80, align: 'right' });
      doc.moveDown(0.5);

      if (Number(invoice.taxRate) > 0) {
        doc.text(`Tax (${invoice.taxRate}%):`, totalsX, doc.y, { width: 80, align: 'right' });
        doc.text(`$${Number(invoice.taxAmount).toFixed(2)}`, totalsX + 80, doc.y - 13, { width: 80, align: 'right' });
        doc.moveDown(0.5);
      }

      doc.fontSize(14).font('Helvetica-Bold');
      doc.text('Total:', totalsX, doc.y, { width: 80, align: 'right' });
      doc.text(`$${Number(invoice.total).toFixed(2)}`, totalsX + 80, doc.y - 17, { width: 80, align: 'right' });
      doc.moveDown(0.5);

      doc.fontSize(10).font('Helvetica');
      doc.text('Amount Paid:', totalsX, doc.y, { width: 80, align: 'right' });
      doc.text(`$${Number(invoice.amountPaid).toFixed(2)}`, totalsX + 80, doc.y - 13, { width: 80, align: 'right' });
      doc.moveDown(0.5);

      const balance = Number(invoice.total) - Number(invoice.amountPaid);
      doc.font('Helvetica-Bold');
      doc.text('Balance Due:', totalsX, doc.y, { width: 80, align: 'right' });
      doc.text(`$${balance.toFixed(2)}`, totalsX + 80, doc.y - 13, { width: 80, align: 'right' });

      // Notes
      if (invoice.notes) {
        doc.moveDown(2);
        doc.fontSize(10).font('Helvetica-Bold').text('Notes:');
        doc.font('Helvetica').text(invoice.notes);
      }

      // Footer
      doc.moveDown(3);
      doc.fontSize(8).font('Helvetica').fillColor('#666666');
      doc.text('Utande Smart Billing System', { align: 'center' });
      doc.text(`Generated on ${new Date().toLocaleString()}`, { align: 'center' });

      doc.end();
    });
  }

  static async generatePaymentReceiptPDF(paymentId: string): Promise<Buffer> {
    const payment = await prisma.payment.findUnique({
      where: { id: paymentId },
      include: {
        customer: true,
        invoice: true,
        receivedBy: true,
      },
    });

    if (!payment) throw new Error('Payment not found');

    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ size: 'A4', margin: 50 });
      const chunks: Buffer[] = [];

      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Header
      doc.fontSize(20).font('Helvetica-Bold').text('UTANDE', { align: 'left' });
      doc.fontSize(10).font('Helvetica').text('Smart Billing System', { align: 'left' });
      doc.moveDown(0.5);

      doc.fontSize(16).font('Helvetica-Bold').text('PAYMENT RECEIPT', { align: 'right' });
      doc.fontSize(10).font('Helvetica');
      doc.text(`Receipt #: ${payment.paymentNumber}`, { align: 'right' });
      doc.text(`Date: ${payment.paymentDate.toLocaleDateString()}`, { align: 'right' });
      doc.moveDown(1);

      // Payment Details
      doc.fontSize(12).font('Helvetica-Bold').text('Payment Details');
      doc.fontSize(10).font('Helvetica');
      doc.text(`Customer: ${payment.customer.firstName} ${payment.customer.lastName}`);
      doc.text(`Email: ${payment.customer.email}`);
      doc.text(`Phone: ${payment.customer.phone}`);
      doc.text(`Amount: $${Number(payment.amount).toFixed(2)}`);
      doc.text(`Payment Method: ${payment.paymentMethod}`);
      if (payment.reference) doc.text(`Reference: ${payment.reference}`);
      if (payment.invoice) doc.text(`Invoice: ${payment.invoice.invoiceNumber}`);
      doc.text(`Received By: ${payment.receivedBy.firstName} ${payment.receivedBy.lastName}`);
      doc.moveDown(2);

      // Footer
      doc.fontSize(8).font('Helvetica').fillColor('#666666');
      doc.text('Thank you for your payment.', { align: 'center' });
      doc.text('Utande Smart Billing System', { align: 'center' });

      doc.end();
    });
  }
}
