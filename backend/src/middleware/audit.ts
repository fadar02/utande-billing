import { Request, Response, NextFunction } from 'express';
import prisma from '../config/database';
import { AuthRequest } from './auth';

export const auditLog = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  const originalJson = res.json.bind(res);
  res.json = function (body: any) {
    if (res.statusCode >= 200 && res.statusCode < 300 && req.user) {
      const logData = {
        userId: req.user.id,
        action: `${req.method} ${req.path}`,
        entity: req.path.split('/')[1] || 'unknown',
        entityId: req.params.id || null,
        newValues: req.method !== 'GET' ? JSON.stringify(req.body) : undefined,
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
      };

      prisma.auditLog.create({ data: logData }).catch(console.error);
    }
    return originalJson(body);
  };
  next();
};
