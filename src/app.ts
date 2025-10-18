import express, { Request, Response } from "express";
import cors from "cors";
import helmet from "helmet";
import routes from "./routes";
import { errorMiddleware } from "./middlewares/error.middleware";
import { setupSwagger } from "./docs/openapi";

import { requestIdMiddleware } from "./middlewares/request-id.middleware";
import { httpLogger } from "./middlewares/http-logger.middleware";
import { authLimiter } from "./middlewares/rate-limit.middleware";

const app = express();

app.use(express.json());
app.use(cors());
app.use(helmet());

// id y logs (antes de rutas)
app.use(requestIdMiddleware);
app.use(httpLogger);

setupSwagger(app);

// limita /api/auth exclusivamente
app.use("/api/auth", authLimiter);

app.use("/api", routes);

app.get("/health", (_req: Request, res: Response) =>
  res.json({ status: "ok" })
);
app.get("/", (_req, res) =>
  res.send("Alianza Producciones API — OK. Revisa /api/docs")
);

app.use(errorMiddleware);

export default app;
