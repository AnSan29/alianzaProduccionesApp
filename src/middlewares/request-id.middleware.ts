import { Request, Response, NextFunction } from 'express';
import { v4 as uuid } from 'uuid';

export function requestIdMiddleware(req: Request, _res: Response, next: NextFunction) {
  (req as any).requestId = uuid();
  next();
}
