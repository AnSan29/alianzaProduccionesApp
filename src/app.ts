import express, { Request, Response } from 'express';
import routes from './routes';

const app = express();

app.use(express.json());
app.use('/api', routes);

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok' });
});

export default app;
