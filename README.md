# 💸 Bot de Control de Gastos Personales

Bot de Telegram desarrollado con **Node.js**, **TypeScript**, **Grammy**, **PostgreSQL**, **Prisma**, **Zod** y **OpenRouter (IA)**. Permite registrar gastos diarios mediante lenguaje natural (mensajes de texto) y convertirlos automáticamente en registros estructurados en base de datos.

---

## 🏛️ Arquitectura Resumida

El proyecto sigue una arquitectura en capas desacoplada con la regla de dependencias: las capas internas nunca dependen de las capas externas ni de tecnologías concretas.

```
Telegram (Grammy)
       │
       ▼
[src/bot] ──► [src/expenses] (ExpenseService) ──► [src/db] (Prisma + Repositories)
                      │
                      ▼
               [src/ai] (IAIProvider / OpenRouter)
```

- **`src/bot/`**: Adaptador de entrada para Telegram. Recibe comandos (`/start`, `/list`, `/total`) y mensajes de texto, resuelve al usuario y envía respuestas formateadas.
- **`src/ai/`**: Capa de inteligencia artificial. Define la interfaz `IAIProvider` y su implementación `OpenRouterProvider`. Incluye el `ExpenseParser` que valida las respuestas del modelo con Zod.
- **`src/expenses/`**: Núcleo de negocio. Aplica reglas de dominio, normalización de fechas y orquesta el flujo entre el parser de IA y la persistencia.
- **`src/users/`**: Gestión de usuarios basada en `telegramId`.
- **`src/db/`**: Capa de datos con repositorios (`UserRepository`, `ExpenseRepository`) y cliente singleton de Prisma.
- **`src/shared/`**: Utilidades transversales (configuración validada con Zod, logger y clases de error).

### Categorías Controladas

Para evitar que la IA invente categorías inexistentes, el sistema restringe las opciones a un conjunto cerrado:
`transporte`, `comida`, `vivienda`, `servicios`, `salud`, `educacion`, `entretenimiento`, `ropa`, `compras`, `impuestos`, `otros`.

El prompt inyecta esta lista de forma dinámica y la salida es validada en dos niveles:
1. **Zod** (`ParsedExpenseSchema`) en tiempo de ejecución.
2. **PostgreSQL Enum** (`Category`) a nivel de base de datos.

---

## 📋 Requisitos Previos

- **Node.js**: versión 18 o superior (recomendado 20+).
- **pnpm**: versión 9 o 10.
- **Docker & Docker Compose**: para ejecutar PostgreSQL en un contenedor local.
- **Token de Telegram**: creado desde [@BotFather](https://t.me/BotFather).
- **API Key de OpenRouter**: cuenta en [OpenRouter.ai](https://openrouter.ai).

---

## ⚙️ Variables de Entorno

Creá tu archivo `.env` en la raíz del proyecto a partir del archivo de ejemplo:

```bash
cp .env.example .env
```

Configurá las variables necesarias:

```env
NODE_ENV=development

# Telegram Bot Token obtenido de @BotFather
TELEGRAM_BOT_TOKEN="tu_token_aqui"

# Conexión a PostgreSQL (coincide con docker-compose.yml)
DATABASE_URL="postgresql://postgres:postgrespassword@localhost:5432/bot_gastos?schema=public"

# Proveedor de IA
AI_PROVIDER=openrouter
OPENROUTER_API_KEY="tu_openrouter_api_key"
OPENROUTER_MODEL="google/gemini-2.0-flash-001"
```

---

## 🚀 Instalación y Puesta en Marcha

### 1. Instalar dependencias

```bash
pnpm install
```

### 2. Iniciar PostgreSQL con Docker

```bash
docker compose up -d
```

Verificá que el contenedor esté corriendo:
```bash
docker ps
```

### 3. Aplicar migraciones de base de datos

Generar el cliente de Prisma y aplicar la migración inicial:

```bash
pnpm prisma:generate
pnpm prisma:migrate
```

*(Si querés sincronizar la base directamente en desarrollo sin guardar historial de migraciones, podés usar `pnpm prisma:push`).*

### 4. Iniciar el bot en modo desarrollo

```bash
pnpm dev
```

El bot iniciará en modo **long polling** y mostrará en consola:
```
[INFO] Proveedor de IA configurado: OpenRouter (modelo: google/gemini-2.0-flash-001)
[INFO] Iniciando long polling con Telegram...
[INFO] ✅ Bot iniciado correctamente como @TuBot
```

---

## 🧪 Cómo Probar el MVP

1. Abrí tu bot en Telegram e ingresá `/start`.
2. Enviá un mensaje de gasto en lenguaje natural:
   - `"Gasté 5000 en Saeta"`
   - `"Ayer gasté 12000 en el supermercado"`
   - `"Pagué 35000 de luz"`
   - `"Compré zapatillas por 80000 en 3 cuotas"`
3. El bot responderá con una confirmación estructurada:
   ```
   ✅ Registré $ 5.000 en transporte 🚌
   📝 Detalle: Saeta
   📅 Fecha: 30/09/2026
   ```
4. Consultá tus últimos gastos con el comando:
   ```
   /list
   ```
5. Consultá el total acumulado en el mes actual con:
   ```
   /total
   ```

---

## 🛠️ Scripts Disponibles

- `pnpm dev`: Inicia el bot en desarrollo con recarga en caliente (`tsx watch`).
- `pnpm build`: Compila TypeScript a JavaScript en la carpeta `dist/`.
- `pnpm start`: Ejecuta la versión compilada en `dist/index.js`.
- `pnpm typecheck`: Verifica tipos de TypeScript sin emitir archivos (`tsc --noEmit`).
- `pnpm test`: Ejecuta las pruebas unitarias de validación y parsing.
- `pnpm prisma:generate`: Regenera el cliente de Prisma.
- `pnpm prisma:migrate`: Aplica las migraciones de Prisma.
