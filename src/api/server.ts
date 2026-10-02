import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { ZodError } from 'zod';
import { createApiRouter, CreateApiRouterDeps } from './routes.js';
import { AppError } from '../shared/errors.js';
import { logger } from '../shared/logger.js';

export function createExpressApp(deps: CreateApiRouterDeps): Express {
  const app = express();

  app.use(cors());
  app.use(express.json());

  // Logging de requests HTTP
  app.use((req: Request, _res: Response, next: NextFunction) => {
    logger.debug(`[HTTP] ${req.method} ${req.path}`);
    next();
  });

  // Montar rutas
  app.use(createApiRouter(deps));

  // Manejador centralizado de errores
  app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
    if (err instanceof ZodError) {
      const issues = err.issues.map((i) => `${i.path.join('.')}: ${i.message}`);
      res.status(400).json({
        error: 'VALIDATION_ERROR',
        details: issues,
      });
      return;
    }

    if (err instanceof AppError) {
      res.status(400).json({
        error: err.code,
        message: err.message,
      });
      return;
    }

    const message = err instanceof Error ? err.message : String(err);
    logger.error('[HTTP] Error no controlado en request:', err);
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Ocurrió un error inesperado en el servidor',
    });
  });

  return app;
}
