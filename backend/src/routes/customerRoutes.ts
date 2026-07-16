import { Router } from 'express';
import { CustomerController } from '../controllers/customerController';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { z } from 'zod';

const router = Router();

const customerSchema = z.object({
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  email: z.string().email(),
  phone: z.string().min(1),
  notes: z.string().optional(),
});

const sendEmailSchema = z.object({
  subject: z.string().min(1),
  message: z.string().min(1),
});

router.use(authenticate);

router.get('/', CustomerController.getAll);
router.get('/:id', CustomerController.getById);
router.post('/', validate(customerSchema), CustomerController.create);
router.put('/:id', CustomerController.update);
router.delete('/:id', authorize('ADMIN'), CustomerController.delete);
router.get('/:id/statement', CustomerController.getStatement);
router.post('/:id/send-email', validate(sendEmailSchema), CustomerController.sendEmail);

export default router;
