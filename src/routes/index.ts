// src/routes/index.ts
import { Router } from "express";
import { pingController } from "../controllers/ping.controller";
import usersRoutes from "./users.routes";

const router = Router();

router.get("/ping", pingController);
router.use("/users", usersRoutes);

export default router;
