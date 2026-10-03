import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../budgets/providers/budget_providers.dart';
import '../data/expense_repository.dart';
import '../models/expense_model.dart';
import '../models/summary_model.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExpenseRepository(apiClient: apiClient);
});

/// Mes seleccionado actualmente para navegación en Home y Estadísticas
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// Resumen mensual del mes seleccionado
final monthlySummaryProvider = FutureProvider<MonthlySummaryModel>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return repo.getMonthlySummary(
    year: selectedDate.year,
    month: selectedDate.month,
  );
});

/// Últimos 5 gastos para la pantalla de inicio
final recentExpensesProvider = FutureProvider<List<ExpenseModel>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.getExpenses(limit: 5);
});

/// Filtros para la pantalla completa de gastos
class ExpenseFilter {
  final String? category;
  final String? search;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExpenseFilter({
    this.category,
    this.search,
    this.startDate,
    this.endDate,
  });

  ExpenseFilter copyWith({
    String? category,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    bool clearCategory = false,
    bool clearSearch = false,
    bool clearDates = false,
  }) {
    return ExpenseFilter(
      category: clearCategory ? null : (category ?? this.category),
      search: clearSearch ? null : (search ?? this.search),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

final expenseFilterProvider = StateProvider<ExpenseFilter>((ref) {
  return const ExpenseFilter();
});

/// Lista completa filtrada de gastos
final expensesListProvider = FutureProvider<List<ExpenseModel>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final filter = ref.watch(expenseFilterProvider);

  return repo.getExpenses(
    limit: 100,
    category: filter.category,
    search: filter.search,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

/// Analítica histórica y desglose mensual para la pantalla de estadísticas
final analyticsProvider = FutureProvider<AnalyticsModel>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  return repo.getAnalytics(
    year: selectedDate.year,
    month: selectedDate.month,
    monthsCount: 6,
  );
});

/// Helper para invalidar consultas tras crear, editar o eliminar un gasto
void refreshAllExpenseData(WidgetRef ref) {
  ref.invalidate(monthlySummaryProvider);
  ref.invalidate(recentExpensesProvider);
  ref.invalidate(expensesListProvider);
  ref.invalidate(analyticsProvider);
  ref.invalidate(budgetsListProvider);
}
