import { Server } from 'node:http';
import { config } from './shared/config.js';
import { logger } from './shared/logger.js';
import { prisma } from './db/prisma.js';
import { UserRepository } from './db/repositories/user.repo.js';
import { ExpenseRepository } from './db/repositories/expense.repo.js';
import { CategoryRepository } from './db/repositories/category.repo.js';
import { BudgetRepository } from './db/repositories/budget.repo.js';
import { UserService } from './users/user.service.js';
import { ExpenseService } from './expenses/expense.service.js';
import { CategoryService } from './categories/category.service.js';
import { BudgetService } from './budgets/budget.service.js';
import { OpenRouterProvider } from './ai/providers/openrouter.provider.js';
import { OpenAICompatibleSTTProvider } from './ai/stt/openai-compatible-stt.provider.js';
import { SpeechToTextService } from './ai/stt/stt.service.js';
import { ExpenseParser } from './ai/expense-parser.js';
import { createBot } from './bot/index.js';
import { createExpressApp } from './api/server.js';

async function bootstrap() {
  logger.info('Iniciando Bot de Control de Gastos + Servidor API...');

  // 1. Instanciar repositorios
  const userRepo = new UserRepository();
  const expenseRepo = new ExpenseRepository();
  const categoryRepo = new CategoryRepository();
  const budgetRepo = new BudgetRepository();

  // 2. Instanciar servicios de dominio
  const categoryService = new CategoryService(categoryRepo);
  // Asegurar categorías básicas del sistema en la base de datos
  await categoryService.init();

  const userService = new UserService(userRepo);
  const budgetService = new BudgetService(budgetRepo, expenseRepo, categoryService);

  // 3. Instanciar proveedor de IA de texto
  const aiProvider = new OpenRouterProvider({
    apiKey: config.OPENROUTER_API_KEY,
    model: config.OPENROUTER_MODEL,
    siteName: 'Bot Gastos Personales',
  });
  logger.info(`Proveedor de IA configurado: ${aiProvider.name} (modelo: ${config.OPENROUTER_MODEL})`);

  // 4. Instanciar proveedor de Speech-to-Text (Audio)
  let sttService: SpeechToTextService;
  if (config.STT_PROVIDER !== 'disabled' && config.STT_API_KEY) {
    const sttProvider = new OpenAICompatibleSTTProvider({
      apiKey: config.STT_API_KEY,
      baseUrl: config.STT_BASE_URL,
      model: config.STT_MODEL,
      providerName: config.STT_PROVIDER === 'groq' ? 'Groq Whisper' : 'OpenAI Whisper',
    });
    sttService = new SpeechToTextService(sttProvider);
    logger.info(`Proveedor STT configurado: ${sttProvider.name} (modelo: ${config.STT_MODEL})`);
  } else {
    sttService = new SpeechToTextService(undefined);
    logger.info('Proveedor STT deshabilitado (no se configuró STT_API_KEY).');
  }

  // 5. Instanciar parser y ExpenseService con categorías integradas
  const expenseParser = new ExpenseParser(aiProvider);
  const expenseService = new ExpenseService(expenseRepo, expenseParser, categoryService);

  // 6. Iniciar servidor HTTP / API REST
  const app = createExpressApp({
    expenseService,
    categoryService,
    budgetService,
    userService,
    apiSecret: config.API_SECRET,
  });

  let httpServer: Server | undefined;
  await new Promise<void>((resolve) => {
    httpServer = app.listen(config.PORT, () => {
      logger.info(`🚀 Servidor HTTP escuchando en http://localhost:${config.PORT} (Health check: /health)`);
      resolve();
    });
  });

  // 7. Crear bot de Telegram
  const bot = createBot({
    token: config.TELEGRAM_BOT_TOKEN,
    userService,
    expenseService,
    categoryService,
    budgetService,
    sttService,
    apiSecret: config.API_SECRET,
  });

  // 8. Manejar terminación limpia (Graceful Shutdown)
  const shutdown = async (signal: string) => {
    logger.info(`Señal ${signal} recibida. Apagando servicios...`);
    try {
      if (httpServer) {
        await new Promise<void>((res) => httpServer?.close(() => res()));
      }
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

  // 9. Iniciar bot (long polling)
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
