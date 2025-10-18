// src/routes/users.routes.ts
import { Router } from 'express';
import { UsersController } from '../controllers/users.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { authorize } from '../middlewares/authorize.middleware';

const router = Router();

// Solo autenticados pueden listar; solo admin puede crear/editar/borrar
router.get('/', authMiddleware, authorize('admin', 'user'), UsersController.list);
router.get('/:id', authMiddleware, authorize('admin', 'user'), UsersController.get);
router.post('/', authMiddleware, authorize('admin'), UsersController.create);
router.put('/:id', authMiddleware, authorize('admin'), UsersController.update);
router.delete('/:id', authMiddleware, authorize('admin'), UsersController.remove);

export default router;
