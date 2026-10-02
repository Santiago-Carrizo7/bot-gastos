import { Bot } from 'grammy';
import { BotContext } from './bot.context.js';
import { createUserMiddleware } from './middlewares/user.middleware.js';
import { registerCommands } from './handlers/commands.js';
import { registerMessageHandler } from './handlers/message.js';
import { registerVoiceHandler } from './handlers/voice.js';
import { UserService } from '../users/user.service.js';
import { ExpenseService } from '../../src/expenses/expense.service.js';
import { CategoryService } from '../categories/category.service.js';
import { BudgetService } from '../budgets/budget.service.js';
import { SpeechToTextService } from '../ai/stt/stt.service.js';
import { logger } from '../shared/logger.js';

export interface CreateBotDependencies {
  token: string;
  userService: UserService;
  expenseService: ExpenseService;
  categoryService?: CategoryService;
  budgetService?: BudgetService;
  sttService?: SpeechToTextService;
  apiSecret?: string;
}

export function createBot(deps: CreateBotDependencies): Bot<BotContext> {
  const { token, userService, expenseService, categoryService, budgetService, sttService, apiSecret } = deps;
  const bot = new Bot<BotContext>(token);

  // Middleware para identificar o registrar al usuario
  bot.use(createUserMiddleware(userService));

  // Registrar comandos (/start, /list, /total, /budget, /categories, /token)
  registerCommands(bot, {
    expenseService,
    categoryService,
    budgetService,
    apiSecret,
  });

  // Registrar handler para texto en lenguaje natural
  registerMessageHandler(bot, expenseService);

  // Registrar handler para notas de voz si STT está disponible
  if (sttService) {
    registerVoiceHandler(bot, expenseService, sttService, token);
  }

  // Manejo de errores no capturados en el ciclo de vida del bot
  bot.catch((err) => {
    logger.error('Error no capturado en Grammy:', {
      ctx: err.ctx.update.update_id,
      error: err.error,
    });
  });

  return bot;
}
