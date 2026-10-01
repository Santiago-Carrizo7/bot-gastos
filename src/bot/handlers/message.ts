import { Bot } from 'grammy';
import { BotContext } from '../bot.context.js';
import { ExpenseService } from '../../expenses/expense.service.js';
import { ExpenseParsingError } from '../../shared/errors.js';
import { logger } from '../../shared/logger.js';
import { formatCurrency, formatDate, CATEGORY_ICONS } from '../formatters.js';
import { ExpenseCategory } from '../../expenses/expense.types.js';

export function registerMessageHandler(bot: Bot<BotContext>, expenseService: ExpenseService) {
  bot.on('message:text', async (ctx) => {
    const text = ctx.message.text.trim();

    // Si comienza con "/", es un comando ya manejado o desconocido
    if (text.startsWith('/')) {
      return;
    }

    if (!ctx.user) {
      await ctx.reply('No se pudo identificar tu usuario. Por favor iniciá con /start');
      return;
    }

    try {
      // Envía acción de escribiendo para mejor UX
      await ctx.replyWithChatAction('typing');

      const expense = await expenseService.createFromText(ctx.user.id, text);

      const icon = CATEGORY_ICONS[expense.category as ExpenseCategory] ?? '📦';
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
          `🤔 No pude interpretar tu gasto.\n\nPor favor reformulalo de forma directa indicando el monto y el concepto, por ejemplo:\n• *"Gasté 5000 en Saeta"*\n• *"Ayer pagué 12000 en el super"*\n• *"Pagué 35000 de luz"*\n• *"Compré zapatillas por 80000 en 3 cuotas"*`,
          { parse_mode: 'Markdown' }
        );
        return;
      }

      logger.error('Error no controlado al procesar mensaje de gasto:', error);
      await ctx.reply('⚠️ Ocurrió un error inesperado al registrar el gasto. Por favor intentá nuevamente.');
    }
  });
}
