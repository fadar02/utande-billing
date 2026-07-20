import { Router } from 'express';
import { InvoiceController } from '../controllers/invoiceController';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { z } from 'zod';

const router = Router();

const createSchema = z.object({
  customerId: z.string().uuid(),
  customerServiceId: z.string().uuid().optional(),
  items: z.array(z.object({
    description: z.string().min(1),
    quantity: z.number().min(0),
    unitPrice: z.number().min(0),
    amount: z.number().min(0),
  })).min(1),
  taxRate: z.number().min(0).optional(),
  dueDate: z.string().min(1),
  description: z.string().optional(),
  billingPeriodStart: z.string().optional(),
  billingPeriodEnd: z.string().optional(),
});

const updateSchema = z.object({
  status: z.string().optional(),
  description: z.string().optional(),
  notes: z.string().optional(),
});

router.use(authenticate);

router.get('/', InvoiceController.getAll);
router.get('/:id', InvoiceController.getById);
router.post('/', authorize('ADMIN', 'FINANCE', 'SALES'), validate(createSchema), InvoiceController.create);
router.put('/:id', validate(updateSchema), InvoiceController.update);
router.post('/:id/cancel', authorize('ADMIN', 'FINANCE'), InvoiceController.cancel);
router.get('/:id/pdf', InvoiceController.downloadPDF);
router.get('/:id/reminders', InvoiceController.getReminderHistory);
router.post('/auto-generate', authorize('ADMIN', 'FINANCE'), InvoiceController.autoGenerate);

export default router;
