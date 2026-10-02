import { Response } from 'express';
import { z } from 'zod';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { BudgetService } from '../../budgets/budget.service.js';

const SetBudgetSchema = z.object({
  category: z.string().trim().min(1, 'La categoría es obligatoria'),
  amount: z.number().positive('El monto debe ser mayor a 0'),
  currency: z.string().optional(),
});

export function createBudgetController(budgetService: BudgetService) {
  return {
    async listBudgets(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const progress = await budgetService.getBudgetsWithProgress(userId);
      res.json({ data: progress });
    },

    async setBudget(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const body = SetBudgetSchema.parse(req.body);

      const budget = await budgetService.setBudget(userId, body.category, body.amount, body.currency);
      res.status(201).json({ data: budget });
    },

    async deleteBudget(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const id = String(req.params.id);

      await budgetService.deleteBudget(userId, id);
      res.status(204).send();
    },
  };
}
