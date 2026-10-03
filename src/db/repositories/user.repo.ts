import { User } from '@prisma/client';
import { prisma } from '../prisma.js';

export class UserRepository {
  async findByTelegramId(telegramId: string): Promise<User | null> {
    return prisma.user.findUnique({
      where: { telegramId },
    });
  }

  async create(telegramId: string): Promise<User> {
    return prisma.user.create({
      data: { telegramId },
    });
  }

  async findById(id: string): Promise<User | null> {
    return prisma.user.findUnique({
      where: { id },
    });
  }

  async findOrCreate(telegramId: string): Promise<User> {
    const existing = await this.findByTelegramId(telegramId);
    if (existing) {
      return existing;
    }
    return this.create(telegramId);
  }
}

