import { Response } from 'express';
import { z } from 'zod';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { ExpenseService } from '../../expenses/expense.service.js';

const CreateExpenseSchema = z.union([
  z.object({
    text: z.string().min(1, 'El texto no puede estar vacío'),
  }),
  z.object({
    amount: z.number().positive('El monto debe ser mayor a 0'),
    description: z.string().min(1, 'La descripción es requerida'),
    category: z.string().min(1, 'La categoría es requerida'),
    date: z.string().optional(),
    installments: z.number().int().min(1).optional(),
    currency: z.string().optional(),
  }),
]);

export function createExpenseController(expenseService: ExpenseService) {
  return {
    async listExpenses(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const take = req.query.limit ? Number(req.query.limit) : 50;
      const skip = req.query.offset ? Number(req.query.offset) : 0;
      const category = req.query.category as string | undefined;

      const expenses = await expenseService.listExpenses(userId, { take, skip, category });
      res.json({ data: expenses });
    },

    async getExpense(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const id = String(req.params.id);

      const expense = await expenseService.getExpense(userId, id);
      res.json({ data: expense });
    },

    async createExpense(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const body = CreateExpenseSchema.parse(req.body);

      if ('text' in body) {
        // Creación mediante procesamiento de lenguaje natural
        const expense = await expenseService.createFromText(userId, body.text);
        res.status(201).json({ data: expense });
      } else {
        // Creación estructurada directa
        const expense = await expenseService.createManual(userId, body);
        res.status(201).json({ data: expense });
      }
    },

    async deleteExpense(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const id = String(req.params.id);

      await expenseService.deleteExpense(userId, id);
      res.status(204).send();
    },

    async getMonthlySummary(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const summary = await expenseService.getMonthlySummary(userId);
      res.json({ data: summary });
    },
  };
}
