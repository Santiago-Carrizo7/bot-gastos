# 💸 Bot de Control de Gastos Personales + API REST

Sistema integral de gestión de finanzas personales vía Telegram y API REST, desarrollado con **Node.js**, **TypeScript**, **Grammy**, **PostgreSQL**, **Prisma**, **Zod**, **OpenRouter (LLM)** y **Groq / OpenAI Whisper (Speech-to-Text)**.

Permite registrar gastos diarios mediante lenguaje natural (texto o **notas de voz**), administrar categorías personalizadas por usuario, fijar presupuestos mensuales y consultar datos vía API para futuras aplicaciones (Flutter).

---

## 🏛️ Arquitectura del Sistema

```
                        ┌──────────────────────────────┐
                        │   Clientes (Telegram / App)  │
                        └───────┬──────────────┬───────┘
                                │              │
                   Notas de voz │              │ Mensajes de texto / HTTP
                                ▼              ▼
                    ┌──────────────────┐  ┌──────────────────┐
                    │  STT (Whisper)   │  │   Telegram Bot   │
                    └─────────┬────────┘  │        &         │
                              │           │  REST API Server │
                              │ Texto     └────────┬─────────┘
                              ▼                    │
                    ┌──────────────────────────────▼───┐
                    │       ExpenseService (Core)      │
                    └───────┬──────────────────┬───────┘
                            │                  │
                Categorías  │                  │ Parseo estructurado
                específicas │                  ▼
                            │         ┌──────────────────┐
                            │         │  ExpenseParser   │
                            │         │ (IA OpenRouter)  │
                            │         └────────┬─────────┘
                            ▼                  ▼
                    ┌──────────────────────────────────┐
                    │      PostgreSQL (via Prisma)     │
                    │   users • expenses • categories  │
                    │              budgets             │
                    └──────────────────────────────────┘
```

- **`src/bot/`**: Adaptador de Telegram. Comandos (`/start`, `/list`, `/total`, `/budget`, `/categories`, `/token`) y handlers para texto y notas de voz (`voice.ts`).
- **`src/api/`**: Servidor REST (Express) desacoplado que reutiliza los servicios del dominio. Incluye middleware de autenticación (`Bearer token`), validaciones con Zod y health check (`/health`).
- **`src/ai/stt/`**: Abstracción `ISpeechToTextProvider` con implementación `OpenAICompatibleSTTProvider` (Groq Whisper por defecto con latencia < 1s y costo cero en free tier).
- **`src/ai/`**: Abstracción `IAIProvider` y `ExpenseParser` con inyección dinámica de categorías por usuario.
- **`src/categories/`**: Gestión de categorías predefinidas del sistema + categorías personalizadas aisladas por usuario.
- **`src/budgets/`**: Cálculo de consumo y progreso de presupuestos mensuales por categoría.
- **`src/expenses/`**: Orquestador central de registro, listados y resúmenes.
- **`src/db/`**: Repositorios Prisma (`ExpenseRepository`, `CategoryRepository`, `BudgetRepository`, `UserRepository`).

---

## 📋 Requisitos Previos

