import { Router } from 'express';
import { PaymentController } from '../controllers/paymentController';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { z } from 'zod';

const router = Router();

const recordSchema = z.object({
  invoiceId: z.string().uuid(),
  customerId: z.string().uuid(),
  amount: z.number().min(0.01),
  paymentMethod: z.enum(['CASH', 'BANK_TRANSFER', 'MOBILE_MONEY', 'CARD', 'CHEQUE', 'OTHER']),
  reference: z.string().optional(),
  notes: z.string().optional(),
});

router.use(authenticate);

router.get('/', PaymentController.getAll);
router.get('/:id', PaymentController.getById);
router.post('/', authorize('ADMIN', 'FINANCE'), validate(recordSchema), PaymentController.record);
router.get('/:id/receipt', PaymentController.downloadReceipt);

export default router;
