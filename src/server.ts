import app from './app';
import env from './config/env';
import { testConnection } from './database/sequelize';

async function bootstrap() {
  await testConnection();

  app.listen(env.port, () => {
    console.log(`🚀 Server running on http://localhost:${env.port} [${env.nodeEnv}]`);
  });
}

bootstrap().catch((err) => {
  console.error('Startup failed:', err);
  process.exit(1);
});
