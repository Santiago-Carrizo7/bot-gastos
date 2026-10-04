import 'package:flutter/material.dart';

class CategoryIcons {
  static const Map<String, String> defaultEmojis = {
    'comida': '🍔',
    'transporte': '🚌',
    'vivienda': '🏠',
    'servicios': '💡',
    'salud': '💊',
    'educacion': '📚',
    'educación': '📚',
    'entretenimiento': '🎬',
    'ropa': '👕',
    'compras': '🛍️',
    'impuestos': '🏛️',
    'supermercado': '🛒',
    'salidas': '🍻',
    'deportes': '⚽',
    'viajes': '✈️',
    'otros': '📦',
  };

  static const List<String> availableEmojis = [
    '🍔', '🍕', '☕', '🛒', '🚌', '🚗', '⛽', '🏠',
    '💡', '💊', '🏥', '📚', '🎬', '🎮', '👕', '🛍️',
    '🏛️', '🍻', '⚽', '🏋️', '✈️', '💻', '📱', '📦',
    '🐾', '🎁', '💈', '🔨', '🎓', '🎨', '🏖️', '💵',
  ];

  static String getEmoji(String categoryName, [String? explicitIcon]) {
    if (explicitIcon != null && explicitIcon.trim().isNotEmpty) {
      return explicitIcon.trim();
    }
    final normalized = categoryName.toLowerCase().trim();
    return defaultEmojis[normalized] ?? '🏷️';
  }

  static const Map<String, Color> fixedCategoryColors = {
    'comida': Color(0xFFF59E0B), // Ámbar Cálido
    'transporte': Color(0xFF2563EB), // Azul Royal
    'entretenimiento': Color(0xFF9333EA), // Púrpura Vibrante
    'supermercado': Color(0xFF10B981), // Esmeralda
    'salidas': Color(0xFFF97316), // Naranja Intenso
    'salud': Color(0xFFE11D48), // Rosa Carmesí / Rojo
    'servicios': Color(0xFF06B6D4), // Cian Eléctrico
    'vivienda': Color(0xFF4F46E5), // Índigo Profundo
    'educacion': Color(0xFF84CC16), // Lima
    'educación': Color(0xFF84CC16), // Lima
    'ropa': Color(0xFFD946EF), // Fucsia Magenta
    'compras': Color(0xFF0D9488), // Teal
    'viajes': Color(0xFFEA580C), // Naranja Óxido
    'deportes': Color(0xFF0284C7), // Celeste Cielo
    'impuestos': Color(0xFF64748B), // Gris Pizarra
    'otros': Color(0xFF94A3B8), // Gris Neutro
  };

  static const List<Color> distinctPalette = [
    Color(0xFF2563EB), // Azul Royal
    Color(0xFFF59E0B), // Ámbar
    Color(0xFF9333EA), // Púrpura
    Color(0xFF10B981), // Esmeralda
    Color(0xFFE11D48), // Carmesí
    Color(0xFF06B6D4), // Cian
    Color(0xFFF97316), // Naranja
    Color(0xFF4F46E5), // Índigo
    Color(0xFF84CC16), // Lima
    Color(0xFFD946EF), // Fucsia
    Color(0xFF0D9488), // Teal
    Color(0xFFEA580C), // Cobrizo
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF64748B), // Slate Gray
    Color(0xFFB91C1C), // Deep Red
    Color(0xFF047857), // Forest Green
  ];

  static Color getColorForCategory(String categoryName, [int? fallbackIndex]) {
    final normalized = categoryName.toLowerCase().trim();
    if (fixedCategoryColors.containsKey(normalized)) {
      return fixedCategoryColors[normalized]!;
    }
    if (fallbackIndex != null) {
      return distinctPalette[fallbackIndex % distinctPalette.length];
    }
    final hash = normalized.hashCode;
    return distinctPalette[hash.abs() % distinctPalette.length];
  }
}
