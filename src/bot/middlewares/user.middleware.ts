import { NextFunction } from 'grammy';
import { BotContext } from '../bot.context.js';
import { UserService } from '../../users/user.service.js';

export function createUserMiddleware(userService: UserService) {
  return async (ctx: BotContext, next: NextFunction): Promise<void> => {
    if (!ctx.from) {
      return next();
    }

    const telegramId = String(ctx.from.id);
    const user = await userService.getOrCreateByTelegramId(telegramId);
    ctx.user = user;

    await next();
  };
}
