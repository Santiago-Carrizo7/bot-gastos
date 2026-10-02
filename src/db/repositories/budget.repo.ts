import { Budget } from '@prisma/client';
import { prisma } from '../prisma.js';

export class BudgetRepository {
  async upsert(userId: string, category: string, amount: number, currency: string = 'ARS'): Promise<Budget> {
    const normalizedCategory = category.toLowerCase().trim();

    return prisma.budget.upsert({
      where: {
        userId_category: {
          userId,
          category: normalizedCategory,
        },
      },
      create: {
        userId,
        category: normalizedCategory,
        amount,
        currency,
      },
      update: {
        amount,
        currency,
      },
    });
  }

  async findByUser(userId: string): Promise<Budget[]> {
    return prisma.budget.findMany({
      where: { userId },
      orderBy: { category: 'asc' },
    });
  }

  async findById(id: string, userId: string): Promise<Budget | null> {
    return prisma.budget.findFirst({
      where: { id, userId },
    });
  }

  async delete(id: string, userId: string): Promise<Budget | null> {
    const existing = await this.findById(id, userId);
    if (!existing) return null;

    return prisma.budget.delete({
      where: { id },
    });
  }
}
