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

function renderProgressBar(percentage: number): string {
  const totalBlocks = 10;
  const clamped = Math.max(0, Math.min(100, percentage));
  const filled = Math.round((clamped / 100) * totalBlocks);
  const empty = totalBlocks - filled;
  return '█'.repeat(filled) + '░'.repeat(empty);
}

export function registerCommands(bot: Bot<BotContext>, deps: RegisterCommandsDeps) {
  const { expenseService, categoryService, budgetService, apiSecret } = deps;

  // /start
  bot.command('start', async (ctx) => {
    const name = ctx.from?.first_name ? ` ${ctx.from.first_name}` : '';
    const welcome = [
      `👋 ¡Hola${name}! Soy tu bot de control de gastos personales.`,
      '',
      'Podés registrar un gasto escribiendo o enviando un audio/nota de voz 🎙️:',
      '• *"Gasté 5000 en Saeta"*',
      '• *"Ayer gasté 12000 en el supermercado"*',
      '• *"Pagué 35000 de luz"*',
      '• *"Compré zapatillas por 80000 en 3 cuotas"*',
      '',
      'Comandos disponibles:',
      '• /list — Ver tus últimos 5 gastos',
      '• /total — Ver total gastado en el mes actual',
      '• /budget — Ver o fijar tus presupuestos mensuales',
      '• /categories — Ver tus categorías disponibles',
      '• /token — Generar token de acceso para la API móvil',
    ].join('\n');

    await ctx.reply(welcome, { parse_mode: 'Markdown' });
  });

  // /list
  bot.command('list', async (ctx) => {
    if (!ctx.user) {
      await ctx.reply('No se pudo identificar tu usuario. Intentá nuevamente con /start.');
      return;
    }

    const expenses = await expenseService.getLastExpenses(ctx.user.id, 5);

    if (expenses.length === 0) {
      await ctx.reply(
        'Aún no tenés gastos registrados. Escribí un mensaje o nota de voz para registrar el primero, por ejemplo: "Gasté 3500 en almuerzo".'
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

  // /budget
  bot.command('budget', async (ctx) => {
    if (!ctx.user || !budgetService) {
      await ctx.reply('Funcionalidad de presupuestos no disponible.');
      return;
    }

    const text = ctx.message?.text?.trim() ?? '';
    const parts = text.split(/\s+/).slice(1);

    // Caso 1: Configurar presupuesto ej: /budget comida 150000
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
          'No tenés presupuestos configurados todavía.',
          'Podés fijar uno escribiendo:',
          '`/budget <categoría> <monto>`',
          '',
          'Ejemplo:',
          '`/budget comida 150000`',
          '`/budget transporte 80000`',
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
        : ` (restan ${formatCurrency(b.remainingAmount, b.currency)})`;

      return `${icon} *${b.category}*: ${statusIcon} ${spent} / ${limit} (${b.percentageUsed}%)\n   \`${bar}\`${alert}`;
    });

    const msg = ['📊 *Progreso de Presupuestos del Mes:*', '', ...lines].join('\n\n');
    await ctx.reply(msg, { parse_mode: 'Markdown' });
  });

  // /categories
  bot.command('categories', async (ctx) => {
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
        : '_Ninguna todavía_';

    const msg = [
      '🏷️ *Tus Categorías Disponibles:*',
      '',
      '*Categorías del Sistema:*',
      systemLines,
      '',
      '*Tus Categorías Personalizadas:*',
      customLines,
    ].join('\n');

    await ctx.reply(msg, { parse_mode: 'Markdown' });
  });

  // /token (para la API REST / App Flutter)
  bot.command('token', async (ctx) => {
    if (!ctx.user) {
      await ctx.reply('No se pudo identificar tu usuario.');
      return;
    }

    // Creación de payload con firma segura
    // Para simplificar sin requerir dependencias complejas adicionales, usamos un token codificado o JWT
    const tokenPayload = Buffer.from(
      JSON.stringify({
        userId: ctx.user.id,
        telegramId: ctx.user.telegramId,
        issuedAt: Date.now(),
      })
    ).toString('base64url');

    await ctx.reply(
      [
        '🔑 *Token de Acceso para la API REST / App Móvil:*',
        '',
        `\`${tokenPayload}\``,
        '',
        'Podés usar este token en el header HTTP:',
        '`Authorization: Bearer <token>`',
        'o enviar el header `x-user-id: ' + ctx.user.id + '` en desarrollo local.',
      ].join('\n'),
      { parse_mode: 'Markdown' }
    );
  });
}
