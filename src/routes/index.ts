import { Router } from "express";
import { pingController } from "../controllers/ping.controller";
import usersRoutes from "./users.routes";
import authRoutes from "./auth.routes";

const router = Router();

router.get("/ping", pingController);
router.use("/users", usersRoutes);
router.use("/auth", authRoutes);

export default router;
