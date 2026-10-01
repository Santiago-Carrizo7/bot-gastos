# AGENTS.md — Bot de Gastos Personales

## 1. Contexto del Proyecto & Stack Tecnológico
Bot de Telegram para control y registro de gastos personales en lenguaje natural, persistidos en PostgreSQL.
- **Runtime:** Node.js (v20+) con ESM (`"type": "module"` e imports `.js` obligatorios).
- **Lenguaje:** TypeScript estricto (`target: ES2022`, `moduleResolution: NodeNext`, strict mode).
- **Core:** Grammy (Telegram Bot), Prisma ORM, PostgreSQL 16 (Docker), Zod (validación), OpenRouter (LLM).
- **Package Manager Obligatorio:** `pnpm` (usar `pnpm.cmd` en Windows). Prohibido mezclar con npm o yarn.

## 2. Arquitectura & Convenciones
Arquitectura en capas desacoplada. Capas internas nunca conocen capas externas ni detalles de transporte.
- `src/bot/`: Handlers de Telegram, middlewares (`user.middleware.ts`), contexto y formatters.
- `src/ai/`: Abstracción `IAIProvider`, adaptadores (`OpenRouterProvider`), prompts y `ExpenseParser`.
- `src/expenses/`: Dominio de negocio (`ExpenseService`, validación Zod y tipos).
- `src/users/`: Gestión de usuarios por `telegramId`.
- `src/db/`: Prisma singleton y repositorios (`UserRepository`, `ExpenseRepository`).
- `src/shared/`: Configuración validada con Zod (`config.ts`), errores personalizados y logger.
- **Categorías Controladas:** Definidas en `EXPENSE_CATEGORIES`. Validadas en Zod, Postgres Enum e inyectadas dinámicamente en el prompt. Si un gasto no encaja, usar `"otros"`.

## 3. Protocolo de Memoria (`MEMORY.md`)
- **Inicio de Sesión:** Leer `MEMORY.md` para conocer estado actual, decisiones y próximos pasos.
- **Fin de Tarea:** Actualizar `MEMORY.md` con decisiones clave, gotchas descubiertos y próximos pasos.
- **Límite Estricto:** Mantener siempre por debajo de **50–60 líneas**. Podar ítems obsoletos.
- **Promoción de Reglas:** Si un patrón o lección se vuelve permanente, moverlo a `AGENTS.md`.
- **Cero Secretos:** NUNCA escribir API keys, tokens ni credenciales en `MEMORY.md` ni `AGENTS.md`.

## 4. Flujo de Desarrollo en 4 Etapas
1. **Etapa 1 — Spec & Plan (`/spec` y `/plan`):**
   - **Regla de Plan Único:** Consolidar especificación y tareas en un único `implementation_plan.md`.
   - **Prohibido:** Crear carpetas `tasks/` (`tasks/plan.md`, `tasks/todo.md`) o dividir en múltiples `.md`.
2. **Etapa 2 — Build, Test & Simplify (`/build`, `/test`, `/code-simplify`):**
   - Implementar en slices verticales verificables.
   - Simplificar código tras pasar tests sin alterar comportamiento.
   - Ejecutar los Quality Gates locales antes de avanzar.
3. **Etapa 3 — Pre-Delivery Audit (`/ship` y `/code-review`):**
   - Revisión en 5 ejes (correctitud, legibilidad, arquitectura, seguridad, performance) y verificación de edge cases.
4. **Etapa 4 — Commits Semánticos (`/autocommit`):**
   - Mensajes de commit **OBLIGATORIAMENTE EN ESPAÑOL** siguiendo Conventional Commits (`tipo(alcance): descripción`).
   - Ejemplos: `feat(bot): agregar comando /resumen`, `fix(ai): corregir parseo de cuotas`.
   - NUNCA ejecutar `git push` a menos que el usuario lo solicite explícitamente.

## 5. Quality Gates Locales (Anti-CI-Failure)
Antes de dar cualquier tarea por completada, ejecutar obligatoriamente:
1. `pnpm typecheck` (`tsc --noEmit`)
2. `pnpm test` (`tsx src/expenses/expense-flow.test.ts`)
3. `pnpm build` (`tsc`)
