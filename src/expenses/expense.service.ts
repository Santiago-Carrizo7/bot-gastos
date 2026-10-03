import { Expense } from '@prisma/client';
import { ExpenseRepository, ExpenseFindOptions } from '../db/repositories/expense.repo.js';
import { ExpenseParser } from '../ai/expense-parser.js';
import { CategoryService } from '../categories/category.service.js';
import { MonthlyTotal } from './expense.types.js';
import { AppError } from '../shared/errors.js';

const MONTH_NAMES = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

export interface CreateManualExpenseDTO {
  amount: number;
  description: string;
  category: string;
  date?: string | Date;
  installments?: number;
  currency?: string;
}

export class ExpenseService {
  constructor(
    private readonly expenseRepo: ExpenseRepository,
    private readonly expenseParser: ExpenseParser,
    private readonly categoryService?: CategoryService
  ) {}

  async createFromText(userId: string, text: string): Promise<Expense> {
    const now = new Date();

    // Obtener las categorías activas permitidas para este usuario
    const availableCategories = this.categoryService
      ? await this.categoryService.getUserCategoryNames(userId)
      : undefined;

    const parsed = await this.expenseParser.parse(text, availableCategories, now);

    // Normalizar fecha al mediodía UTC
    const [year, month, day] = parsed.date.split('-').map(Number);
    const date = new Date(Date.UTC(year, month - 1, day, 12, 0, 0));

    // Buscar si existe la categoría para vincular el categoryId opcional
    let categoryId: string | undefined;
    if (this.categoryService) {
      const cat = await this.categoryService.findByNameForUser(parsed.category, userId);
      if (cat) categoryId = cat.id;
    }

    return this.expenseRepo.create({
      userId,
      amount: parsed.amount,
      description: parsed.description,
      category: parsed.category,
      categoryId,
      date,
      installments: parsed.installments,
      currency: parsed.currency,
    });
  }

  async createManual(userId: string, data: CreateManualExpenseDTO): Promise<Expense> {
    if (data.amount <= 0) {
      throw new AppError('El monto debe ser mayor a 0');
    }
    if (!data.description.trim()) {
      throw new AppError('La descripción no puede estar vacía');
    }

    const normalizedCategory = data.category.toLowerCase().trim();

    // Validar si la categoría está disponible para el usuario
    if (this.categoryService) {
      const allowed = await this.categoryService.getUserCategoryNames(userId);
      if (!allowed.includes(normalizedCategory)) {
        throw new AppError(`La categoría "${normalizedCategory}" no es válida.`);
      }
    }

    let parsedDate: Date;
    if (data.date) {
      if (typeof data.date === 'string') {
        const [y, m, d] = data.date.slice(0, 10).split('-').map(Number);
        parsedDate = new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
      } else {
        parsedDate = data.date;
      }
    } else {
      parsedDate = new Date();
    }

    let categoryId: string | undefined;
    if (this.categoryService) {
      const cat = await this.categoryService.findByNameForUser(normalizedCategory, userId);
      if (cat) categoryId = cat.id;
    }

    return this.expenseRepo.create({
      userId,
      amount: data.amount,
      description: data.description.trim(),
      category: normalizedCategory,
      categoryId,
      date: parsedDate,
      installments: data.installments ?? 1,
      currency: data.currency ?? 'ARS',
    });
  }

  async getExpense(userId: string, id: string): Promise<Expense> {
    const expense = await this.expenseRepo.findById(id, userId);
    if (!expense) {
      throw new AppError('Gasto no encontrado');
    }
    return expense;
  }

