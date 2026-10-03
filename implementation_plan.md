# Plan de Implementación — App Móvil Flutter (Bot de Gastos)

## 1. Auditoría del Backend Existente (Fase 1)

### 1.1 Endpoints Existentes
| Método | Endpoint | Descripción | Parámetros / Body |
|---|---|---|---|
| `GET` | `/health` | Chequeo de salud del servicio | Público |
| `GET` | `/api/expenses` | Listar gastos | Query: `limit`, `offset`, `category` |
| `GET` | `/api/expenses/:id` | Obtener gasto individual | Param: `id` |
| `POST` | `/api/expenses` | Crear gasto (texto NL o estructurado) | `{ text }` o `{ amount, description, category, date, installments, currency }` |
| `DELETE` | `/api/expenses/:id` | Eliminar gasto | Param: `id` |
| `GET` | `/api/summary` | Resumen mensual actual | Sin query params (usa mes actual) |
| `GET` | `/api/categories` | Listar categorías activas | Sistema + personalizadas del usuario |
| `POST` | `/api/categories` | Crear categoría personalizada | `{ name, icon }` |
| `PUT` | `/api/categories/:id` | Modificar categoría personalizada | `{ name?, icon? }` |
| `PATCH` | `/api/categories/:id/deactivate` | Desactivar categoría personalizada | Param: `id` |
| `GET` | `/api/budgets` | Presupuestos con progreso | Calcula gastado vs límite del mes actual |
| `POST` | `/api/budgets` | Fijar presupuesto | `{ category, amount, currency? }` |
| `DELETE` | `/api/budgets/:id` | Eliminar presupuesto | Param: `id` |

### 1.2 Mecanismo de Vinculación y Autenticación
1. **Generación del Token en Telegram (`/vincular` o `/token`):**
   - Ejecutado en el bot (`src/bot/handlers/commands.ts`).
   - Crea un JSON: `{"userId": "<uuid>", "telegramId": "<id>", "issuedAt": <timestamp>}`.
   - Lo codifica en formato `base64url` y lo envía al usuario en un bloque de código fácil de copiar.
2. **Validación del Token en la API (`src/api/middlewares/auth.middleware.ts`):**
   - El cliente envía el header `Authorization: Bearer <token_base64url>`.
   - El middleware decodifica el base64url, extrae `payload.userId` y lo inyecta en `req.userId`.
3. **Almacenamiento en la App Móvil:**
   - Flutter guardará el token en `flutter_secure_storage` (cifrado en Keystore/Keychain).
   - En cada petición HTTP subsiguiente, un interceptor de `Dio` adjuntará automáticamente el encabezado `Authorization: Bearer <token>`.

### 1.3 Endpoints Faltantes o Ajustes Necesarios en el Backend
Respetando estrictamente la arquitectura existente sin cambiar tecnologías ni base de datos:
1. **`PUT /api/expenses/:id` (Editar gasto):**
   - Requerido explícitamente para permitir la edición de gastos desde Flutter.
   - Recibirá: `{ amount?, description?, category?, date?, installments?, currency? }`.
   - Reutiliza validaciones de `ExpenseService` y mapeo de categorías.
2. **`GET /api/me` (Validación de vinculación y perfil):**
   - Permite que Flutter verifique si el token pegado es válido inmediatamente y obtenga los datos del usuario (`id`, `telegramId`, `createdAt`).
3. **Filtros en `GET /api/expenses` (`search`, `startDate`, `endDate`):**
   - Para soportar búsqueda por texto y filtrado por rango de fechas (períodos/meses).
4. **Navegación temporal en `GET /api/summary` (`?year=YYYY&month=M`):**
   - Para permitir cambiar de mes (anterior, actual, siguiente) tanto en Inicio como en Estadísticas.
5. **Historial de últimos meses para Estadísticas (`GET /api/analytics`):**
   - Retorna los totales de los últimos 6 meses para renderizar el gráfico de barras sin saturar de peticiones.

---

## 2. Arquitectura & Stack Tecnológico de Flutter (Fase 2)

### 2.1 Configuración del Proyecto Móvil
- **Directorio:** `mobile/`
- **Flutter SDK:** 3.44.5 (Dart 3.12.2)
- **Design System:** Material 3 con paleta moderna (Tema Slate/Emerald financiero minimalista, soporte para Light y Dark mode).

