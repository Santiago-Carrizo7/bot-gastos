import { Request, Response, NextFunction } from 'express';
import { UserService } from '../../users/user.service.js';
import { logger } from '../../shared/logger.js';

export interface AuthenticatedRequest extends Request {
  userId?: string;
}

export function createAuthMiddleware(userService: UserService, apiSecret: string) {
  return async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
    try {
      const authHeader = req.headers.authorization;
      const devUserId = req.headers['x-user-id'] as string | undefined;

      // Opción 1: Header de desarrollo local x-user-id
      if (process.env.NODE_ENV !== 'production' && devUserId) {
        req.userId = devUserId;
        return next();
      }

      // Opción 2: Bearer Token
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({
          error: 'UNAUTHORIZED',
          message: 'Se requiere encabezado Authorization: Bearer <token>',
        });
        return;
      }

      const token = authHeader.slice(7).trim();

      // Descodificar el token generado por el bot con /token
      try {
        const decodedStr = Buffer.from(token, 'base64url').toString('utf8');
        const payload = JSON.parse(decodedStr) as { userId?: string };

        if (!payload.userId) {
          throw new Error('Payload sin userId');
        }

        req.userId = payload.userId;
        return next();
      } catch (tokenErr) {
        logger.warn('Token de autenticación inválido:', tokenErr);
        res.status(401).json({
          error: 'INVALID_TOKEN',
          message: 'El token de autenticación no es válido o ha expirado',
        });
        return;
      }
    } catch (err) {
      next(err);
    }
  };
}
