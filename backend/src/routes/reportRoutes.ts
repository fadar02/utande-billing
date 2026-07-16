import { Router } from 'express';
import { ReportController } from '../controllers/reportController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.use(authenticate);
router.use(authorize('ADMIN', 'FINANCE'));

router.get('/outstanding-invoices', ReportController.getOutstandingInvoices);
router.get('/paid-invoices', ReportController.getPaidInvoices);
router.get('/overdue-invoices', ReportController.getOverdueInvoices);
router.get('/revenue', ReportController.getRevenueReport);
router.get('/payments', ReportController.getPaymentReport);
router.get('/emails', ReportController.getEmailReport);
router.get('/reminders', ReportController.getReminderReport);

export default router;