### 2.2 Paquetes Clave (`pubspec.yaml`)
- `flutter_riverpod` (v2.x): Gestión de estado predecible, inmutable y desacoplada.
- `dio`: Cliente HTTP con interceptores para autenticación automática, timeouts y manejo de errores estandarizado.
- `flutter_secure_storage`: Persistencia segura del token de sesión.
- `intl`: Formateo de moneda (`$ 15.000`), fechas en español (`12 de octubre`, `Hoy`, `Ayer`).
- `fl_chart`: Gráficos interactivos y limpios (Pie/Donut chart de categorías, Bar chart mensual).

### 2.3 Estructura de Carpetas (`mobile/lib/`)
```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart          # Instancia Dio con interceptor de auth y logs
│   │   ├── api_endpoints.dart       # URLs centralizadas
│   │   └── api_error_handler.dart   # Mapeo de errores HTTP a excepciones amigables
│   ├── storage/
│   │   └── secure_storage_service.dart # Manejo de tokens y datos locales
│   ├── theme/
│   │   ├── app_theme.dart           # Colores Material 3, tipografías y bordes
│   │   └── app_colors.dart          # Paleta visual consistente
│   └── utils/
│       ├── currency_formatter.dart  # Formato ARS / moneda
│       ├── date_formatter.dart      # Formato de fechas relativo (Hoy, Ayer, etc.)
│       └── category_icons.dart      # Mapeo de emojis/iconos consistentes
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   ├── presentation/link_screen.dart # Pantalla de vinculación con instrucciones
│   │   └── providers/auth_provider.dart
│   ├── navigation/
│   │   └── presentation/main_navigation_screen.dart # Bottom Navigation Bar
│   ├── home/
│   │   ├── presentation/home_screen.dart # Resumen mensual, top categorías, gastos recientes
│   │   └── presentation/widgets/ # Card de balance, gráfico rápido, mes selector
│   ├── expenses/
│   │   ├── data/expense_repository.dart
│   │   ├── models/expense_model.dart
│   │   ├── presentation/expense_list_screen.dart # Listado agrupado por fecha con buscador y filtro
│   │   ├── presentation/expense_form_screen.dart # Crear y editar gasto
│   │   ├── presentation/expense_detail_sheet.dart # Bottom sheet con detalle y confirmación de borrado
│   │   └── providers/expense_providers.dart
│   ├── categories/
│   │   ├── data/category_repository.dart
│   │   ├── models/category_model.dart
│   │   ├── presentation/category_list_screen.dart # Gestión de categorías sistema y personalizadas
│   │   ├── presentation/category_form_dialog.dart # Crear y editar categoría con selector de icono
│   │   └── providers/category_providers.dart
│   ├── budgets/
│   │   ├── data/budget_repository.dart
│   │   ├── models/budget_model.dart
│   │   ├── presentation/budget_list_screen.dart # Barras de progreso, estado visual, total del mes
│   │   ├── presentation/budget_form_dialog.dart # Crear y editar presupuesto
│   │   └── providers/budget_providers.dart
│   ├── analytics/
│   │   ├── presentation/analytics_screen.dart # Donut chart de categorías, bar chart mensual, evolución
│   │   └── providers/analytics_providers.dart
│   └── settings/
│       └── presentation/settings_screen.dart # Estado de vinculación, desvincular, config de URL
└── shared/
    └── widgets/
        ├── empty_state_view.dart    # Vistas vacías cuidadas y amigables
        ├── error_view.dart          # Reintentos de red y avisos de error
        └── loading_indicator.dart
```

---

## 3. Plan de Pantallas y Experiencia de Usuario (Fase 2 Detallada)

### 3.1 Flujo de Bienvenida & Vinculación con Telegram
- **Estado Inicial:** Si no existe token en almacenamiento seguro, se muestra `LinkScreen`.
- **UI:** Explicación limpia de 4 pasos (Abrir bot en Telegram -> `/vincular` -> Copiar token -> Pegar aquí).
- **Validación en vivo:** Input con botón "Pegar del portapapeles", llamada inmediata a `GET /api/me`. Si es exitoso, bienvenida con feedback y transición fluida al Home. Manejo amigable de token inválido o problemas de conectividad con el backend.
- **Configuración de Host:** Opción para ajustar la URL base del backend (por defecto `http://10.0.2.2:3000` para emulador Android, `http://localhost:3000` para Chrome/Web, o IP local para dispositivo físico).

