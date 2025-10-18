// src/services/users.service.ts
import { UsersRepository } from '../repositories/users.repository';
import { CreateUserInput, UpdateUserInput } from '../validators/user.schema';
import bcrypt from 'bcryptjs';

export class UsersService {
  static async list(page = 1, size = 20, search?: string) {
    const limit = Math.max(1, Math.min(size, 100));
    const offset = (Math.max(1, page) - 1) * limit;
    const { rows, count } = await UsersRepository.findAll(offset, limit, search);
    return {
      data: rows,
      pagination: {
        page,
        size: limit,
        total: count,
        pages: Math.ceil(count / limit) || 1
      }
    };
    }

  static async get(id: number) {
    const user = await UsersRepository.findById(id);
    if (!user) throw new Error('USER_NOT_FOUND');
    return user;
  }

  static async create(payload: CreateUserInput) {
    const exists = await UsersRepository.findByEmail(payload.email);
    if (exists) throw new Error('EMAIL_ALREADY_IN_USE');
    const password_hash = await bcrypt.hash(payload.password, 10);
    const user = await UsersRepository.create({
      name: payload.name,
      email: payload.email,
      password_hash,
      role: payload.role || 'user',
      is_active: true
    });
    return user;
  }

  static async update(id: number, payload: UpdateUserInput) {
    const user = await UsersRepository.findById(id);
    if (!user) throw new Error('USER_NOT_FOUND');

    if (payload.email && payload.email !== user.email) {
      const taken = await UsersRepository.findByEmail(payload.email);
      if (taken) throw new Error('EMAIL_ALREADY_IN_USE');
    }

    let password_hash: string | undefined;
    if (payload.password) {
      password_hash = await bcrypt.hash(payload.password, 10);
    }

    const updated = await UsersRepository.update(id, {
      name: payload.name ?? user.name,
      email: payload.email ?? user.email,
      role: payload.role ?? user.role,
      is_active: payload.is_active ?? user.is_active,
      password_hash: password_hash ?? user.password_hash
    });

    return updated!;
  }

  static async remove(id: number) {
    const removed = await UsersRepository.softDelete(id);
    if (!removed) throw new Error('USER_NOT_FOUND');
    return removed;
  }
}
