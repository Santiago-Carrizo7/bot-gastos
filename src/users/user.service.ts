import { User } from '@prisma/client';
import { UserRepository } from '../db/repositories/user.repo.js';

export class UserService {
  constructor(private readonly userRepo: UserRepository) {}

  async getOrCreateByTelegramId(telegramId: string): Promise<User> {
    return this.userRepo.findOrCreate(telegramId);
  }
}
