import nodemailer from 'nodemailer';
import { config } from '../config';
import prisma from '../config/database';
import logger from '../utils/logger';

let transporter: nodemailer.Transporter | null = null;

function getTransporter(): nodemailer.Transporter {
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: config.smtp.host,
      port: config.smtp.port,
      secure: config.smtp.port === 465,
      auth: {
        user: config.smtp.user,
        pass: config.smtp.pass,
      },
      connectionTimeout: 30000,
      greetingTimeout: 30000,
      socketTimeout: 45000,
    });
  }
  return transporter;
}

interface SendEmailParams {
  to: string;
  cc?: string;
  subject: string;
  html: string;
  emailType: string;
  relatedId?: string;
}

export const sendEmail = async (params: SendEmailParams): Promise<boolean> => {
  const emailLog = await prisma.emailLog.create({
    data: {
      recipientEmail: params.to,
      subject: params.subject,
      body: params.html,
      emailType: params.emailType,
      relatedId: params.relatedId,
      status: 'QUEUED',
    },
  });

  try {
    await getTransporter().sendMail({
      from: config.smtp.from,
      to: params.to,
      cc: params.cc,
      subject: params.subject,
      html: params.html,
    });

    await prisma.emailLog.update({
      where: { id: emailLog.id },
      data: { status: 'SENT', sentAt: new Date() },
    });

    logger.info(`Email sent to ${params.to}: ${params.subject}`);
    return true;
  } catch (error: any) {
    await prisma.emailLog.update({
      where: { id: emailLog.id },
      data: {
        status: 'FAILED',
        failedAt: new Date(),
        errorMessage: error.message,
      },
    });

    logger.error(`Email failed to ${params.to}: ${error.message}`);
    return false;
  }
};

export const retryFailedEmails = async (): Promise<void> => {
  const failedEmails = await prisma.emailLog.findMany({
    where: {
      status: 'FAILED',
      retryCount: { lt: 3 },
    },
  });

  for (const email of failedEmails) {
    try {
      await getTransporter().sendMail({
        from: config.smtp.from,
        to: email.recipientEmail,
        subject: email.subject,
        html: email.body,
      });

      await prisma.emailLog.update({
        where: { id: email.id },
        data: { status: 'SENT', sentAt: new Date(), retryCount: email.retryCount + 1 },
      });
    } catch (error: any) {
      await prisma.emailLog.update({
        where: { id: email.id },
        data: {
          retryCount: email.retryCount + 1,
          errorMessage: error.message,
          failedAt: new Date(),
        },
      });
    }
  }
};

// Email Templates
const FRONTEND_URL = config.appUrl || 'http://localhost:3000';

const logoBase64 = (() => {
  try {
    const fs = require('fs');
    const path = require('path');
    const logoPath = path.join(__dirname, '../../public/logo.png');
    const data = fs.readFileSync(logoPath);
    return `data:image/png;base64,${data.toString('base64')}`;
  } catch {
    return `${config.appUrl}/assets/logo.png`;
  }
})();
const logoImg = `<img src="${logoBase64}" alt="Utande" style="height:80px;margin:0 auto 12px;display:block;" />`;

const baseWrapper = (headerColor: string, headerTitle: string, content: string) => `
<div style="font-family:Arial,Helvetica,sans-serif;max-width:600px;margin:0 auto;background:#ffffff;border:1px solid #e2e8f0;border-radius:8px;overflow:hidden;">
  <div style="background:#1a2332;padding:24px;text-align:center;">
    ${logoImg}
    <div style="color:#ffffff;font-size:20px;font-weight:700;margin:0;">Utande Billing</div>
    <div style="color:#a0aec0;font-size:12px;margin:4px 0 0;">Smart Billing System</div>
  </div>
  <div style="background:${headerColor};color:#ffffff;padding:16px 24px;">
    <div style="font-size:16px;font-weight:600;">${headerTitle}</div>
  </div>
  <div style="padding:24px;">
    ${content}
  </div>
  <div style="padding:12px 24px;text-align:center;border-top:1px solid #e2e8f0;">
    <div style="color:#a0aec0;font-size:11px;">Utande Smart Billing System | This is an automated email, please do not reply.</div>
  </div>
</div>`;

const viewButton = (url: string, label: string, color: string = '#4299e1') => `
<div style="text-align:center;margin:24px 0;">
  <a href="${url}" style="display:inline-block;padding:14px 40px;background:${color};color:#ffffff;text-decoration:none;border-radius:6px;font-size:15px;font-weight:600;">${label}</a>
</div>`;

const invoiceSummary = (invoiceNumber: string, amount: string, dueDate: string) => `
<table style="width:100%;border-collapse:collapse;margin:16px 0;font-size:14px;">
  <tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;width:40%;color:#4a5568;font-weight:500;">Invoice Number</td><td style="padding:10px 12px;border:1px solid #e2e8f0;font-weight:600;">${invoiceNumber}</td></tr>
  <tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;color:#4a5568;font-weight:500;">Amount Due</td><td style="padding:10px 12px;border:1px solid #e2e8f0;font-weight:600;color:#e53e3e;">MWK ${amount}</td></tr>
  <tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;color:#4a5568;font-weight:500;">Due Date</td><td style="padding:10px 12px;border:1px solid #e2e8f0;">${dueDate}</td></tr>
</table>`;

