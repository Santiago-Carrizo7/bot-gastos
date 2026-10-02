import { Category } from '@prisma/client';
import { CategoryRepository } from '../db/repositories/category.repo.js';
import { AppError } from '../shared/errors.js';
import { DEFAULT_CATEGORY_NAMES } from '../expenses/expense.types.js';

export class CategoryService {
  constructor(private readonly categoryRepo: CategoryRepository) {}

  async init(): Promise<void> {
    await this.categoryRepo.ensureSystemCategories();
  }

  async getUserCategories(userId: string): Promise<Category[]> {
    return this.categoryRepo.findActiveByUser(userId);
  }

  async getUserCategoryNames(userId: string): Promise<string[]> {
    const categories = await this.categoryRepo.findActiveByUser(userId);
    if (categories.length === 0) {
      return [...DEFAULT_CATEGORY_NAMES];
    }
    return categories.map((c) => c.name.toLowerCase());
  }

  async findByNameForUser(name: string, userId: string): Promise<Category | null> {
    return this.categoryRepo.findByNameAndUser(name, userId);
  }

  async createCustomCategory(userId: string, name: string, icon?: string): Promise<Category> {
    const normalizedName = name.trim().toLowerCase();

    if (!normalizedName) {
      throw new AppError('El nombre de la categoría no puede estar vacío');
    }

    const existing = await this.categoryRepo.findByNameAndUser(normalizedName, userId);
    if (existing) {
      throw new AppError(`Ya existe una categoría con el nombre "${normalizedName}"`);
    }

    return this.categoryRepo.create({
      name: normalizedName,
      icon: icon ?? '🏷️',
      userId,
    });
  }

  async updateCustomCategory(
    id: string,
    userId: string,
    data: { name?: string; icon?: string }
  ): Promise<Category> {
    const category = await this.categoryRepo.findById(id);
    if (!category) {
      throw new AppError('Categoría no encontrada');
    }

    if (category.isSystem || category.userId !== userId) {
      throw new AppError('No podés editar una categoría del sistema o de otro usuario');
    }

    if (data.name) {
      const normalizedName = data.name.trim().toLowerCase();
      const existing = await this.categoryRepo.findByNameAndUser(normalizedName, userId);
      if (existing && existing.id !== id) {
        throw new AppError(`Ya existe una categoría con el nombre "${normalizedName}"`);
      }
    }

    return this.categoryRepo.update(id, userId, data);
  }

  async deactivateCategory(id: string, userId: string): Promise<Category> {
    const category = await this.categoryRepo.findById(id);
    if (!category) {
      throw new AppError('Categoría no encontrada');
    }

    if (category.isSystem || category.userId !== userId) {
      throw new AppError('No podés desactivar una categoría del sistema o de otro usuario');
    }

    return this.categoryRepo.deactivate(id, userId);
  }
}
