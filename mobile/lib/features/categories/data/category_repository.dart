import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_error_handler.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final ApiClient apiClient;

  CategoryRepository({required this.apiClient});

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.categories);
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      return list
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<CategoryModel> createCategory(String name, {String? icon}) async {
    try {
      final body = <String, dynamic>{
        'name': name.trim().toLowerCase(),
      };
      if (icon != null && icon.trim().isNotEmpty) {
        body['icon'] = icon.trim();
      }

      final response = await apiClient.dio.post(
        ApiEndpoints.categories,
        data: body,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return CategoryModel.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<CategoryModel> updateCategory(String id, {String? name, String? icon}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name.trim().toLowerCase();
      if (icon != null) body['icon'] = icon.trim();

      final response = await apiClient.dio.put(
        ApiEndpoints.categoryDetail(id),
        data: body,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return CategoryModel.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<CategoryModel> deactivateCategory(String id) async {
    try {
      final response = await apiClient.dio.patch(
        ApiEndpoints.categoryDeactivate(id),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return CategoryModel.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
