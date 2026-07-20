import { Router } from 'express';
import { ReminderConfigController } from '../controllers/reminderConfigController';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

router.use(authenticate);
router.use(authorize('ADMIN'));

router.get('/config', ReminderConfigController.getConfig);
router.put('/config', ReminderConfigController.updateConfig);
router.get('/history/:invoiceId', ReminderConfigController.getReminderHistory);
router.get('/logs', ReminderConfigController.getAllLogs);
router.post('/trigger', ReminderConfigController.triggerNow);
router.post('/send', ReminderConfigController.sendManualReminder);

export default router;
