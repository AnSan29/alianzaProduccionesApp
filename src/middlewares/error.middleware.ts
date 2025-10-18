// src/middlewares/error.middleware.ts
import { ZodError } from "zod";
import { Request, Response, NextFunction } from "express";

export function errorMiddleware(
  err: any,
  _req: Request,
  res: Response,
  _next: NextFunction
) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: "VALIDATION_ERROR",
      details: err.flatten(),
    });
  }

  const map: Record<string, number> = {
    USER_NOT_FOUND: 404,
    EMAIL_ALREADY_IN_USE: 409,
  };

  const code = (err && err.message && map[err.message]) || 500;
  const name = (err && err.message) || "INTERNAL_ERROR";

  if (code === 500) {
    console.error(err);
  }

  res.status(code).json({ error: name });
}
