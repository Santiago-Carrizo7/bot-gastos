class ApiEndpoints {
  static const String defaultBaseUrl = 'https://bot-gastos-nezr.onrender.com';

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
