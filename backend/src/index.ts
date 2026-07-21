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
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: '*' }));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 500 }));

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

// Debug: email log viewer
app.get('/api/debug/email-logs', async (_req, res) => {
  try {
    const logs = await prisma.emailLog.findMany({ orderBy: { createdAt: 'desc' }, take: 10 });
    res.json(logs);
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
});

// Health check
app.get('/api/health', async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: 'Database connection failed' });
  }
});

// API 404 — must be before frontend catch-all
app.use('/api', (_req, res) => {
  res.status(404).json({ error: 'API endpoint not found' });
});

// Serve frontend build in production
const frontendBuild = path.join(__dirname, '../../frontend/dist');
logger.info(`Serving frontend from: ${frontendBuild}`);
app.use(express.static(frontendBuild));
app.get('*', (_req, res) => {
  res.sendFile(path.join(frontendBuild, 'index.html'));
});

// Error handling middleware
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error(`Unhandled error: ${err.message}`, { stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
const start = async () => {
  try {
    try {
      const { execSync } = require('child_process');
      const backendDir = path.resolve(__dirname, '..');
      const prismaBin = path.join(backendDir, 'node_modules', '.bin', 'prisma');
      execSync(`"${prismaBin}" db push --skip-generate --accept-data-loss`, { stdio: 'inherit', cwd: backendDir, timeout: 30000 });
      logger.info('Database schema synced');
    } catch (e: any) {
      logger.error(`prisma db push failed: ${e.message}`);
    }

    await prisma.$connect();
    logger.info('Database connected');

    startScheduler();

    app.listen(config.port, () => {
      logger.info(`Utande Billing API running on port ${config.port}`);
    });
  } catch (error: any) {
    logger.error(`Failed to start server: ${error.message}`);
    process.exit(1);
  }
};

start();

export default app;
