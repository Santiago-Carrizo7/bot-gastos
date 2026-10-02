import { SYSTEM_CATEGORIES } from '../expenses/expense.types.js';

export const CATEGORY_ICONS: Record<string, string> = {
  transporte: '🚌',
  comida: '🍔',
  vivienda: '🏠',
  servicios: '💡',
  salud: '💊',
  educacion: '📚',
  entretenimiento: '🎉',
  ropa: '👕',
  compras: '🛍️',
  impuestos: '🏛️',
  otros: '📦',
};

export function getCategoryIcon(categoryName: string, customIcon?: string | null): string {
  if (customIcon) return customIcon;
  const normalized = categoryName.toLowerCase().trim();
  return CATEGORY_ICONS[normalized] ?? '🏷️';
}

export function formatCurrency(amount: number | string, currency: string = 'ARS'): string {
  const num = typeof amount === 'string' ? parseFloat(amount) : amount;
  const formatted = new Intl.NumberFormat('es-AR', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(num);

  if (currency === 'USD') {
    return `US$ ${formatted}`;
  }
  return `$ ${formatted}`;
}

export function formatDate(date: Date): string {
  const day = String(date.getUTCDate()).padStart(2, '0');
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const year = date.getUTCFullYear();
  return `${day}/${month}/${year}`;
}
