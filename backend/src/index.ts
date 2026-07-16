import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import rateLimit from 'express-rate-limit';
import { config } from './config';
import prisma from './config/database';
import logger from './utils/logger';
import { auditLog } from './middleware/audit';
import { startScheduler } from './jobs/scheduler';

// Routes
import authRoutes from './routes/authRoutes';
import customerRoutes from './routes/customerRoutes';
import serviceRoutes from './routes/serviceRoutes';
import invoiceRoutes from './routes/invoiceRoutes';
import paymentRoutes from './routes/paymentRoutes';
import reportRoutes from './routes/reportRoutes';
import dashboardRoutes from './routes/dashboardRoutes';
import reminderRoutes from './routes/reminderRoutes';
import publicRoutes from './routes/publicRoutes';
import settingsRoutes from './routes/settingsRoutes';

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({ origin: '*', credentials: true }));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Static files (logo for emails)
app.use('/assets', express.static(path.join(__dirname, '../public')));

// Public routes (no auth required)
app.use('/api/public', publicRoutes);

// Audit logging for write operations
app.use(auditLog);

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/invoices', invoiceRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/reminders', reminderRoutes);
app.use('/api/settings', settingsRoutes);

// Health check
app.get('/api/health', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: 'Database connection failed' });
  }
});

// Error handling middleware
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error(`Unhandled error: ${err.message}`, { stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
const start = async () => {
  try {
    await prisma.$connect();
    logger.info('Database connected');

    startScheduler();

    app.listen(config.port, () => {
      logger.info(`Utande Billing API running on port ${config.port}`);
      console.log(`\n  Utande Smart Billing System API`);
      console.log(`  ================================`);
      console.log(`  URL:      http://localhost:${config.port}`);
      console.log(`  Health:   http://localhost:${config.port}/api/health`);
      console.log(`  API Base: http://localhost:${config.port}/api\n`);
    });
  } catch (error: any) {
    logger.error(`Failed to start server: ${error.message}`);
    process.exit(1);
  }
};

start();

export default app;
