import { Router } from 'express';
import { AuthController } from '../controllers/authController';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { z } from 'zod';

const router = Router();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  role: z.enum(['ADMIN', 'FINANCE', 'SALES', 'TECHNICAL']).optional(),
});

router.post('/login', validate(loginSchema), AuthController.login);
router.post('/register', validate(registerSchema), AuthController.register);
router.get('/profile', authenticate, AuthController.getProfile);
router.get('/users', authenticate, authorize('ADMIN'), AuthController.getAllUsers);
router.put('/users/:id', authenticate, authorize('ADMIN'), AuthController.updateUser);
router.put('/change-password', authenticate, AuthController.changePassword);

export default router;
