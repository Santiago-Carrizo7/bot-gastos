import assert from 'node:assert/strict';
import { EXPENSE_CATEGORIES, SYSTEM_CATEGORIES } from './expense.types.js';
import { ParsedExpenseSchema } from './expense.schema.js';
import { ExpenseParser } from '../ai/expense-parser.js';
import { IAIProvider, CompletePromptParams } from '../ai/providers/base.js';
import { ISpeechToTextProvider, TranscribeAudioParams } from '../ai/stt/base.js';
import { SpeechToTextService } from '../ai/stt/stt.service.js';
import { formatCurrency, formatDate, getCategoryIcon } from '../bot/formatters.js';

// Mock Provider para pruebas unitarias sin llamadas de red
class MockAIProvider implements IAIProvider {
  readonly name = 'MockAIProvider';
  constructor(private readonly mockOutput: string) {}

  async completePrompt(_params: CompletePromptParams): Promise<string> {
    return this.mockOutput;
  }
}

class MockSTTProvider implements ISpeechToTextProvider {
  readonly name = 'MockSTTProvider';
  async transcribe(_params: TranscribeAudioParams): Promise<string> {
    return 'Gasté 3500 en Saeta ayer';
  }
}

async function runTests() {
  console.log('🧪 Ejecutando pruebas unitarias de validación, parsing y STT...');

  // 1. Probar categorías básicas del sistema
  assert.ok(SYSTEM_CATEGORIES.some((c) => c.name === 'transporte'));
  assert.ok(SYSTEM_CATEGORIES.some((c) => c.name === 'comida'));
  assert.ok(SYSTEM_CATEGORIES.some((c) => c.name === 'otros'));
  assert.ok(EXPENSE_CATEGORIES.includes('transporte'));

  // 2. Probar esquema Zod con campos válidos
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

  // 3. Probar que monto negativo falla validación Zod
  const negativeAmount = ParsedExpenseSchema.safeParse({
    amount: -500,
    description: 'Saeta',
    category: 'transporte',
    date: '2026-09-30',
  });
  assert.equal(negativeAmount.success, false, 'Un monto negativo debe ser rechazado');

  // 4. Probar que si la IA intenta inventar una categoría, ExpenseParser aplica fallback a "otros"
  const inventedCategoryJson =
    '{"amount": 5000, "description": "Gimnasio", "category": "categoria_inventada_por_ia", "date": "2026-09-30", "installments": 1, "currency": "ARS"}';
  const parserWithInventedCategory = new ExpenseParser(new MockAIProvider(inventedCategoryJson));
  const parsedWithFallback = await parserWithInventedCategory.parse(
    'Pagué el gym',
    ['deportes', 'comida', 'otros']
  );
  assert.equal(
    parsedWithFallback.category,
    'otros',
    'Una categoría fuera del whitelist de categorías permitidas debe fallbackear a "otros"'
  );

  // 5. Probar que una categoría personalizada del usuario es aceptada si está en su whitelist
  const customCategoryJson =
    '{"amount": 15000, "description": "Crossfit", "category": "crossfit", "date": "2026-09-30", "installments": 1, "currency": "ARS"}';
  const parserWithCustomCategory = new ExpenseParser(new MockAIProvider(customCategoryJson));
  const parsedCustom = await parserWithCustomCategory.parse(
    'Pagué cuota de crossfit',
    ['crossfit', 'comida', 'otros']
  );
  assert.equal(parsedCustom.category, 'crossfit');

  // 6. Probar ExpenseParser con JSON envuelto en Markdown
  const markdownWrapped =
    '```json\n{"amount": 12000, "description": "Supermercado", "category": "comida", "date": "2026-09-29", "installments": 1, "currency": "ARS"}\n```';
  const parserWithMarkdown = new ExpenseParser(new MockAIProvider(markdownWrapped));
  const parsedFromMd = await parserWithMarkdown.parse('Ayer gasté 12000 en el supermercado');
  assert.equal(parsedFromMd.amount, 12000);
  assert.equal(parsedFromMd.category, 'comida');

  // 7. Probar cuotas
  const installmentsJson =
    '{"amount": 80000, "description": "Zapatillas", "category": "ropa", "date": "2026-10-01", "installments": 3, "currency": "ARS"}';
  const parserWithInstallments = new ExpenseParser(new MockAIProvider(installmentsJson));
  const parsedInstallments = await parserWithInstallments.parse('Compré zapatillas por 80000 en 3 cuotas');
  assert.equal(parsedInstallments.installments, 3);
  assert.equal(parsedInstallments.category, 'ropa');

  // 8. Probar servicio de Speech-to-Text
  const sttService = new SpeechToTextService(new MockSTTProvider());
  assert.equal(sttService.isConfigured(), true);
  const audioTranscript = await sttService.transcribe(Buffer.from('dummy-audio-bytes'));
  assert.equal(audioTranscript, 'Gasté 3500 en Saeta ayer');

  // 9. Probar formateadores de UI
  const formattedArs = formatCurrency(5000, 'ARS');
  assert.ok(formattedArs.includes('5.000'), `Esperado $ 5.000, obtenido: ${formattedArs}`);

  const formattedDate = formatDate(new Date('2026-09-30T12:00:00Z'));
  assert.equal(formattedDate, '30/09/2026');

  const iconTransport = getCategoryIcon('transporte');
  assert.equal(iconTransport, '🚌');

  console.log('✅ Todas las pruebas unitarias pasaron satisfactoriamente!');
}

runTests().catch((err) => {
  console.error('❌ Error en pruebas:', err);
  process.exit(1);
});
