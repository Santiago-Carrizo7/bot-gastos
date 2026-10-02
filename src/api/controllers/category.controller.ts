import { Response } from 'express';
import { z } from 'zod';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { CategoryService } from '../../categories/category.service.js';

const CreateCategorySchema = z.object({
  name: z.string().trim().min(1, 'El nombre es obligatorio'),
  icon: z.string().trim().optional(),
});

const UpdateCategorySchema = z.object({
  name: z.string().trim().min(1).optional(),
  icon: z.string().trim().optional(),
});

export function createCategoryController(categoryService: CategoryService) {
  return {
    async listCategories(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const categories = await categoryService.getUserCategories(userId);
      res.json({ data: categories });
    },

    async createCategory(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const body = CreateCategorySchema.parse(req.body);

      const category = await categoryService.createCustomCategory(userId, body.name, body.icon);
      res.status(201).json({ data: category });
    },

    async updateCategory(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const id = String(req.params.id);
      const body = UpdateCategorySchema.parse(req.body);

      const category = await categoryService.updateCustomCategory(id, userId, body);
      res.json({ data: category });
    },

    async deactivateCategory(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const id = String(req.params.id);

      const category = await categoryService.deactivateCategory(id, userId);
      res.json({ data: category });
    },
  };
}
