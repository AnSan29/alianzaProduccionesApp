// src/controllers/users.controller.ts
import { Request, Response, NextFunction } from "express";
import { UsersService } from "../services/users.service";
import { createUserSchema, updateUserSchema } from "../validators/user.schema";

export class UsersController {
  static async list(req: Request, res: Response, next: NextFunction) {
    try {
      const page = parseInt((req.query.page as string) || "1", 10);
      const size = parseInt((req.query.size as string) || "20", 10);
      const search = (req.query.search as string) || undefined;
      const result = await UsersService.list(page, size, search);
      res.json(result);
    } catch (e) {
      next(e);
    }
  }

  static async get(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Number(req.params.id);
      const user = await UsersService.get(id);
      res.json(user);
    } catch (e) {
      next(e);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction) {
    try {
      const parsed = createUserSchema.parse(req.body);
      const user = await UsersService.create(parsed);
      res.status(201).json(user);
    } catch (e) {
      next(e);
    }
  }

  static async update(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Number(req.params.id);
      const parsed = updateUserSchema.parse(req.body);
      const user = await UsersService.update(id, parsed);
      res.json(user);
    } catch (e) {
      next(e);
    }
  }

  static async remove(req: Request, res: Response, next: NextFunction) {
    try {
      const id = Number(req.params.id);
      const user = await UsersService.remove(id);
      res.json(user);
    } catch (e) {
      next(e);
    }
  }
}