  async updateExpense(userId: string, id: string, data: Partial<CreateManualExpenseDTO>): Promise<Expense> {
    const existing = await this.expenseRepo.findById(id, userId);
    if (!existing) {
      throw new AppError('Gasto no encontrado o no pertenece al usuario');
    }

    if (data.amount !== undefined && data.amount <= 0) {
      throw new AppError('El monto debe ser mayor a 0');
    }
    if (data.description !== undefined && !data.description.trim()) {
      throw new AppError('La descripción no puede estar vacía');
    }

    let normalizedCategory: string | undefined;
    let categoryId: string | undefined;

    if (data.category !== undefined) {
      normalizedCategory = data.category.toLowerCase().trim();
      if (this.categoryService) {
        const allowed = await this.categoryService.getUserCategoryNames(userId);
        if (!allowed.includes(normalizedCategory)) {
          throw new AppError(`La categoría "${normalizedCategory}" no es válida.`);
        }
        const cat = await this.categoryService.findByNameForUser(normalizedCategory, userId);
        if (cat) categoryId = cat.id;
      }
    }

    let parsedDate: Date | undefined;
    if (data.date !== undefined) {
      if (typeof data.date === 'string') {
        const [y, m, d] = data.date.slice(0, 10).split('-').map(Number);
        parsedDate = new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
      } else {
        parsedDate = data.date;
      }
    }

    const updated = await this.expenseRepo.update(id, userId, {
      amount: data.amount,
      description: data.description?.trim(),
      category: normalizedCategory,
      categoryId,
      date: parsedDate,
      installments: data.installments,
      currency: data.currency,
    });

    if (!updated) {
      throw new AppError('No se pudo actualizar el gasto');
    }

    return updated;
  }

  async deleteExpense(userId: string, id: string): Promise<void> {
    const deleted = await this.expenseRepo.delete(id, userId);
    if (!deleted) {
      throw new AppError('Gasto no encontrado o no pertenece al usuario');
    }
  }

  async listExpenses(userId: string, options: ExpenseFindOptions = {}): Promise<Expense[]> {
    return this.expenseRepo.findManyByUser(userId, options);
  }

  async getLastExpenses(userId: string, limit: number = 5): Promise<Expense[]> {
    return this.expenseRepo.findLastByUserId(userId, limit);
  }

  async getCurrentMonthTotal(userId: string, referenceDate: Date = new Date()): Promise<MonthlyTotal> {
    const year = referenceDate.getFullYear();
    const month = referenceDate.getMonth();

    const startDate = new Date(Date.UTC(year, month, 1, 0, 0, 0));
    const endDate = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59, 999));

    const aggregate = await this.expenseRepo.getTotalByUserIdAndDateRange(userId, startDate, endDate);

    return {
      total: aggregate.total,
      count: aggregate.count,
      monthName: MONTH_NAMES[month],
      year,
    };
  }

  async getMonthlySummary(userId: string, referenceDate: Date = new Date()) {
    const year = referenceDate.getFullYear();
    const month = referenceDate.getMonth();

    const startDate = new Date(Date.UTC(year, month, 1, 0, 0, 0));
    const endDate = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59, 999));

    const expenses = await this.expenseRepo.findManyByUser(userId, {
      startDate,
      endDate,
      take: 1000,
    });

    const categoryBreakdown: Record<string, { total: number; count: number }> = {};
    let totalMonth = 0;

    for (const exp of expenses) {
      const amt = Number(exp.amount);
      totalMonth += amt;
      if (!categoryBreakdown[exp.category]) {
        categoryBreakdown[exp.category] = { total: 0, count: 0 };
      }
      categoryBreakdown[exp.category].total += amt;
      categoryBreakdown[exp.category].count += 1;
    }

    return {
      year,
      month: month + 1,
      monthName: MONTH_NAMES[month],
      total: totalMonth,
      count: expenses.length,
      categories: categoryBreakdown,
    };
  }

  async getMonthlyHistory(userId: string, monthsCount: number = 6) {
    const now = new Date();
    const history = [];

    for (let i = monthsCount - 1; i >= 0; i--) {
      const d = new Date(Date.UTC(now.getFullYear(), now.getMonth() - i, 1));
      const year = d.getUTCFullYear();
      const monthIndex = d.getUTCMonth();
      const startDate = new Date(Date.UTC(year, monthIndex, 1, 0, 0, 0));
      const endDate = new Date(Date.UTC(year, monthIndex + 1, 0, 23, 59, 59, 999));

      const aggregate = await this.expenseRepo.getTotalByUserIdAndDateRange(userId, startDate, endDate);
      history.push({
        year,
        month: monthIndex + 1,
        monthName: MONTH_NAMES[monthIndex],
        total: aggregate.total,
        count: aggregate.count,
      });
    }

    return history;
  }
}

