import { Bot } from 'grammy';
import { BotContext } from '../bot.context.js';
import { ExpenseService } from '../../expenses/expense.service.js';
import { CategoryService } from '../../categories/category.service.js';
import { BudgetService } from '../../budgets/budget.service.js';
import { formatCurrency, formatDate, getCategoryIcon } from '../formatters.js';

export interface RegisterCommandsDeps {
  expenseService: ExpenseService;
  categoryService?: CategoryService;
  budgetService?: BudgetService;
  apiSecret?: string;
}

/**
 * Comandos oficiales que se registran en el botón "Menú" nativo de Telegram
 */
export const BOT_MENU_COMMANDS = [
  { command: 'gastos', description: '📋 Ver tus últimos 5 gastos' },
  { command: 'total', description: '💰 Ver el total gastado en el mes' },
  { command: 'presupuesto', description: '📊 Ver o fijar presupuestos mensuales' },
  { command: 'categorias', description: '🏷️ Ver tus categorías disponibles' },
  { command: 'vincular', description: '📱 Vincular con la app del celular' },
  { command: 'ayuda', description: '❓ Ver guía rápida y comandos' },
];

function renderProgressBar(percentage: number): string {
  const totalBlocks = 10;
  const clamped = Math.max(0, Math.min(100, percentage));
  const filled = Math.round((clamped / 100) * totalBlocks);
  const empty = totalBlocks - filled;
  return '█'.repeat(filled) + '░'.repeat(empty);
}

export function buildHelpMessage(firstName?: string): string {
  const name = firstName ? ` ${firstName}` : '';
  return [
    `👋 ¡Hola${name}! Soy tu asistente de control de gastos.`,
    '',
    '📝 *¿Cómo registrar un gasto?*',
    'Simplemente escribime o mandame un *audio de voz* 🎙️ como si hablaras con una persona:',
    '• *"Gasté 5000 en Saeta"*',
    '• *"Ayer gasté 12000 en el supermercado"*',
    '• *"Pagué 35000 de luz"*',
    '• *"Compré zapatillas por 80000 en 3 cuotas"*',
    '',
    '📌 *Comandos disponibles (podés tocarlos):*',
    '• /gastos — Ver tus últimos 5 gastos',
    '• /total — Ver el total acumulado del mes',
    '• /presupuesto — Ver o fijar presupuestos del mes',
    '• /categorias — Ver las categorías de gastos',
    '• /vincular — Obtener código para la app móvil',
    '• /ayuda — Mostrar este menú de ayuda',
  ].join('\n');
}

