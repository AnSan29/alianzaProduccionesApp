import dotenv from 'dotenv';
dotenv.config();

const env = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  db: {
    dialect: (process.env.DB_DIALECT || 'mysql') as 'mysql' | 'mariadb' | 'postgres' | 'sqlite',
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    database: process.env.DB_NAME || 'alianza_db',
    username: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || ''
  }
};

export default env;
