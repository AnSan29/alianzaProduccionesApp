// src/controllers/auth.controller.ts
import { Request, Response, NextFunction } from 'express';
import { UsersService } from '../services/users.service';
import { createUserSchema } from '../validators/user.schema';
import { signToken } from '../utils/token';
import bcrypt from 'bcryptjs';
import User from '../models/user.model';

export class AuthController {
  static async register(req: Request, res: Response, next: NextFunction) {
    try {
      const data = createUserSchema.parse(req.body);
      const user = await UsersService.create(data);

      const token = signToken({ id: user.id, email: user.email, role: user.role });
      return res.status(201).json({ token, user });
    } catch (err) {
      return next(err);
    }
  }

  static async login(req: Request, res: Response, next: NextFunction) {
    try {
      const { email, password } = req.body as { email: string; password: string };
      const user = await User.findOne({ where: { email } });

      if (!user) {
        res.status(401).json({ error: 'INVALID_CREDENTIALS' });
        return; // 👈 ayuda a TS a “olvidar” el null
      }

      const valid = await bcrypt.compare(password, user.password_hash);
      if (!valid) {
        res.status(401).json({ error: 'INVALID_CREDENTIALS' });
        return;
      }

      const token = signToken({ id: user.id, email: user.email, role: user.role });
      return res.json({ token, user });
    } catch (err) {
      return next(err);
    }
  }

  static async me(req: Request, res: Response) {
    return res.json({ user: req.user || null });
  }
}
