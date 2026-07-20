import { Router } from 'express';
import { ReminderConfigController } from '../controllers/reminderConfigController';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { z } from 'zod';

const router = Router();

const configSchema = z.object({
  sevenDaysEnabled: z.boolean().optional(),
  threeDaysEnabled: z.boolean().optional(),
  oneDayEnabled: z.boolean().optional(),
  onDueDateEnabled: z.boolean().optional(),
  overdueEnabled: z.boolean().optional(),
  overdueIntervalDays: z.number().min(1).max(365).optional(),
  maxRetries: z.number().min(0).max(10).optional(),
});

const manualSendSchema = z.object({
  invoiceId: z.string().uuid(),
});

router.use(authenticate);
router.use(authorize('ADMIN'));

router.get('/config', ReminderConfigController.getConfig);
router.put('/config', validate(configSchema), ReminderConfigController.updateConfig);
router.get('/history/:invoiceId', ReminderConfigController.getReminderHistory);
router.get('/logs', ReminderConfigController.getAllLogs);
router.post('/trigger', ReminderConfigController.triggerNow);
router.post('/send', validate(manualSendSchema), ReminderConfigController.sendManualReminder);

export default router;
