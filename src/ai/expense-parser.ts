import { IAIProvider } from './providers/base.js';
import { buildExpenseParserSystemPrompt } from './prompts/expense-parser.prompt.js';
import { ParsedExpense, ParsedExpenseSchema } from '../expenses/expense.schema.js';
import { ExpenseParsingError } from '../shared/errors.js';
import { logger } from '../shared/logger.js';

export class ExpenseParser {
  constructor(private readonly aiProvider: IAIProvider) {}

  async parse(text: string, referenceDate: Date = new Date()): Promise<ParsedExpense> {
    const dateStr = referenceDate.toISOString().slice(0, 10);
    const systemPrompt = buildExpenseParserSystemPrompt(dateStr);

    let rawResponse: string;
    try {
      rawResponse = await this.aiProvider.completePrompt({
        systemPrompt,
        userPrompt: text,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      throw new ExpenseParsingError(`No se pudo procesar el mensaje con el modelo de IA: ${message}`);
    }

    const cleanJson = this.extractJson(rawResponse);

    let parsedObject: unknown;
    try {
      parsedObject = JSON.parse(cleanJson);
    } catch {
      logger.warn('Fallo al parsear JSON devuelto por IA:', rawResponse);
      throw new ExpenseParsingError(
        'El modelo de IA no devolvió un formato válido. Por favor, intentá reformular tu mensaje.',
        rawResponse
      );
    }

    const validation = ParsedExpenseSchema.safeParse(parsedObject);
    if (!validation.success) {
      const issues = validation.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join(', ');
      logger.warn('El JSON no cumple el esquema esperado:', { issues, rawResponse });
      throw new ExpenseParsingError(
        `Los datos del gasto no son válidos (${issues}). Por favor, reformulá tu mensaje indicando monto y concepto.`,
        rawResponse
      );
    }

    return validation.data;
  }

  private extractJson(rawText: string): string {
    let text = rawText.trim();

    // Elimina bloques de código markdown tipo ```json ... ``` o ``` ... ```
    if (text.startsWith('```')) {
      text = text.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
    }

    // Si aún tiene texto alrededor, busca el primer '{' y el último '}'
    const firstBrace = text.indexOf('{');
    const lastBrace = text.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      text = text.slice(firstBrace, lastBrace + 1);
    }

    return text.trim();
  }
}
