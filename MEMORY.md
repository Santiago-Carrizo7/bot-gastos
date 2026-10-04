# Project Memory (Bot de Gastos)
> **Reglas de uso:** Memoria episódica entre sesiones. Mantener siempre por debajo de **50-60 líneas**. Resumir o eliminar lo que ya no aporte valor. Si algo se vuelve una regla permanente, moverlo a `AGENTS.md`. **NUNCA** guardar secretos, tokens ni datos sensibles.

## Estado Actual
- Bot de Telegram en producción: texto, voz (STT), comandos `/gastos`, `/total`, `/presupuesto`, `/categorias`, `/vincular`.
- API REST Express completa con autenticación Bearer token (base64url emitido por `/vincular`), endpoints `/api/expenses`, `/api/categories`, `/api/budgets`, `/api/summary`, `/api/analytics` y `/api/me`.
- App móvil Flutter completa en `/mobile` con Riverpod, Dio, Secure Storage, Material 3, fl_chart (donut y barras), validaciones, edición de gastos y control de presupuestos.
- PostgreSQL en Docker con Prisma ORM (modelos User, Expense, Category, Budget).

## Decisiones Técnicas Recientes
- **App Flutter Decoupled:** Aplicación móvil en `mobile/` consumiendo la API REST sin duplicar lógica.
- **Autenticación Móvil:** Token de `/vincular` validado contra `/api/me` y guardado en `flutter_secure_storage`.
- **UI & UX Móvil Pulida:** Barra inferior con etiqueta `'Presupuesto'` a 11sp en una sola línea; gráfico de torta con paleta de colores fija de alto contraste que garantiza que ninguna categoría repita color.
- **Resiliencia de Períodos:** `ExpenseRepository.getMonthlySummary` calcula totales por rango de fechas si el servidor no filtra por mes/año.
- **Backend & Despliegue Sincronizado:** Endpoints `PUT /api/expenses/:id`, `GET /api/me`, `GET /api/analytics` y `NotFoundError` (404) desplegados en Render.

## Aprendizajes y Errores a Evitar (Gotchas)
- **Windows Flutter Path:** SDK en `C:\Users\santi\Documents\SantiUNSa\DesarrolloMovil\flutter\bin\flutter.bat`.
- **Render Auto-Deploy:** Requiere `git push origin main` para que Render compile los nuevos endpoints Express.
- **Colores en Gráficos:** No usar hash-modulo para asignar colores en gráficos para evitar colisiones cromáticas.

## Próximos Pasos
- [ ] Exportación de reportes mensuales en CSV o PDF.
- [ ] Insights financieros basados en IA.
