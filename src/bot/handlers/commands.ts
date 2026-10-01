import { Bot } from 'grammy';
import { BotContext } from '../bot.context.js';
import { ExpenseService } from '../../expenses/expense.service.js';
import { formatCurrency, formatDate, CATEGORY_ICONS } from '../formatters.js';
import { ExpenseCategory } from '../../expenses/expense.types.js';

export function registerCommands(bot: Bot<BotContext>, expenseService: ExpenseService) {
  // /start
  bot.command('start', async (ctx) => {
    const name = ctx.from?.first_name ? ` ${ctx.from.first_name}` : '';
    const welcome = [
      `👋 ¡Hola${name}! Soy tu bot de control de gastos personales.`,
      '',
      'Podés registrar un gasto simplemente escribiéndome en lenguaje natural:',
      '• *"Gasté 5000 en Saeta"*',
      '• *"Ayer gasté 12000 en el supermercado"*',
      '• *"Pagué 35000 de luz"*',
      '• *"Compré zapatillas por 80000 en 3 cuotas"*',
      '',
      'Comandos disponibles:',
      '• /list - Ver tus últimos 5 gastos',
      '• /total - Ver el total gastado en el mes actual',
    ].join('\n');

    await ctx.reply(welcome, { parse_mode: 'Markdown' });
  });

  // /list
  bot.command('list', async (ctx) => {
    if (!ctx.user) {
      await ctx.reply('No se pudo identificar tu usuario. Intentá nuevamente.');
      return;
    }

    const expenses = await expenseService.getLastExpenses(ctx.user.id, 5);

    if (expenses.length === 0) {
      await ctx.reply(
        'Aún no tenés gastos registrados. Escribí un mensaje para registrar el primero, por ejemplo: "Gasté 3500 en almuerzo".'
      );
      return;
    }

    const lines = expenses.map((exp, index) => {
      const icon = CATEGORY_ICONS[exp.category as ExpenseCategory] ?? '📦';
      const formattedAmount = formatCurrency(Number(exp.amount), exp.currency);
      const dateStr = formatDate(exp.date);
      const installmentsStr = exp.installments > 1 ? ` (${exp.installments} cuotas)` : '';
      return `${index + 1}. ${icon} *${formattedAmount}* — ${exp.description} (${exp.category})${installmentsStr} — _${dateStr}_`;
    });

    const message = [`📋 *Tus últimos ${expenses.length} gastos:*`, '', ...lines].join('\n');

    await ctx.reply(message, { parse_mode: 'Markdown' });
  });

  // /total
  bot.command('total', async (ctx) => {
    if (!ctx.user) {
      await ctx.reply('No se pudo identificar tu usuario. Intentá nuevamente.');
      return;
    }

    const monthlyTotal = await expenseService.getCurrentMonthTotal(ctx.user.id);

    if (monthlyTotal.count === 0) {
      await ctx.reply(`📊 En *${monthlyTotal.monthName} ${monthlyTotal.year}* todavía no registraste gastos.`, {
        parse_mode: 'Markdown',
      });
      return;
    }

    const formattedTotal = formatCurrency(monthlyTotal.total);
    const countText = monthlyTotal.count === 1 ? '1 gasto registrado' : `${monthlyTotal.count} gastos registrados`;

    const message = [
      `📊 *Total de ${monthlyTotal.monthName} ${monthlyTotal.year}:*`,
      '',
      `💰 *${formattedTotal}*`,
      `📑 ${countText}`,
    ].join('\n');

    await ctx.reply(message, { parse_mode: 'Markdown' });
  });
}
