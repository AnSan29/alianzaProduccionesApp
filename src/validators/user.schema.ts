// src/validators/user.schema.ts
import { z } from 'zod';

export const createUserSchema = z.object({
  name: z.string().min(2).max(120),
  email: z.string().email().max(160),
  password: z.string().min(8).max(72),
  role: z.enum(['user', 'admin']).optional()
});

export const updateUserSchema = z.object({
  name: z.string().min(2).max(120).optional(),
  email: z.string().email().max(160).optional(),
  password: z.string().min(8).max(72).optional(),
  role: z.enum(['user', 'admin']).optional(),
  is_active: z.boolean().optional()
});

export type CreateUserInput = z.infer<typeof createUserSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
