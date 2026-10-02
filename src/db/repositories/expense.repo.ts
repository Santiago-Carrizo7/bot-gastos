import { Expense } from '@prisma/client';
import { prisma } from '../prisma.js';
import { CreateExpenseData } from '../../expenses/expense.types.js';

export interface ExpenseAggregatedTotal {
  total: number;
  count: number;
}

export interface ExpenseFindOptions {
  skip?: number;
  take?: number;
  startDate?: Date;
  endDate?: Date;
  category?: string;
}

export class ExpenseRepository {
  async create(data: CreateExpenseData): Promise<Expense> {
    return prisma.expense.create({
      data: {
        userId: data.userId,
        amount: data.amount,
        description: data.description,
        category: data.category.toLowerCase().trim(),
        categoryId: data.categoryId,
        date: data.date,
        installments: data.installments ?? 1,
        currency: data.currency ?? 'ARS',
      },
    });
  }

  async findById(id: string, userId: string): Promise<Expense | null> {
    return prisma.expense.findFirst({
      where: { id, userId },
    });
  }

  async findLastByUserId(userId: string, limit: number = 5): Promise<Expense[]> {
    return prisma.expense.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take: limit,
    });
  }

  async findManyByUser(userId: string, options: ExpenseFindOptions = {}): Promise<Expense[]> {
    const { skip, take = 50, startDate, endDate, category } = options;

    return prisma.expense.findMany({
      where: {
        userId,
        ...(category ? { category: category.toLowerCase().trim() } : {}),
        ...(startDate || endDate
          ? {
              date: {
                ...(startDate ? { gte: startDate } : {}),
                ...(endDate ? { lte: endDate } : {}),
              },
            }
          : {}),
      },
      orderBy: { date: 'desc' },
      skip,
      take,
    });
  }

  async delete(id: string, userId: string): Promise<Expense | null> {
    const existing = await this.findById(id, userId);
    if (!existing) return null;

    return prisma.expense.delete({
      where: { id },
    });
  }

  async getTotalByUserIdAndDateRange(
    userId: string,
    startDate: Date,
    endDate: Date
  ): Promise<ExpenseAggregatedTotal> {
    const aggregate = await prisma.expense.aggregate({
      where: {
        userId,
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
      _sum: {
        amount: true,
      },
      _count: {
        id: true,
      },
    });

    return {
      total: aggregate._sum.amount ? Number(aggregate._sum.amount) : 0,
      count: aggregate._count.id,
    };
  }

  async getTotalByCategoryAndDateRange(
    userId: string,
    category: string,
    startDate: Date,
    endDate: Date
  ): Promise<ExpenseAggregatedTotal> {
    const aggregate = await prisma.expense.aggregate({
      where: {
        userId,
        category: category.toLowerCase().trim(),
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
      _sum: {
        amount: true,
      },
      _count: {
        id: true,
      },
    });

    return {
      total: aggregate._sum.amount ? Number(aggregate._sum.amount) : 0,
      count: aggregate._count.id,
    };
  }
}
