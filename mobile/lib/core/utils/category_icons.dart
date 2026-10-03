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

  static Color getColorForCategory(String categoryName) {
    final hash = categoryName.toLowerCase().hashCode;
    final index = hash.abs() % _colors.length;
    return _colors[index];
  }

  static const List<Color> _colors = [
    Color(0xFF0D9488), // Teal
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF97316), // Orange
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF06B6D4), // Cyan
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Light Teal
  ];
}
