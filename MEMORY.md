# Project Memory (Bot de Gastos)
> **Reglas de uso:** Memoria episódica entre sesiones. Mantener siempre por debajo de **50-60 líneas**. Resumir o eliminar lo que ya no aporte valor. Si algo se vuelve una regla permanente, moverlo a `AGENTS.md`. **NUNCA** guardar secretos, tokens ni datos sensibles.

## Estado Actual
- Bot de Telegram en producción: texto, voz (STT), comandos `/gastos`, `/total`, `/presupuesto`, `/categorias`, `/vincular`.
- API REST Express completa con autenticación Bearer token (base64url emitido por `/vincular`), endpoints `/api/expenses`, `/api/categories`, `/api/budgets`, `/api/summary`, `/api/analytics` y `/api/me`.
- App móvil Flutter completa en `/mobile` con Riverpod, Dio, Secure Storage, Material 3, fl_chart (donut y barras), validaciones, edición de gastos y control de presupuestos.
- PostgreSQL en Docker con Prisma ORM (modelos User, Expense, Category, Budget).

## Decisiones Técnicas Recientes
- **App Flutter Decoupled:** Aplicación móvil en `mobile/` consumiendo la API REST existente sin duplicar lógica de negocio.
- **Autenticación Móvil Segura:** Token generado en Telegram `/vincular` validado contra `/api/me` y persistido con `flutter_secure_storage`.
- **Capa Core Móvil:** Interceptor Dio que inyecta automáticamente `Authorization: Bearer <token>` y URL base dinámica para emulador/dispositivo.
- **Edición y Analytics en Backend:** Agregado `PUT /api/expenses/:id`, `GET /api/me` y `GET /api/analytics` con historial de 6 meses para gráficos.

## Aprendizajes y Errores a Evitar (Gotchas)
- **Windows Flutter Path:** SDK en `C:\Users\santi\Documents\SantiUNSa\DesarrolloMovil\flutter\bin\flutter.bat`.
- **Interpolación en Strings Dart:** Carácter `$` en etiquetas de monedas debe escaparse (`r'ARS ($)'`).
- **Android Emulator Loopback:** Emulador Android se comunica con localhost vía `http://10.0.2.2:3000`.

## Próximos Pasos
- [ ] Alertas o notificaciones proactivas de presupuestos al aproximarse al límite.
- [ ] Exportación de reportes mensuales en CSV o PDF.
- [ ] Insights financieros basados en IA (sección futura).
