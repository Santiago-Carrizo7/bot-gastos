import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:3000';
    }
  }

  // Endpoints
  static const String health = '/health';
  static const String me = '/api/me';
  static const String expenses = '/api/expenses';
  static const String summary = '/api/summary';
  static const String analytics = '/api/analytics';
  static const String categories = '/api/categories';
  static const String budgets = '/api/budgets';

  static String expenseDetail(String id) => '/api/expenses/$id';
  static String categoryDetail(String id) => '/api/categories/$id';
  static String categoryDeactivate(String id) => '/api/categories/$id/deactivate';
  static String budgetDetail(String id) => '/api/budgets/$id';
}
