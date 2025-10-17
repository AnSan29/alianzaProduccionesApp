import { Sequelize } from 'sequelize';
import env from '../config/env';

const sequelize = new Sequelize(env.db.database, env.db.username, env.db.password, {
  host: env.db.host,
  port: env.db.port,
  dialect: env.db.dialect,
  logging: env.nodeEnv === 'development' ? console.log : false,
  define: {
    underscored: true,
    freezeTableName: true,
    timestamps: true
  }
});

export async function testConnection(): Promise<void> {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connection has been established successfully.');
  } catch (error) {
    console.error('❌ Unable to connect to the database:', error);
    throw error;
  }
}

export default sequelize;
