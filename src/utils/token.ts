import * as jwt from "jsonwebtoken";
import { jwtConfig } from "../config/jwt";
import { JwtUserPayload } from "../types/express";

export function signToken(payload: JwtUserPayload): string {
  return jwt.sign(
    payload,
    jwtConfig.secret, // ← ya es string
    { expiresIn: jwtConfig.expiresIn as jwt.SignOptions["expiresIn"] }
  );
}

export function verifyToken(token: string): JwtUserPayload | null {
  try {
    return jwt.verify(token, jwtConfig.secret) as JwtUserPayload;
  } catch {
    return null;
  }
}
  