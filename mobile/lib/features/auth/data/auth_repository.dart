import 'dart:convert';
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

  /// Decodifica el payload base64url generado por /vincular en Telegram
  UserModel _decodeTokenPayload(String token) {
    try {
      final normalized = base64Url.normalize(token.trim());
      final decodedStr = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decodedStr) as Map<String, dynamic>;

      final userId = map['userId']?.toString();
      final telegramId = map['telegramId']?.toString() ?? 'Conectado';

      if (userId == null || userId.isEmpty) {
        throw const FormatException('Token sin userId');
      }

      return UserModel(
        id: userId,
        telegramId: telegramId,
      );
    } catch (_) {
      throw ApiException(
        message: 'El código ingresado no tiene un formato válido. Copialo nuevamente desde /vincular en Telegram.',
        code: 'INVALID_TOKEN_FORMAT',
      );
    }
  }

  /// Verifica el token contra el backend y lo persiste si es válido
  Future<UserModel> verifyAndSaveToken(String token) async {
    final cleanToken = token.trim();
    // 1. Validar formato local del token base64url
    final decodedUser = _decodeTokenPayload(cleanToken);

    try {
      // 2. Intentar validar contra /api/me
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
    } on DioException catch (e) {
      // Si el backend remoto aún no tiene desplegado /api/me (404),
      // validamos conectividad y autenticación contra /api/categories
      if (e.response?.statusCode == 404) {
        try {
          await apiClient.dio.get(
            ApiEndpoints.categories,
            options: Options(
              headers: {
                'Authorization': 'Bearer $cleanToken',
              },
            ),
          );

          await storageService.saveAuthToken(cleanToken);
          await storageService.saveUserInfo(
            userId: decodedUser.id,
            telegramId: decodedUser.telegramId,
          );

          return decodedUser;
        } catch (fallbackErr) {
          throw ApiErrorHandler.handle(fallbackErr);
        }
      }
      throw ApiErrorHandler.handle(e);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  /// Consulta el usuario actual usando el token almacenado
  Future<UserModel> getCurrentUser() async {
    final token = await storageService.getAuthToken();
    if (token == null || token.trim().isEmpty) {
      throw ApiException(message: 'No hay sesión activa', code: 'NO_TOKEN');
    }

    try {
      final response = await apiClient.dio.get(ApiEndpoints.me);
      final data = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback para backend en producción sin /api/me
        try {
          await apiClient.dio.get(ApiEndpoints.categories);
          final decoded = _decodeTokenPayload(token);
          return decoded;
        } catch (fallbackErr) {
          throw ApiErrorHandler.handle(fallbackErr);
        }
      }
      throw ApiErrorHandler.handle(e);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  /// Desvincula la cuenta de Telegram localmente
  Future<void> unlink() async {
    await storageService.clearAll();
  }
}
