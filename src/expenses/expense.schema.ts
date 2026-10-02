import { z } from 'zod';

export const ParsedExpenseSchema = z.object({
  amount: z
    .number({ invalid_type_error: 'El monto debe ser un número' })
    .positive('El monto debe ser mayor a 0'),
  description: z
    .string({ invalid_type_error: 'La descripción debe ser texto' })
    .trim()
    .min(1, 'La descripción no puede estar vacía'),
  category: z
    .string({ invalid_type_error: 'La categoría debe ser texto' })
    .trim()
    .toLowerCase()
    .min(1, 'La categoría no puede estar vacía'),
  date: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'La fecha debe estar en formato YYYY-MM-DD'),
  installments: z
    .number()
    .int('Las cuotas deben ser un número entero')
    .min(1, 'Debe tener al menos 1 cuota')
    .default(1),
  currency: z
    .string()
    .trim()
    .toUpperCase()
    .default('ARS'),
});

export type ParsedExpense = z.infer<typeof ParsedExpenseSchema>;
