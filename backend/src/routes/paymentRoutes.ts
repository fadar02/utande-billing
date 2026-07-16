import { Router } from 'express';
import { PaymentController } from '../controllers/paymentController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.use(authenticate);

router.get('/', PaymentController.getAll);
router.get('/:id', PaymentController.getById);
router.post('/', authorize('ADMIN', 'FINANCE'), PaymentController.record);
router.get('/:id/receipt', PaymentController.downloadReceipt);

export default router;
