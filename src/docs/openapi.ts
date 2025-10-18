// src/docs/openapi.ts
import swaggerJSDoc from 'swagger-jsdoc';
import * as swaggerUi from 'swagger-ui-express';
import { Express } from 'express';

const options = {
  definition: {
    openapi: '3.0.3',
    info: {
      title: 'Alianza Producciones API',
      version: '1.0.0',
      description: 'Documentación OpenAPI del servidor Node + TS + Sequelize'
    },
    servers: [{ url: 'http://localhost:3000' }]
  },
  apis: ['src/routes/*.ts']
};

export const swaggerSpec = swaggerJSDoc(options);

export function setupSwagger(app: Express) {
  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
}
