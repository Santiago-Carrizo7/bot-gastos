import { Category } from '@prisma/client';
import { prisma } from '../prisma.js';
import { SYSTEM_CATEGORIES } from '../../expenses/expense.types.js';

export class CategoryRepository {
  async ensureSystemCategories(): Promise<void> {
    for (const cat of SYSTEM_CATEGORIES) {
      const existing = await prisma.category.findFirst({
        where: {
          name: cat.name,
          isSystem: true,
          userId: null,
        },
      });

      if (!existing) {
        await prisma.category.create({
          data: {
            name: cat.name,
            icon: cat.icon,
            isSystem: true,
            userId: null,
            isActive: true,
          },
        });
      }
    }
  }

  async findActiveByUser(userId: string): Promise<Category[]> {
    return prisma.category.findMany({
      where: {
        isActive: true,
        OR: [{ isSystem: true, userId: null }, { userId }],
      },
      orderBy: [{ isSystem: 'desc' }, { name: 'asc' }],
    });
  }

  async findByNameAndUser(name: string, userId?: string): Promise<Category | null> {
    const normalizedName = name.trim().toLowerCase();

    // Primero busca categoría personalizada del usuario
    if (userId) {
      const custom = await prisma.category.findFirst({
        where: {
          name: normalizedName,
          userId,
          isActive: true,
        },
      });
      if (custom) return custom;
    }

    // Si no, busca categoría del sistema
    return prisma.category.findFirst({
      where: {
        name: normalizedName,
        isSystem: true,
        userId: null,
        isActive: true,
      },
    });
  }

  async findById(id: string): Promise<Category | null> {
    return prisma.category.findUnique({
      where: { id },
    });
  }

  async create(data: { name: string; icon?: string; userId: string }): Promise<Category> {
    return prisma.category.create({
      data: {
        name: data.name.trim().toLowerCase(),
        icon: data.icon?.trim(),
        isSystem: false,
        userId: data.userId,
        isActive: true,
      },
    });
  }

  async update(id: string, userId: string, data: { name?: string; icon?: string }): Promise<Category> {
    return prisma.category.update({
      where: { id, userId },
      data: {
        ...(data.name ? { name: data.name.trim().toLowerCase() } : {}),
        ...(data.icon !== undefined ? { icon: data.icon?.trim() } : {}),
      },
    });
  }

  async deactivate(id: string, userId: string): Promise<Category> {
    return prisma.category.update({
      where: { id, userId, isSystem: false },
      data: { isActive: false },
    });
  }
}