export const emailTemplates = {
  invoiceCreated: (customerName: string, invoiceNumber: string, amount: string, dueDate: string, invoiceId?: string) => {
    const viewUrl = invoiceId ? `${FRONTEND_URL}/pay/${invoiceId}` : '#';
    return {
      subject: `Invoice ${invoiceNumber} from Utande — Amount Due: MWK ${amount}`,
      html: baseWrapper('#4299e1', 'New Invoice', `
        <p style="color:#2d3748;font-size:14px;margin:0 0 12px;">Dear ${customerName},</p>
        <p style="color:#4a5568;font-size:14px;margin:0 0 8px;">A new invoice has been generated for your account. Please find the details below:</p>
        ${invoiceSummary(invoiceNumber, amount, dueDate)}
        ${viewButton(viewUrl, 'View Invoice', '#4299e1')}
        <p style="color:#4a5568;font-size:13px;margin:0 0 8px;">Please make payment before the due date to avoid any service interruption.</p>
        <p style="color:#718096;font-size:13px;margin:0;">If you have any questions, please reply to this email or contact our billing department.</p>
      `),
    };
  },

  paymentReminder: (
    customerName: string,
    invoiceNumber: string,
    amount: string,
    dueDate: string,
    reminderType: string,
    invoiceId?: string,
    serviceName?: string,
    items?: { description: string; quantity: number; unitPrice: number; amount: number }[],
    balance?: string,
    daysOverdue?: number
  ) => {
    const isUrgent = reminderType === 'overdue';
    const title = isUrgent ? 'Overdue Payment Notice' : 'Payment Reminder';
    const balanceAmount = balance || amount;

    const daysInfo = isUrgent && daysOverdue ? `<p style="color:#e53e3e;font-size:14px;font-weight:600;margin:0 0 16px;">This invoice is ${daysOverdue} day${daysOverdue !== 1 ? 's' : ''} overdue</p>` : '';

    let itemsList = '';
    if (items && items.length > 0) {
      itemsList = items.map(item =>
        `<tr>
          <td style="padding:8px 12px;border:1px solid #e2e8f0;">${item.description}</td>
          <td style="padding:8px 12px;border:1px solid #e2e8f0;text-align:center;">${item.quantity}</td>
          <td style="padding:8px 12px;border:1px solid #e2e8f0;text-align:right;">MWK ${item.amount.toFixed(2)}</td>
        </tr>`
      ).join('');
    }

    return {
      subject: isUrgent
        ? `OVERDUE: Invoice ${invoiceNumber} — MWK ${balanceAmount}`
        : `Payment Reminder: Invoice ${invoiceNumber} — MWK ${balanceAmount}`,
      html: baseWrapper('#1a2332', title, `
        <p style="color:#2d3748;font-size:14px;margin:0 0 12px;">Dear ${customerName},</p>
        <p style="color:#4a5568;font-size:14px;margin:0 0 16px;">This is a reminder that your payment is <strong style="color:${isUrgent ? '#e53e3e' : '#1a2332'};">${reminderType}</strong>.</p>
        ${daysInfo}
        <table style="width:100%;border-collapse:collapse;margin:16px 0;font-size:14px;">
          <tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;width:40%;color:#4a5568;font-weight:500;">Invoice</td><td style="padding:10px 12px;border:1px solid #e2e8f0;font-weight:600;">${invoiceNumber}</td></tr>
          <tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;color:#4a5568;font-weight:500;">Amount Due</td><td style="padding:10px 12px;border:1px solid #e2e8f0;font-weight:700;color:#e53e3e;">MWK ${balanceAmount}</td></tr>
          <tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;color:#4a5568;font-weight:500;">Due Date</td><td style="padding:10px 12px;border:1px solid #e2e8f0;">${dueDate}</td></tr>
        </table>
        ${itemsList ? `<table style="width:100%;border-collapse:collapse;margin:16px 0;font-size:13px;">
          <tr style="background:#f7fafc;">
            <th style="padding:8px 12px;border:1px solid #e2e8f0;text-align:left;">Description</th>
            <th style="padding:8px 12px;border:1px solid #e2e8f0;text-align:center;">Qty</th>
            <th style="padding:8px 12px;border:1px solid #e2e8f0;text-align:right;">Amount</th>
          </tr>
          ${itemsList}
          <tr style="background:#f7fafc;">
            <td colspan="2" style="padding:10px 12px;border:1px solid #e2e8f0;text-align:right;font-weight:600;">Total</td>
            <td style="padding:10px 12px;border:1px solid #e2e8f0;text-align:right;font-weight:700;color:#e53e3e;">MWK ${balanceAmount}</td>
          </tr>
        </table>` : ''}
        ${isUrgent ? '<p style="color:#e53e3e;font-size:13px;font-weight:600;margin:16px 0 0;">Continued non-payment may result in service suspension.</p>' : ''}
      `),
    };
  },

  overdueNotice: (customerName: string, invoiceNumber: string, amount: string, dueDate: string, invoiceId?: string) => {
    const viewUrl = invoiceId ? `${FRONTEND_URL}/pay/${invoiceId}` : '#';
    return {
      subject: `OVERDUE: Invoice ${invoiceNumber} — MWK ${amount} now past due`,
      html: baseWrapper('#1a2332', 'Overdue Payment Notice', `
        <p style="color:#2d3748;font-size:14px;margin:0 0 16px;">Dear ${customerName},</p>
        <p style="color:#4a5568;font-size:14px;margin:0 0 16px;">We are writing to inform you that the payment for the following invoice is now <strong style="color:#e53e3e;">overdue</strong>. We kindly urge you to address this matter promptly.</p>
        ${invoiceSummary(invoiceNumber, amount, dueDate)}
        <div style="background:#fff5f5;border-left:4px solid #e53e3e;padding:12px 16px;margin:16px 0;border-radius:0 6px 6px 0;">
          <p style="color:#742a2a;font-size:13px;margin:0;">Please note that continued non-payment may result in temporary suspension of your services.</p>
        </div>
        <p style="color:#718096;font-size:12px;margin:16px 0 0;">If you have already made this payment, please disregard this notice. For any questions, please contact our billing support team.</p>
      `),
    };
  },

  paymentReceipt: (
    customerName: string,
    paymentNumber: string,
    amount: string,
    paymentMethod: string,
    invoiceNumber?: string
  ) => ({
    subject: `Payment Receipt ${paymentNumber} — Utande`,
    html: baseWrapper('#48bb78', 'Payment Confirmed', `
      <p style="color:#2d3748;font-size:14px;margin:0 0 12px;">Dear ${customerName},</p>
      <p style="color:#4a5568;font-size:14px;margin:0 0 8px;">We have received your payment. Thank you! Here are the details:</p>
      <table style="width:100%;border-collapse:collapse;margin:16px 0;font-size:14px;">
        <tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;width:40%;color:#4a5568;font-weight:500;">Receipt Number</td><td style="padding:10px 12px;border:1px solid #e2e8f0;font-weight:600;">${paymentNumber}</td></tr>
        <tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;color:#4a5568;font-weight:500;">Amount Received</td><td style="padding:10px 12px;border:1px solid #e2e8f0;font-weight:600;color:#48bb78;">MWK ${amount}</td></tr>
        <tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;color:#4a5568;font-weight:500;">Payment Method</td><td style="padding:10px 12px;border:1px solid #e2e8f0;">${paymentMethod}</td></tr>
        ${invoiceNumber ? `<tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;color:#4a5568;font-weight:500;">Invoice</td><td style="padding:10px 12px;border:1px solid #e2e8f0;">${invoiceNumber}</td></tr>` : ''}
        <tr><td style="padding:10px 12px;background:#f7fafc;border:1px solid #e2e8f0;color:#4a5568;font-weight:500;">Date</td><td style="padding:10px 12px;border:1px solid #e2e8f0;">${new Date().toLocaleDateString()}</td></tr>
      </table>
      <p style="color:#4a5568;font-size:13px;margin:0 0 8px;">Your account balance has been updated. Thank you for your prompt payment.</p>
      <p style="color:#718096;font-size:13px;margin:0;">Please keep this receipt for your records.</p>
    `),
  }),

  serviceSuspended: (customerName: string, serviceName: string) => ({
    subject: `Service Suspended — ${serviceName} | Utande`,
    html: baseWrapper('#e53e3e', 'Service Suspended', `
      <p style="color:#2d3748;font-size:14px;margin:0 0 12px;">Dear ${customerName},</p>
      <p style="color:#4a5568;font-size:14px;margin:0 0 8px;">Due to non-payment, your <strong>${serviceName}</strong> service has been <strong style="color:#e53e3e;">suspended</strong>.</p>
      <p style="color:#4a5568;font-size:14px;margin:0 0 8px;">To restore your service, please settle all outstanding invoices. You can view your account by logging into the Utande Billing portal.</p>
      <p style="color:#718096;font-size:13px;margin:0;">If you believe this is an error, please contact our support team immediately.</p>
    `),
  }),

  serviceRestored: (customerName: string, serviceName: string) => ({
    subject: `Service Restored — ${serviceName} | Utande`,
    html: baseWrapper('#48bb78', 'Service Restored', `
      <p style="color:#2d3748;font-size:14px;margin:0 0 12px;">Dear ${customerName},</p>
      <p style="color:#4a5568;font-size:14px;margin:0 0 8px;">Your <strong>${serviceName}</strong> service has been <strong style="color:#48bb78;">restored</strong>. Thank you for your payment!</p>
      <p style="color:#4a5568;font-size:14px;margin:0 0 8px;">All services are now fully operational. If you experience any issues, please contact our support team.</p>
      <p style="color:#718096;font-size:13px;margin:0;">Thank you for choosing Utande.</p>
    `),
  }),
};
