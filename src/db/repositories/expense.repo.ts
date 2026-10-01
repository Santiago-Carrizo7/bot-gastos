import { Expense, Category } from '@prisma/client';
import { prisma } from '../prisma.js';
import { CreateExpenseData } from '../../expenses/expense.types.js';

export interface ExpenseAggregatedTotal {
  total: number;
  count: number;
}

export class ExpenseRepository {
  async create(data: CreateExpenseData): Promise<Expense> {
    return prisma.expense.create({
      data: {
        userId: data.userId,
        amount: data.amount,
        description: data.description,
        category: data.category as Category,
        date: data.date,
        installments: data.installments ?? 1,
        currency: data.currency ?? 'ARS',
      },
    });
  }

  async findLastByUserId(userId: string, limit: number = 5): Promise<Expense[]> {
    return prisma.expense.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      take: limit,
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
}