export function registerCommands(bot: Bot<BotContext>, deps: RegisterCommandsDeps) {
  const { expenseService, categoryService, budgetService } = deps;

  // /start, /ayuda, /inicio
  bot.command(['start', 'ayuda', 'inicio', 'help'], async (ctx) => {
    const welcome = buildHelpMessage(ctx.from?.first_name);
    await ctx.reply(welcome, { parse_mode: 'Markdown' });
  });

  // /gastos, /listargastos, /list
  bot.command(['gastos', 'listargastos', 'ultimos', 'list'], async (ctx) => {
    if (!ctx.user) {
      await ctx.reply('No se pudo identificar tu usuario. Intentá nuevamente con /ayuda.');
      return;
    }

    const expenses = await expenseService.getLastExpenses(ctx.user.id, 5);

    if (expenses.length === 0) {
      await ctx.reply(
        'Aún no tenés gastos registrados. Escribí un mensaje o mandá un audio para registrar el primero, por ejemplo: *"Gasté 3500 en almuerzo"*.',
        { parse_mode: 'Markdown' }
      );
      return;
    }

    const lines = expenses.map((exp, index) => {
      const icon = getCategoryIcon(exp.category);
      const formattedAmount = formatCurrency(Number(exp.amount), exp.currency);
      const dateStr = formatDate(exp.date);
      const installmentsStr = exp.installments > 1 ? ` (${exp.installments} cuotas)` : '';
      return `${index + 1}. ${icon} *${formattedAmount}* — ${exp.description} (${exp.category})${installmentsStr} — _${dateStr}_`;
    });

    const message = [`📋 *Tus últimos ${expenses.length} gastos:*`, '', ...lines].join('\n');

    await ctx.reply(message, { parse_mode: 'Markdown' });
  });

  // /total, /totalgastado
  bot.command(['total', 'totalgastado', 'resumen'], async (ctx) => {
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

  // /presupuesto, /fijarpresupuesto, /budget
  bot.command(['presupuesto', 'fijarpresupuesto', 'presupuestos', 'budget'], async (ctx) => {
    if (!ctx.user || !budgetService) {
      await ctx.reply('Funcionalidad de presupuestos no disponible.');
      return;
    }

    const text = ctx.message?.text?.trim() ?? '';
    const parts = text.split(/\s+/).slice(1);

    // Caso 1: Configurar presupuesto ej: /presupuesto comida 150000
    if (parts.length >= 2) {
      const categoryName = parts[0].toLowerCase();
      const amount = parseFloat(parts[1].replace(/\./g, '').replace(',', '.'));

      if (isNaN(amount) || amount <= 0) {
        await ctx.reply('⚠️ El monto del presupuesto debe ser un número positivo mayor a 0.');
        return;
      }

      try {
        await budgetService.setBudget(ctx.user.id, categoryName, amount);
        const icon = getCategoryIcon(categoryName);
        await ctx.reply(
          `✅ Presupuesto mensual para *${categoryName}* ${icon} fijado en *${formatCurrency(amount)}*`,
          { parse_mode: 'Markdown' }
        );
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        await ctx.reply(`⚠️ No se pudo fijar el presupuesto: ${msg}`);
      }
      return;
    }

    // Caso 2: Consultar presupuestos del mes actual
    const budgets = await budgetService.getBudgetsWithProgress(ctx.user.id);

    if (budgets.length === 0) {
      await ctx.reply(
        [
          '📊 *Presupuestos Mensuales*',
          '',
          'Todavía no configuraste ningún tope mensual.',
          'Para definir cuánto querés gastar por mes en una categoría, escribí:',
          '`/presupuesto <categoría> <monto>`',
          '',
          '*Ejemplos:*',
          '• `/presupuesto comida 150000`',
          '• `/presupuesto transporte 80000`',
        ].join('\n'),
        { parse_mode: 'Markdown' }
      );
      return;
    }

    const lines = budgets.map((b) => {
      const icon = getCategoryIcon(b.category);
      const spent = formatCurrency(b.spentAmount, b.currency);
      const limit = formatCurrency(b.budgetAmount, b.currency);
      const bar = renderProgressBar(b.percentageUsed);
      const statusIcon = b.isExceeded ? '⚠️' : b.percentageUsed >= 85 ? '🟡' : '🟢';

      const alert = b.isExceeded
        ? `\n   ❗ *Excedido por ${formatCurrency(Math.abs(b.remainingAmount), b.currency)}*`
        : ` (disponible: ${formatCurrency(b.remainingAmount, b.currency)})`;

      return `${icon} *${b.category}*: ${statusIcon} ${spent} / ${limit} (${b.percentageUsed}%)\n   \`${bar}\`${alert}`;
    });

    const msg = [
      '📊 *Progreso de tus Presupuestos del Mes:*',
      '',
      ...lines,
      '',
      '💡 _Para modificar o agregar otro usá: `/presupuesto <categoría> <monto>`_ ',
    ].join('\n');
    await ctx.reply(msg, { parse_mode: 'Markdown' });
  });

  // /categorias, /categories
  bot.command(['categorias', 'categories'], async (ctx) => {
    if (!ctx.user || !categoryService) {
      await ctx.reply('No se pudieron obtener las categorías.');
      return;
    }

    const categories = await categoryService.getUserCategories(ctx.user.id);
    const system = categories.filter((c) => c.isSystem);
    const custom = categories.filter((c) => !c.isSystem);

    const systemLines = system.map((c) => `• ${c.icon ?? '🏷️'} ${c.name}`).join('\n');
    const customLines =
      custom.length > 0
        ? custom.map((c) => `• ${c.icon ?? '🏷️'} *${c.name}* (personalizada)`).join('\n')
        : '_Ninguna creada todavía_';

    const msg = [
      '🏷️ *Categorías Disponibles:*',
      '',
      '*Categorías Generales:*',
      systemLines,
      '',
      '*Tus Categorías Personalizadas:*',
      customLines,
    ].join('\n');

    await ctx.reply(msg, { parse_mode: 'Markdown' });
  });

  // /vincular, /token
  bot.command(['vincular', 'token'], async (ctx) => {
    if (!ctx.user) {
      await ctx.reply('No se pudo identificar tu usuario.');
      return;
    }

    const tokenPayload = Buffer.from(
      JSON.stringify({
        userId: ctx.user.id,
        telegramId: ctx.user.telegramId,
        issuedAt: Date.now(),
      })
    ).toString('base64url');

    await ctx.reply(
      [
        '📱 *Vincular con la Aplicación Móvil*',
        '',
        'Cuando abras la aplicación de gastos en tu celular por primera vez, te va a pedir un *código de vinculación* para conectar tu cuenta.',
        '',
        '👇 *Tocá el siguiente código para copiarlo y pegalo en la app:*',
        '',
        `\`${tokenPayload}\``,
        '',
        '🔒 _Este código es personal. No lo compartas con otras personas._',
      ].join('\n'),
      { parse_mode: 'Markdown' }
    );
  });
}
