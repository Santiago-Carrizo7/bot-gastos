import 'package:intl/intl.dart';

class DateFormatter {
  static const List<String> monthNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Ayer';
    } else if (difference == -1) {
      return 'Mañana';
    } else if (difference > 1 && difference < 7) {
      final weekday = DateFormat('EEEE', 'es_AR').format(date);
      return weekday[0].toUpperCase() + weekday.substring(1);
    } else if (date.year == now.year) {
      return DateFormat('d \'de\' MMMM', 'es_AR').format(date);
    } else {
      return DateFormat('d \'de\' MMMM, yyyy', 'es_AR').format(date);
    }
  }

  static String formatFull(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatMonthYear(int year, int month) {
    if (month >= 1 && month <= 12) {
      return '${monthNames[month - 1]} $year';
    }
    return '$month/$year';
  }

  static String getMonthName(int month) {
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return '';
  }

  static String toIsoDateOnly(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
