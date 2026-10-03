import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/budget_repository.dart';
import '../models/budget_model.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BudgetRepository(apiClient: apiClient);
});

final budgetsListProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getBudgets();
});
