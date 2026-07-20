import { Router } from 'express';
import { ServiceController } from '../controllers/serviceController';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { z } from 'zod';

const router = Router();

const createSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  type: z.string().min(1),
  monthlyRate: z.number().min(0),
  setupFee: z.number().min(0).optional(),
});

const updateSchema = z.object({
  name: z.string().min(1).optional(),
  description: z.string().optional(),
  type: z.string().min(1).optional(),
  monthlyRate: z.number().min(0).optional(),
  setupFee: z.number().min(0).optional(),
  isActive: z.boolean().optional(),
});

const assignSchema = z.object({
  customerId: z.string().uuid(),
  serviceId: z.string().uuid(),
  customRate: z.number().optional(),
  monthlyRate: z.number().min(0).optional(),
});

router.use(authenticate);

router.get('/', ServiceController.getAll);
router.get('/:id', ServiceController.getById);
router.post('/', authorize('ADMIN', 'TECHNICAL'), validate(createSchema), ServiceController.create);
router.put('/:id', authorize('ADMIN', 'TECHNICAL'), validate(updateSchema), ServiceController.update);
router.delete('/:id', authorize('ADMIN'), ServiceController.delete);
router.post('/assign', authorize('ADMIN', 'SALES', 'FINANCE'), validate(assignSchema), ServiceController.assignToCustomer);
router.put('/customer-service/:id', ServiceController.updateCustomerService);
router.delete('/customer-service/:id', ServiceController.removeCustomerService);

export default router;
