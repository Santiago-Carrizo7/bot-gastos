import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_error_handler.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/expense_model.dart';
import '../models/summary_model.dart';

class ExpenseRepository {
  final ApiClient apiClient;

  ExpenseRepository({required this.apiClient});

  Future<List<ExpenseModel>> getExpenses({
    int limit = 50,
    int offset = 0,
    String? category,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await apiClient.dio.get(
        ApiEndpoints.expenses,
        queryParameters: queryParams,
      );

      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list
          .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<ExpenseModel> getExpenseById(String id) async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.expenseDetail(id));
      final data = response.data['data'] as Map<String, dynamic>;
      return ExpenseModel.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<ExpenseModel> createExpense({
    required double amount,
    required String description,
    required String category,
    DateTime? date,
    int installments = 1,
    String currency = 'ARS',
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'description': description.trim(),
        'category': category.trim().toLowerCase(),
        'installments': installments,
        'currency': currency,
      };

      if (date != null) {
        body['date'] = DateFormatter.toIsoDateOnly(date);
      }

      final response = await apiClient.dio.post(
        ApiEndpoints.expenses,
        data: body,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return ExpenseModel.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<ExpenseModel> updateExpense(
    String id, {
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    int? installments,
    String? currency,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (amount != null) body['amount'] = amount;
      if (description != null) body['description'] = description.trim();
      if (category != null) body['category'] = category.trim().toLowerCase();
      if (date != null) body['date'] = DateFormatter.toIsoDateOnly(date);
      if (installments != null) body['installments'] = installments;
      if (currency != null) body['currency'] = currency;

      final response = await apiClient.dio.put(
        ApiEndpoints.expenseDetail(id),
        data: body,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return ExpenseModel.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await apiClient.dio.delete(ApiEndpoints.expenseDetail(id));
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<MonthlySummaryModel> getMonthlySummary({int? year, int? month}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (year != null) queryParams['year'] = year;
      if (month != null) queryParams['month'] = month;

      final response = await apiClient.dio.get(
        ApiEndpoints.summary,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return MonthlySummaryModel.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<AnalyticsModel> getAnalytics({int? year, int? month, int monthsCount = 6}) async {
    try {
      final queryParams = <String, dynamic>{
        'months': monthsCount,
      };
      if (year != null) queryParams['year'] = year;
      if (month != null) queryParams['month'] = month;

      final response = await apiClient.dio.get(
        ApiEndpoints.analytics,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return AnalyticsModel.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
