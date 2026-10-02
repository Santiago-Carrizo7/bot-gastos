import { Bot } from 'grammy';
import { BotContext } from '../bot.context.js';
import { ExpenseService } from '../../expenses/expense.service.js';
import { ExpenseParsingError } from '../../shared/errors.js';
import { logger } from '../../shared/logger.js';
import { formatCurrency, formatDate, getCategoryIcon } from '../formatters.js';
import { buildHelpMessage } from './commands.js';

const HELP_KEYWORDS = new Set(['ayuda', 'comandos', 'menu', 'menú', 'hola', 'opciones', '?']);

export function registerMessageHandler(bot: Bot<BotContext>, expenseService: ExpenseService) {
  bot.on('message:text', async (ctx) => {
    const text = ctx.message.text.trim();
    const lowerText = text.toLowerCase();

    // Si es un comando "/" no reconocido o una palabra clave de ayuda, mostramos el menú de comandos
    if (text.startsWith('/') || HELP_KEYWORDS.has(lowerText)) {
      const helpMsg = buildHelpMessage(ctx.from?.first_name);
      await ctx.reply(helpMsg, { parse_mode: 'Markdown' });
      return;
    }

    if (!ctx.user) {
      await ctx.reply('No se pudo identificar tu usuario. Por favor tocá /ayuda');
      return;
    }

    try {
      // Envía acción de escribiendo para mejor UX
      await ctx.replyWithChatAction('typing');

      const expense = await expenseService.createFromText(ctx.user.id, text);

      const icon = getCategoryIcon(expense.category);
      const formattedAmount = formatCurrency(Number(expense.amount), expense.currency);
      const formattedDate = formatDate(expense.date);
      const installmentsStr = expense.installments > 1 ? `\n💳 Cuotas: *${expense.installments}*` : '';

      const response = [
        `✅ Registré *${formattedAmount}* en *${expense.category}* ${icon}`,
        `📝 Detalle: *${expense.description}*`,
        `📅 Fecha: *${formattedDate}*${installmentsStr}`,
      ].join('\n');

      await ctx.reply(response, { parse_mode: 'Markdown' });
    } catch (error) {
      if (error instanceof ExpenseParsingError) {
        logger.warn('Error de interpretación de mensaje:', { error: error.message, text });
        await ctx.reply(
          [
            '🤔 No pude entender ese mensaje como un gasto.',
            '',
            'Para anotar un gasto, decime el *monto* y en qué lo gastaste, por ejemplo:',
            '• *"Gasté 5000 en Saeta"*',
            '• *"Ayer pagué 12000 en el super"*',
            '• *"Compré zapatillas por 80000 en 3 cuotas"*',
            '',
            '📌 *¿Buscabas los comandos?*',
            '• /gastos — Últimos 5 gastos',
            '• /total — Total gastado en el mes',
            '• /presupuesto — Ver o fijar presupuestos',
            '• /categorias — Ver categorías',
            '• /vincular — Código para la app móvil',
          ].join('\n'),
          { parse_mode: 'Markdown' }
        );
        return;
      }

      logger.error('Error no controlado al procesar mensaje de gasto:', error);
      await ctx.reply('⚠️ Ocurrió un error inesperado al registrar el gasto. Por favor intentá nuevamente.');
    }
  });
}
