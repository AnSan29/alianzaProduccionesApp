import 'express';

export interface JwtUserPayload {
  id: number;
  email: string;
  role: 'user' | 'admin';
  iat?: number;
  exp?: number;
}

declare module 'express-serve-static-core' {
  interface Request {
    user?: JwtUserPayload;
  }
}
