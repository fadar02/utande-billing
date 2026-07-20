import { Router } from 'express';
import { SettingsController } from '../controllers/settingsController';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { z } from 'zod';

const router = Router();

const updateSchema = z.object({
  settings: z.array(z.object({
    key: z.string().min(1),
    value: z.string(),
  })).min(1),
});

router.use(authenticate);
router.use(authorize('ADMIN', 'FINANCE'));

router.get('/', SettingsController.getAll);
router.get('/:key', SettingsController.get);
router.put('/', validate(updateSchema), SettingsController.update);
router.post('/reset', SettingsController.reset);

export default router;
