# Project Memory (Bot de Gastos)
> **Reglas de uso:** Memoria episódica entre sesiones. Mantener siempre por debajo de **50-60 líneas**. Resumir o eliminar lo que ya no aporte valor. Si algo se vuelve una regla permanente, moverlo a `AGENTS.md`. **NUNCA** guardar secretos, tokens ni datos sensibles.

## Estado Actual
- Bot de Telegram en español: texto, voz (STT), menú nativo (`setMyCommands`) y comandos `/gastos`, `/total`, `/presupuesto`, `/categorias`, `/vincular` y `/ayuda`.
- STT desacoplado con `ISpeechToTextProvider` (soporta Groq Whisper y OpenAI Whisper).
- Categorías del sistema + categorías personalizadas por usuario en PostgreSQL con fallback seguro a "otros".
- Presupuestos mensuales (`Budget`) con cálculo de porcentaje consumido y exceso.
- Servidor REST Express desacoplado (`/api/expenses`, `/api/categories`, `/api/budgets`, `/health`) con autenticación Bearer token.
- Dockerfile multi-stage de producción y `docker-compose.yml` local con volúmenes persistentes y healthchecks.

## Decisiones Técnicas Recientes
- **Categorías Dinámicas:** Migración de Enum a tabla `categories` con campo `category` en `Expense` preservando datos históricos.
- **Speech-to-Text:** Implementación `OpenAICompatibleSTTProvider` que usa la API estándar multipart de Whisper (Groq/OpenAI).
- **Mismo Flujo de Dominio:** Notas de voz se transcriben a texto y reutilizan idénticamente `ExpenseService.createFromText`.
- **API REST Desacoplada:** Controllers reutilizan los mismos servicios del bot sin duplicar lógica de negocio.

## Aprendizajes y Errores a Evitar (Gotchas)
- **Groq Whisper:** Velocidad < 1s y free tier amplio en `https://api.groq.com/openai/v1`.
- **Telegram Voice:** Las notas de voz vienen en formato `.ogg` (Opus) y se descargan directo desde la Bot API de Telegram vía `ctx.getFile()`.
- **Render Sleep:** Render free tier duerme el contenedor tras 15 min de inactividad; se requiere ping a `/health` o Railway (\$5 crédito/mes).

## Próximos Pasos
- [ ] Implementar aplicación móvil Flutter consumiendo la API REST.
- [ ] Alertas o notificaciones proactivas de presupuestos al aproximarse al límite.
- [ ] Exportación de reportes mensuales en CSV o PDF.
