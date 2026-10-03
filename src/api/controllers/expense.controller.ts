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

const UpdateExpenseSchema = z.object({
  amount: z.number().positive('El monto debe ser mayor a 0').optional(),
  description: z.string().min(1, 'La descripción es requerida').optional(),
  category: z.string().min(1, 'La categoría es requerida').optional(),
  date: z.string().optional(),
  installments: z.number().int().min(1).optional(),
  currency: z.string().optional(),
});

export function createExpenseController(expenseService: ExpenseService) {
  return {
    async listExpenses(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const take = req.query.limit ? Number(req.query.limit) : 50;
      const skip = req.query.offset ? Number(req.query.offset) : 0;
      const category = req.query.category as string | undefined;
      const search = req.query.search as string | undefined;

      let startDate: Date | undefined;
      let endDate: Date | undefined;
      if (req.query.startDate && typeof req.query.startDate === 'string') {
        startDate = new Date(req.query.startDate);
      }
      if (req.query.endDate && typeof req.query.endDate === 'string') {
        endDate = new Date(req.query.endDate);
      }

      const expenses = await expenseService.listExpenses(userId, {
        take,
        skip,
        category,
        search,
        startDate,
        endDate,
      });
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

    async updateExpense(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const id = String(req.params.id);
      const body = UpdateExpenseSchema.parse(req.body);

      const updated = await expenseService.updateExpense(userId, id, body);
      res.json({ data: updated });
    },

    async deleteExpense(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const id = String(req.params.id);

      await expenseService.deleteExpense(userId, id);
      res.status(204).send();
    },

    async getMonthlySummary(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      let refDate = new Date();
      if (req.query.year && req.query.month) {
        const y = Number(req.query.year);
        const m = Number(req.query.month);
        if (!isNaN(y) && !isNaN(m) && m >= 1 && m <= 12) {
          refDate = new Date(Date.UTC(y, m - 1, 1, 12, 0, 0));
        }
      }
      const summary = await expenseService.getMonthlySummary(userId, refDate);
      res.json({ data: summary });
    },

    async getAnalytics(req: AuthenticatedRequest, res: Response) {
      const userId = req.userId!;
      const months = req.query.months ? Number(req.query.months) : 6;
      const history = await expenseService.getMonthlyHistory(userId, months);

      let refDate = new Date();
      if (req.query.year && req.query.month) {
        const y = Number(req.query.year);
        const m = Number(req.query.month);
        if (!isNaN(y) && !isNaN(m) && m >= 1 && m <= 12) {
          refDate = new Date(Date.UTC(y, m - 1, 1, 12, 0, 0));
        }
      }
      const current = await expenseService.getMonthlySummary(userId, refDate);

      res.json({
        data: {
          current,
          monthlyHistory: history,
        },
      });
    },
  };
}
