import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || process.env.APP_PORT || '3000', 10),
  appUrl: process.env.APP_URL || 'http://localhost:3000',
  jwt: {
    secret: process.env.JWT_SECRET || 'fallback-secret',
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
  },
  smtp: {
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
    from: process.env.SMTP_FROM || 'Utande Billing <billing@utande.com>',
  },
  reminders: {
    sevenDays: process.env.REMINDER_7_DAYS === 'true',
    threeDays: process.env.REMINDER_3_DAYS === 'true',
    oneDay: process.env.REMINDER_1_DAY === 'true',
    onDueDate: process.env.REMINDER_ON_DUE_DATE === 'true',
    overdue: process.env.REMINDER_OVERDUE === 'true',
    overdueIntervalDays: parseInt(process.env.REMINDER_OVERDUE_INTERVAL_DAYS || '3', 10),
  },
};
