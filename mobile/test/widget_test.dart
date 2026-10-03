import 'package:flutter_test/flutter_test.dart';
import 'package:bot_gastos/core/theme/app_theme.dart';

void main() {
  test('AppTheme inicializa light y dark theme con Material 3', () {
    final light = AppTheme.lightTheme;
    final dark = AppTheme.darkTheme;

    expect(light.useMaterial3, true);
    expect(dark.useMaterial3, true);
  });
}