- **Node.js**: v20+ con ESM.
- **pnpm**: v10 (`pnpm.cmd` en Windows).
- **Docker & Docker Compose**: para PostgreSQL local.
- **Token de Telegram**: creado desde [@BotFather](https://t.me/BotFather).
- **API Key de OpenRouter**: en [OpenRouter.ai](https://openrouter.ai).
- **API Key de Groq (Opcional para Audio)**: gratuita en [Groq Console](https://console.groq.com) (o OpenAI API key).

---

## ⚙️ Variables de Entorno

Creá tu archivo `.env` a partir de `.env.example`:

```env
NODE_ENV=development
PORT=3000
API_SECRET="tu_clave_secreta_para_firmar_tokens"

# Telegram Bot
TELEGRAM_BOT_TOKEN="tu_token_aqui"

# PostgreSQL
DATABASE_URL="postgresql://postgres:postgrespassword@localhost:5432/bot_gastos?schema=public"

# Proveedor de IA de Texto
AI_PROVIDER=openrouter
OPENROUTER_API_KEY="tu_openrouter_api_key"
OPENROUTER_MODEL="google/gemini-2.0-flash-001"

# Proveedor de Speech-to-Text (Audio / Voz)
STT_PROVIDER=groq
STT_API_KEY="tu_groq_api_key"
STT_MODEL="whisper-large-v3-turbo"
```

---

## 🚀 Puesta en Marcha Local

### 1. Iniciar PostgreSQL con Docker

```bash
docker compose up -d
```

### 2. Ejecutar Migraciones de Base de Datos

```bash
pnpm prisma:generate
pnpm prisma:migrate
```

### 3. Iniciar el Servidor y Bot en Desarrollo

```bash
pnpm dev
```

La consola confirmará el inicio de ambos servicios:
```
[INFO] Proveedor STT configurado: Groq Whisper (modelo: whisper-large-v3-turbo)
[INFO] 🚀 Servidor HTTP escuchando en http://localhost:3000 (Health check: /health)
[INFO] ✅ Bot iniciado correctamente como @TuBot
```

---

## 📱 Interacción con el Bot de Telegram

### Registro de Gastos (Texto o Audio)
- **Texto:** `"Gasté 5000 en Saeta ayer"`, `"Compré zapatillas por 80000 en 3 cuotas"`.
- **Nota de voz 🎙️:** Enviá un audio diciendo tu gasto; el bot lo transcribirá e interpretará al instante.

### Comandos Disponibles
- `/start` — Mensaje de bienvenida y ayuda.
- `/list` — Ver los últimos 5 gastos registrados.
- `/total` — Ver total acumulado en el mes en curso.
- `/budget` — Consultar el progreso de presupuestos mensuales del mes.
- `/budget <categoría> <monto>` — Fijar o actualizar un presupuesto (ej: `/budget comida 150000`).
- `/categories` — Ver categorías activas del sistema y tus categorías personalizadas.
- `/token` — Generar token de acceso para la API REST / App móvil.

---

## 🌐 Endpoints de la API REST

Todos los endpoints (excepto `/health`) requieren autenticación mediante el header `Authorization: Bearer <token>` (obtenido con `/token` en Telegram) o `x-user-id: <id>` en desarrollo local.

### Gastos
- `GET /api/expenses` — Listar gastos (parámetros opcionales: `limit`, `offset`, `category`).
- `GET /api/expenses/:id` — Obtener un gasto por ID.
- `POST /api/expenses` — Crear gasto estructurado (`{ amount, description, category }`) o por texto (`{ text: "Gasté 5000 en Saeta" }`).
- `DELETE /api/expenses/:id` — Eliminar gasto propio.
- `GET /api/summary` — Resumen mensual y desglose por categorías.

### Categorías
- `GET /api/categories` — Listar categorías activas disponibles (sistema + usuario).
- `POST /api/categories` — Crear categoría personalizada (`{ name: "gimnasio", icon: "🏋️" }`).
- `PUT /api/categories/:id` — Modificar nombre/icono de categoría personalizada.
- `PATCH /api/categories/:id/deactivate` — Desactivar categoría personalizada.

### Presupuestos
- `GET /api/budgets` — Listar presupuestos con progreso del mes (% consumido, gastado, remanente).
- `POST /api/budgets` — Fijar o actualizar presupuesto (`{ category: "comida", amount: 150000 }`).
- `DELETE /api/budgets/:id` — Eliminar presupuesto.

### Health Check
- `GET /health` — `{"status": "ok", "uptime": 120}`

---

## ☁️ Estrategia de Despliegue en Producción

Para uso personal o familiar económico sin complicaciones:

### Opción 1 (Recomendada PaaS): Railway / Render
1. Conectar el repositorio de GitHub.
2. Crear un servicio de **PostgreSQL administrado** (volumen persistente incluido).
3. Crear un **Web Service** apuntando al `Dockerfile` del proyecto.
4. Inyectar las variables de entorno en el panel.
5. El contenedor ejecuta automáticamente `pnpm exec prisma migrate deploy` antes de iniciar.
> **Consideración:** En el plan gratuito de Render, el contenedor web se suspende tras 15 minutos sin peticiones HTTP entrantes. Para evitar esto, Railway incluye \$5 de crédito mensual continuo, o se puede configurar un monitor de uptime que haga ping regular a `/health`.

### Opción 2 (VPS Económica): Hetzner Cloud / DigitalOcean (~$4 USD/mes)
- Despliegue directo con `docker compose` incluyendo PostgreSQL y la aplicación compilada.
- Control total, sin limitaciones de reposo (*sleep*) ni cuotas reducidas.

---

## 🧪 Pruebas y Calidad de Código

- `pnpm typecheck` — Verificación estricta de tipos de TypeScript.
- `pnpm test` — Pruebas unitarias de parsing, fallback de categorías, STT y formatters.
- `pnpm build` — Compilación a JavaScript en `dist/`.
