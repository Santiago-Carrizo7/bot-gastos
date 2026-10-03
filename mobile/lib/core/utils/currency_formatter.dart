import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final NumberFormat _formatterWithDecimals = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  static String format(num amount, {String currency = 'ARS', bool showDecimals = false}) {
    final hasDecimals = showDecimals || (amount % 1 != 0);
    final formatted = hasDecimals
        ? _formatterWithDecimals.format(amount)
        : _formatter.format(amount);

    if (currency == 'USD') {
      return 'US$formatted';
    }
    return formatted;
  }
}
