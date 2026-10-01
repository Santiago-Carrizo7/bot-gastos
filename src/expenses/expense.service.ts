import { Expense } from '@prisma/client';
import { ExpenseRepository } from '../db/repositories/expense.repo.js';
import { ExpenseParser } from '../ai/expense-parser.js';
import { MonthlyTotal } from './expense.types.js';

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

export class ExpenseService {
  constructor(
    private readonly expenseRepo: ExpenseRepository,
    private readonly expenseParser: ExpenseParser
  ) {}

  async createFromText(userId: string, text: string): Promise<Expense> {
    const now = new Date();
    const parsed = await this.expenseParser.parse(text, now);

    // Creamos la fecha a partir del string YYYY-MM-DD asignando mediodía UTC
    // para evitar que zonas horarias locales cambien el día calendario
    const [year, month, day] = parsed.date.split('-').map(Number);
    const date = new Date(Date.UTC(year, month - 1, day, 12, 0, 0));

    return this.expenseRepo.create({
      userId,
      amount: parsed.amount,
      description: parsed.description,
      category: parsed.category,
      date,
      installments: parsed.installments,
      currency: parsed.currency,
    });
  }

  async getLastExpenses(userId: string, limit: number = 5): Promise<Expense[]> {
    return this.expenseRepo.findLastByUserId(userId, limit);
  }

  async getCurrentMonthTotal(userId: string, referenceDate: Date = new Date()): Promise<MonthlyTotal> {
    const year = referenceDate.getFullYear();
    const month = referenceDate.getMonth();

    const startDate = new Date(Date.UTC(year, month, 1, 0, 0, 0));
    // Último milisegundo del mes
    const endDate = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59, 999));

    const aggregate = await this.expenseRepo.getTotalByUserIdAndDateRange(userId, startDate, endDate);

    return {
      total: aggregate.total,
      count: aggregate.count,
      monthName: MONTH_NAMES[month],
      year,
    };
  }
}
