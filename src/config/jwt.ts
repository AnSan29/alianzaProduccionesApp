import dotenv from 'dotenv';
dotenv.config();

export const jwtConfig: {
  secret: string;
  expiresIn: string | number;
} = {
  secret: process.env.JWT_SECRET || 'supersecretkey',
  expiresIn: process.env.JWT_EXPIRES_IN || '1h'
};
