import { Router } from 'express';
import { DashboardController } from '../controllers/dashboardController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.use(authenticate);

router.get('/stats', DashboardController.getStats);
router.get('/revenue-chart', DashboardController.getRevenueChart);
router.get('/audit-logs', authorize('ADMIN'), DashboardController.getAuditLogs);

export default router;
