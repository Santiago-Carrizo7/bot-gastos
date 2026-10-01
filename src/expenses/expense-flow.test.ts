import assert from 'node:assert/strict';
import { EXPENSE_CATEGORIES } from './expense.types.js';
import { ParsedExpenseSchema } from './expense.schema.js';
import { ExpenseParser } from '../ai/expense-parser.js';
import { IAIProvider, CompletePromptParams } from '../ai/providers/base.js';
import { formatCurrency, formatDate } from '../bot/formatters.js';

// Mock Provider para pruebas unitarias sin llamadas de red
class MockAIProvider implements IAIProvider {
  readonly name = 'MockAIProvider';
  constructor(private readonly mockOutput: string) {}

  async completePrompt(_params: CompletePromptParams): Promise<string> {
    return this.mockOutput;
  }
}

async function runTests() {
  console.log('🧪 Ejecutando pruebas unitarias de validación y parsing...');

  // 1. Probar categorías controladas
  assert.ok(EXPENSE_CATEGORIES.includes('transporte'));
  assert.ok(EXPENSE_CATEGORIES.includes('comida'));
  assert.ok(EXPENSE_CATEGORIES.includes('otros'));

  // 2. Probar esquema Zod con categoría válida
  const validParsed = ParsedExpenseSchema.parse({
    amount: 5000,
    description: 'Saeta',
    category: 'transporte',
    date: '2026-09-30',
    installments: 1,
    currency: 'ARS',
  });
  assert.equal(validParsed.amount, 5000);
  assert.equal(validParsed.category, 'transporte');

  // 3. Probar que una categoría no permitida falla la validación
  const invalidCategoryResult = ParsedExpenseSchema.safeParse({
    amount: 5000,
    description: 'Saeta',
    category: 'categoria_inventada',
    date: '2026-09-30',
  });
  assert.equal(invalidCategoryResult.success, false, 'Una categoría no controlada debe ser rechazada');

  // 4. Probar ExpenseParser con JSON envuelto en Markdown
  const markdownWrapped =
    '```json\n{"amount": 12000, "description": "Supermercado", "category": "comida", "date": "2026-09-29", "installments": 1, "currency": "ARS"}\n```';
  const parserWithMarkdown = new ExpenseParser(new MockAIProvider(markdownWrapped));
  const parsedFromMd = await parserWithMarkdown.parse('Ayer gasté 12000 en el supermercado');
  assert.equal(parsedFromMd.amount, 12000);
  assert.equal(parsedFromMd.category, 'comida');

  // 5. Probar cuotas
  const installmentsJson =
    '{"amount": 80000, "description": "Zapatillas", "category": "ropa", "date": "2026-10-01", "installments": 3, "currency": "ARS"}';
  const parserWithInstallments = new ExpenseParser(new MockAIProvider(installmentsJson));
  const parsedInstallments = await parserWithInstallments.parse('Compré zapatillas por 80000 en 3 cuotas');
  assert.equal(parsedInstallments.installments, 3);
  assert.equal(parsedInstallments.category, 'ropa');

  // 6. Probar formateadores de UI
  const formattedArs = formatCurrency(5000, 'ARS');
  assert.ok(formattedArs.includes('5.000'), `Esperado $ 5.000, obtenido: ${formattedArs}`);

  const formattedDate = formatDate(new Date('2026-09-30T12:00:00Z'));
  assert.equal(formattedDate, '30/09/2026');

  console.log('✅ Todas las pruebas unitarias pasaron satisfactoriamente!');
}

runTests().catch((err) => {
  console.error('❌ Error en pruebas:', err);
  process.exit(1);
});
