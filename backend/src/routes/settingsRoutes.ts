import { Router } from 'express';
import { SettingsController } from '../controllers/settingsController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.use(authenticate);
router.use(authorize('ADMIN', 'FINANCE'));

router.get('/', SettingsController.getAll);
router.get('/:key', SettingsController.get);
router.put('/', SettingsController.update);
router.post('/reset', SettingsController.reset);

export default router;
