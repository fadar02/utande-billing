import { Router } from 'express';
import { InvoiceController } from '../controllers/invoiceController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.use(authenticate);

router.get('/', InvoiceController.getAll);
router.get('/:id', InvoiceController.getById);
router.post('/', authorize('ADMIN', 'FINANCE', 'SALES'), InvoiceController.create);
router.put('/:id', InvoiceController.update);
router.post('/:id/cancel', authorize('ADMIN', 'FINANCE'), InvoiceController.cancel);
router.get('/:id/pdf', InvoiceController.downloadPDF);
router.get('/:id/reminders', InvoiceController.getReminderHistory);
router.post('/auto-generate', authorize('ADMIN', 'FINANCE'), InvoiceController.autoGenerate);

export default router;
