import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_error_handler.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final ApiClient apiClient;

  BudgetRepository({required this.apiClient});

  Future<List<BudgetModel>> getBudgets() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.budgets);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list
          .map((item) => BudgetModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<BudgetModel> setBudget({
    required String category,
    required double amount,
    String currency = 'ARS',
  }) async {
    try {
      final body = <String, dynamic>{
        'category': category.trim().toLowerCase(),
        'amount': amount,
        'currency': currency,
      };

      final response = await apiClient.dio.post(
        ApiEndpoints.budgets,
        data: body,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return BudgetModel.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await apiClient.dio.delete(ApiEndpoints.budgetDetail(id));
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
