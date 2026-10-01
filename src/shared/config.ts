import 'dotenv/config';
import { z } from 'zod';
import { ConfigError } from './errors.js';

const configSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  TELEGRAM_BOT_TOKEN: z.string().min(1, 'TELEGRAM_BOT_TOKEN es obligatorio'),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL es obligatorio'),
  AI_PROVIDER: z.enum(['openrouter']).default('openrouter'),
  OPENROUTER_API_KEY: z.string().min(1, 'OPENROUTER_API_KEY es obligatorio'),
  OPENROUTER_MODEL: z.string().default('google/gemini-2.0-flash-001'),
});

export type AppConfig = z.infer<typeof configSchema>;

function loadConfig(): AppConfig {
  const result = configSchema.safeParse(process.env);

  if (!result.success) {
    const issues = result.error.issues.map((i) => `  - ${i.path.join('.')}: ${i.message}`).join('\n');
    throw new ConfigError(`Error en variables de entorno:\n${issues}`);
  }

  return result.data;
}

export const config = loadConfig();
