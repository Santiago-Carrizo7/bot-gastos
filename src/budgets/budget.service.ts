import { Budget } from '@prisma/client';
import { BudgetRepository } from '../db/repositories/budget.repo.js';
import { ExpenseRepository } from '../db/repositories/expense.repo.js';
import { CategoryService } from '../categories/category.service.js';
import { AppError } from '../shared/errors.js';

export interface BudgetProgress {
  id: string;
  category: string;
  budgetAmount: number;
  spentAmount: number;
  remainingAmount: number;
  percentageUsed: number;
  isExceeded: boolean;
  currency: string;
}

export class BudgetService {
  constructor(
    private readonly budgetRepo: BudgetRepository,
    private readonly expenseRepo: ExpenseRepository,
    private readonly categoryService?: CategoryService
  ) {}

  async setBudget(userId: string, category: string, amount: number, currency: string = 'ARS'): Promise<Budget> {
    if (amount <= 0) {
      throw new AppError('El monto del presupuesto debe ser mayor a 0');
    }

    const normalizedCategory = category.toLowerCase().trim();

    if (this.categoryService) {
      const allowed = await this.categoryService.getUserCategoryNames(userId);
      if (!allowed.includes(normalizedCategory)) {
        throw new AppError(`La categoría "${normalizedCategory}" no existe o no está activa para este usuario.`);
      }
    }

    return this.budgetRepo.upsert(userId, normalizedCategory, amount, currency);
  }

  async getBudgets(userId: string): Promise<Budget[]> {
    return this.budgetRepo.findByUser(userId);
  }

  async getBudgetsWithProgress(userId: string, referenceDate: Date = new Date()): Promise<BudgetProgress[]> {
    const budgets = await this.budgetRepo.findByUser(userId);
    if (budgets.length === 0) return [];

    const year = referenceDate.getFullYear();
    const month = referenceDate.getMonth();

    const startDate = new Date(Date.UTC(year, month, 1, 0, 0, 0));
    const endDate = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59, 999));

    const results: BudgetProgress[] = [];

    for (const b of budgets) {
      const { total: spent } = await this.expenseRepo.getTotalByCategoryAndDateRange(
        userId,
        b.category,
        startDate,
        endDate
      );

      const budgetAmount = Number(b.amount);
      const remainingAmount = budgetAmount - spent;
      const percentageUsed = budgetAmount > 0 ? Math.round((spent / budgetAmount) * 100) : 0;
      const isExceeded = spent > budgetAmount;

      results.push({
        id: b.id,
        category: b.category,
        budgetAmount,
        spentAmount: spent,
        remainingAmount,
        percentageUsed,
        isExceeded,
        currency: b.currency,
      });
    }

    return results;
  }

  async deleteBudget(userId: string, id: string): Promise<void> {
    const deleted = await this.budgetRepo.delete(id, userId);
    if (!deleted) {
      throw new AppError('Presupuesto no encontrado o no pertenece al usuario');
    }
  }
}
