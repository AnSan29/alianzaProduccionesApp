import { Request, Response } from 'express';

export function pingController(_req: Request, res: Response) {
  res.json({ message: 'pong', at: new Date().toISOString() });
}
