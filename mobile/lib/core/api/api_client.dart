import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService storageService;

  ApiClient({required this.storageService, Dio? customDio})
      : dio = customDio ?? Dio() {
    dio.options = BaseOptions(
      baseUrl: ApiEndpoints.defaultBaseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Inyectar URL base dinámica
          final customUrl = await storageService.getApiBaseUrl();
          if (customUrl != null && customUrl.trim().isNotEmpty) {
            var clean = customUrl.trim();
            if (clean.endsWith('/')) {
              clean = clean.substring(0, clean.length - 1);
            }
            options.baseUrl = clean;
          } else {
            options.baseUrl = ApiEndpoints.defaultBaseUrl;
          }

          // Inyectar Bearer token si no fue especificado explícitamente en la llamada
          if (!options.headers.containsKey('Authorization')) {
            final token = await storageService.getAuthToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
      ),
    );
  }
}
