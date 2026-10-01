export const EXPENSE_CATEGORIES = [
  'transporte',
  'comida',
  'vivienda',
  'servicios',
  'salud',
  'educacion',
  'entretenimiento',
  'ropa',
  'compras',
  'impuestos',
  'otros',
] as const;

export type ExpenseCategory = (typeof EXPENSE_CATEGORIES)[number];

export interface CreateExpenseData {
  userId: string;
  amount: number;
  description: string;
  category: ExpenseCategory;
  date: Date;
  installments?: number;
  currency?: string;
}

export interface MonthlyTotal {
  total: number;
  count: number;
  monthName: string;
  year: number;
}