### 3.2 Navegación Principal (Bottom Navigation)
1. **Inicio:** Resumen del mes, presupuesto disponible, selector de mes, gastos recientes, top categorías.
2. **Gastos:** Historial completo, agrupado visualmente por días (Hoy, Ayer, 29 de Septiembre...), barra de búsqueda por texto, chips de filtro por categoría y botón flotante `+ Gasto`.
3. **Estadísticas:** Distribución porcentual en donut chart, gráfico de barras de los últimos meses, evolución por categoría al tocarla, métricas clave.
4. **Presupuestos:** Presupuesto total mensual acumulado, tarjetas con barra de progreso por categoría (verde <80%, amarillo 80-99%, rojo >=100% con advertencia de exceso).
5. **Más (Ajustes):** Estado de cuenta de Telegram conectada (ID no sensible), gestión de Categorías, selección de servidor/URL y botón "Desvincular Telegram".

### 3.3 Formularios y Acciones
- **Crear/Editar Gasto:** Teclado numérico grande para monto, selector de fecha (Date Picker nativo), dropdown de categorías (obtenido del backend), campo de cuotas (por defecto 1), descripción.
- **Detalle & Eliminación:** Bottom Sheet modal con información completa, botón de "Editar" y botón de "Eliminar" con diálogo de confirmación explícita.
- **Invalidación de Estado Reactiva:** Al crear/editar/eliminar un gasto, Riverpod refresca automáticamente la lista de gastos, el resumen de inicio, los presupuestos y las estadísticas.

---

## 4. Tareas de Implementación (Fase 3 & 4)

### Backend (Adiciones Mínimas)
- [ ] Implementar `updateExpense` en `ExpenseRepository`, `ExpenseService` y `ExpenseController`.
- [ ] Agregar soporte para `search`, `startDate` y `endDate` en `listExpenses`.
- [ ] Agregar soporte para `year` y `month` en `getMonthlySummary`.
- [ ] Implementar endpoint `GET /api/me` para validación de token y consulta de usuario.
- [ ] Implementar endpoint de analítica histórica mensual `GET /api/analytics` para soporte de gráficos.
- [ ] Correr Quality Gates locales: `pnpm typecheck`, `pnpm test`, `pnpm build`.

### Frontend Flutter
- [ ] Crear proyecto Flutter en `mobile/` (`flutter create --org com.botgastos --project-name bot_gastos mobile`).
- [ ] Configurar `pubspec.yaml` con `flutter_riverpod`, `dio`, `flutter_secure_storage`, `intl`, `fl_chart`.
- [ ] Implementar capa `core`: cliente Dio, interceptor de autenticación, almacenamiento seguro, tema Material 3, utilidades de fecha y moneda.
- [ ] Implementar módulo de Autenticación & Vinculación (`LinkScreen`, validación contra `/api/me`, storage).
- [ ] Implementar `MainNavigationScreen` con Bottom Navigation Bar de 5 tabs.
- [ ] Implementar módulo de Gastos:
  - Repositorio y providers.
  - Listado de gastos agrupados por fecha con buscador y filtro.
  - Pantalla modal de creación y edición con validación.
  - Detalle de gasto con acción de eliminar confirmada.
- [ ] Implementar módulo de Inicio (`HomeScreen`):
  - Card de resumen del mes y balance restante.
  - Selector interactivo de meses anterior/actual/siguiente.
  - Top 3 categorías del mes con barras proporcionales.
  - Últimos gastos con navegación a detalle.
- [ ] Implementar módulo de Presupuestos:
  - Listado de presupuestos con barras de progreso y porcentaje.
  - Diálogo para fijar / editar presupuesto por categoría.
  - Eliminación de presupuestos.
- [ ] Implementar módulo de Categorías:
  - Visualización diferenciada: categorías del sistema vs personalizadas.
  - Creación de categorías personalizadas con emoji/icono.
  - Edición y desactivación.
- [ ] Implementar módulo de Estadísticas:
  - Gráfico Donut de distribución por categoría con leyenda y montos.
  - Gráfico de barras de evolución mensual.
  - Evolución histórica por categoría seleccionada.
- [ ] Implementar pantalla de Ajustes (conexión de Telegram, desvincular, info de app).
- [ ] Manejo exhaustivo de estados vacíos (empty states ilustrados y amigables) y errores de red con reintentos.

### Validación y Auditoría (Fase 5)
- [ ] Verificación de flujo completo en tests y análisis estático (`flutter analyze`).
- [ ] Verificar Quality Gates locales de backend (`pnpm test`, `pnpm typecheck`, `pnpm build`).
- [ ] Actualizar `MEMORY.md`.
