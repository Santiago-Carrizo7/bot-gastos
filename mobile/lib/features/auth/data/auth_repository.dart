import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_error_handler.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  AuthRepository({required this.apiClient, required this.storageService});

  /// Verifica el token contra el backend y lo persiste si es válido
  Future<UserModel> verifyAndSaveToken(String token) async {
    try {
      final cleanToken = token.trim();
      final response = await apiClient.dio.get(
        ApiEndpoints.me,
        options: Options(
          headers: {
            'Authorization': 'Bearer $cleanToken',
          },
        ),
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data);

      await storageService.saveAuthToken(cleanToken);
      await storageService.saveUserInfo(userId: user.id, telegramId: user.telegramId);

      return user;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  /// Consulta el usuario actual usando el token almacenado
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.me);
      final data = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  /// Desvincula la cuenta de Telegram localmente
  Future<void> unlink() async {
    await storageService.clearAll();
  }
}
