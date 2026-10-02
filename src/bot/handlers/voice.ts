import { Bot } from 'grammy';
import { BotContext } from '../bot.context.js';
import { ExpenseService } from '../../expenses/expense.service.js';
import { SpeechToTextService } from '../../ai/stt/stt.service.js';
import { ExpenseParsingError } from '../../shared/errors.js';
import { logger } from '../../shared/logger.js';
import { formatCurrency, formatDate, getCategoryIcon } from '../formatters.js';

export function registerVoiceHandler(
  bot: Bot<BotContext>,
  expenseService: ExpenseService,
  sttService: SpeechToTextService,
  botToken: string
) {
  bot.on(['message:voice', 'message:audio'], async (ctx) => {
    if (!ctx.user) {
      await ctx.reply('No se pudo identificar tu usuario. Por favor iniciá con /start');
      return;
    }

    if (!sttService.isConfigured()) {
      await ctx.reply(
        '🎙️ El procesamiento de notas de voz aún no está configurado en el servidor (falta STT_API_KEY).'
      );
      return;
    }

    const voiceOrAudio = ctx.message.voice ?? ctx.message.audio;
    if (!voiceOrAudio) {
      await ctx.reply('No se pudo procesar el archivo de audio.');
      return;
    }

    try {
      await ctx.replyWithChatAction('typing');

      // 1. Obtener ruta del archivo en servidores de Telegram
      const file = await ctx.getFile();
      if (!file.file_path) {
        await ctx.reply('No se pudo descargar la nota de voz desde Telegram.');
        return;
      }

      // 2. Descargar el buffer del audio
      const downloadUrl = `https://api.telegram.org/file/bot${botToken}/${file.file_path}`;
      const response = await fetch(downloadUrl);
      if (!response.ok) {
        throw new Error(`Fallo al descargar audio de Telegram: HTTP ${response.status}`);
      }

      const arrayBuffer = await response.arrayBuffer();
      const audioBuffer = Buffer.from(arrayBuffer);

      // 3. Transcribir audio mediante Speech-to-Text
      const transcript = await sttService.transcribe(audioBuffer, voiceOrAudio.mime_type ?? 'audio/ogg');
      logger.info(`Audio transcripto para usuario ${ctx.user.id}: "${transcript}"`);

      // 4. Crear gasto utilizando el mismo flujo de dominio
      const expense = await expenseService.createFromText(ctx.user.id, transcript);

      const icon = getCategoryIcon(expense.category);
      const formattedAmount = formatCurrency(Number(expense.amount), expense.currency);
      const formattedDate = formatDate(expense.date);
      const installmentsStr = expense.installments > 1 ? `\n💳 Cuotas: *${expense.installments}*` : '';

      const replyMessage = [
        `🎙️ *Audio detectado:* _"${transcript}"_`,
        '',
        `✅ Registré *${formattedAmount}* en *${expense.category}* ${icon}`,
        `📝 Detalle: *${expense.description}*`,
        `📅 Fecha: *${formattedDate}*${installmentsStr}`,
      ].join('\n');

      await ctx.reply(replyMessage, { parse_mode: 'Markdown' });
    } catch (error) {
      if (error instanceof ExpenseParsingError) {
        logger.warn('Error de interpretación tras transcripción de audio:', error.message);
        await ctx.reply(
          `🤔 Escuché el audio pero no pude interpretarlo como un gasto claro.\n\nIntentá decir claramente el monto y el concepto, por ejemplo: *"Gasté 5000 en Saeta"* o *"Pagué 12000 en el supermercado"*`,
          { parse_mode: 'Markdown' }
        );
        return;
      }

      const msg = error instanceof Error ? error.message : String(error);
      logger.error('Error al procesar nota de voz:', error);
      await ctx.reply(`⚠️ No se pudo procesar la nota de voz (${msg}). Probá enviando un mensaje de texto.`);
    }
  });
}
