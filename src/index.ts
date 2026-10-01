import { config } from './shared/config.js';
import { logger } from './shared/logger.js';
import { prisma } from './db/prisma.js';
import { UserRepository } from './db/repositories/user.repo.js';
import { ExpenseRepository } from './db/repositories/expense.repo.js';
import { UserService } from './users/user.service.js';
import { ExpenseService } from './expenses/expense.service.js';
import { OpenRouterProvider } from './ai/providers/openrouter.provider.js';
import { ExpenseParser } from './ai/expense-parser.js';
import { createBot } from './bot/index.js';

async function bootstrap() {
  logger.info('Iniciando Bot de Control de Gastos...');

  // 1. Instanciar repositorios
  const userRepo = new UserRepository();
  const expenseRepo = new ExpenseRepository();

  // 2. Instanciar proveedor de IA según configuración
  // (Abstraído para facilitar el intercambio de proveedor en el futuro)
  const aiProvider = new OpenRouterProvider({
    apiKey: config.OPENROUTER_API_KEY,
    model: config.OPENROUTER_MODEL,
    siteName: 'Bot Gastos Personales',
  });

  logger.info(`Proveedor de IA configurado: ${aiProvider.name} (modelo: ${config.OPENROUTER_MODEL})`);

  // 3. Instanciar parser y servicios de dominio
  const expenseParser = new ExpenseParser(aiProvider);
  const userService = new UserService(userRepo);
  const expenseService = new ExpenseService(expenseRepo, expenseParser);

  // 4. Crear bot de Telegram
  const bot = createBot({
    token: config.TELEGRAM_BOT_TOKEN,
    userService,
    expenseService,
  });

  // 5. Manejar terminación limpia (Graceful Shutdown)
  const shutdown = async (signal: string) => {
    logger.info(`Señal ${signal} recibida. Apagando servicios...`);
    try {
      await bot.stop();
      await prisma.$disconnect();
      logger.info('Desconexión completada con éxito.');
      process.exit(0);
    } catch (error) {
      logger.error('Error durante el apagado:', error);
      process.exit(1);
    }
  };

  process.once('SIGINT', () => shutdown('SIGINT'));
  process.once('SIGTERM', () => shutdown('SIGTERM'));

  // 6. Iniciar bot (long polling)
  logger.info('Iniciando long polling con Telegram...');
  await bot.start({
    onStart: (botInfo) => {
      logger.info(`✅ Bot iniciado correctamente como @${botInfo.username}`);
    },
  });
}

bootstrap().catch((error) => {
  logger.error('Error fatal al iniciar la aplicación:', error);
  process.exit(1);
});
