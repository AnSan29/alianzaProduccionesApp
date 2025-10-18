import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/token';

export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer '))
    return res.status(401).json({ error: 'NO_TOKEN_PROVIDED' });

  const token = header.split(' ')[1];
  const payload = verifyToken(token);
  if (!payload) return res.status(401).json({ error: 'INVALID_TOKEN' });

  req.user = payload; // ← ya tipado por nuestra declaración
  next();
}
