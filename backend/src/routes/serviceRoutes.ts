import { Router } from 'express';
import { ServiceController } from '../controllers/serviceController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.use(authenticate);

router.get('/', ServiceController.getAll);
router.get('/:id', ServiceController.getById);
router.post('/', authorize('ADMIN', 'TECHNICAL'), ServiceController.create);
router.put('/:id', authorize('ADMIN', 'TECHNICAL'), ServiceController.update);
router.delete('/:id', authorize('ADMIN'), ServiceController.delete);
router.post('/assign', authorize('ADMIN', 'SALES', 'FINANCE'), ServiceController.assignToCustomer);
router.put('/customer-service/:id', ServiceController.updateCustomerService);
router.delete('/customer-service/:id', ServiceController.removeCustomerService);

export default router;
