# Project Memory (Bot de Gastos)
> **Reglas de uso:** Memoria episódica entre sesiones. Mantener siempre por debajo de **50-60 líneas**. Resumir o eliminar lo que ya no aporte valor. Si algo se vuelve una regla permanente, moverlo a `AGENTS.md`. **NUNCA** guardar secretos, tokens ni datos sensibles.

## Estado Actual
- MVP completamente implementado, compilable (`pnpm build`) y verificado (`pnpm test`).
- Bot de Telegram (Grammy) con comandos `/start`, `/list` y `/total`, y handler de texto natural.
- Capa de IA con `IAIProvider` y `OpenRouterProvider` funcional con extracción JSON y validación Zod.
- PostgreSQL en Docker (`docker-compose.yml`) + Prisma con modelos `User`, `Expense` y migración inicial aplicada en SQL.
- Auto-registro de usuarios mediante middleware de Telegram por `telegramId`.

## Decisiones Técnicas Recientes
- **Categorías Cerradas:** Definidas en `EXPENSE_CATEGORIES`, sincronizadas entre Zod, Postgres Enum y prompt dinámico.
- **Abstracción IA:** `ExpenseParser` usa `IAIProvider`, permitiendo cambiar de OpenRouter a OpenAI/Gemini sin tocar lógica.
- **Normalización de Fechas:** Las fechas relativas extraídas se normalizan a mediodía UTC (`T12:00:00Z`) para evitar desfasajes horarios al persistir.
- **Telegram IDs:** Almacenados como `String` en Postgres para evitar overflow de enteros de 64 bits en JavaScript.

## Aprendizajes y Errores a Evitar (Gotchas)
- **Windows pnpm:** En PowerShell ejecutar `pnpm.cmd` si la política de scripts bloquea `pnpm.ps1`.
- **ESM NodeNext:** Imports relativos en TypeScript requieren extensión `.js` explícita (ej. `./expense.types.js`).
- **Prisma Migrations en Desarrollo:** `prisma migrate diff` genera SQL exacto sin necesidad de shadow database viva.
- **Sin Secretos:** No commitear `.env`; usar siempre `.env.example`.

## Próximos Pasos
- [ ] Procesamiento de audios y notas de voz con Speech-to-Text (Whisper / OpenAI / Groq).
- [ ] Categorías personalizadas por usuario.
- [ ] Presupuestos mensuales y alertas de consumo.
- [ ] Endpoints HTTP / REST para futura integración con app móvil Flutter.
