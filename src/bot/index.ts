import { Bot } from 'grammy';
import { BotContext } from './bot.context.js';
import { createUserMiddleware } from './middlewares/user.middleware.js';
import { registerCommands } from './handlers/commands.js';
import { registerMessageHandler } from './handlers/message.js';
import { UserService } from '../users/user.service.js';
import { ExpenseService } from '../expenses/expense.service.js';
import { logger } from '../shared/logger.js';

export interface CreateBotDependencies {
  token: string;
  userService: UserService;
  expenseService: ExpenseService;
}

export function createBot({ token, userService, expenseService }: CreateBotDependencies): Bot<BotContext> {
  const bot = new Bot<BotContext>(token);

  // Middleware para identificar o registrar al usuario
  bot.use(createUserMiddleware(userService));

  // Registrar comandos (/start, /list, /total)
  registerCommands(bot, expenseService);

  // Registrar handler para texto en lenguaje natural
  registerMessageHandler(bot, expenseService);

  // Manejo de errores no capturados en el ciclo de vida del bot
  bot.catch((err) => {
    logger.error('Error no capturado en Grammy:', {
      ctx: err.ctx.update.update_id,
      error: err.error,
    });
  });

  return bot;
}
