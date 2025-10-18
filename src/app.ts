// src/app.ts
import express, { Request, Response } from "express";
import routes from "./routes";
import { errorMiddleware } from "./middlewares/error.middleware";

const app = express();

app.use(express.json());
app.use("/api", routes);

app.get("/health", (_req: Request, res: Response) => {
  res.json({ status: "ok" });
});

app.use(errorMiddleware);

export default app;
