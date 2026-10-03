import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() => message;
}

class ApiErrorHandler {
  static ApiException handle(dynamic error) {
    if (error is ApiException) {
      return error;
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      if (statusCode == 401) {
        return ApiException(
          message: 'El código de vinculación es inválido o expiró.',
          code: 'UNAUTHORIZED',
          statusCode: 401,
        );
      }

      if (data is Map<String, dynamic>) {
        if (data.containsKey('message') && data['message'] != null) {
          return ApiException(
            message: data['message'].toString(),
            code: data['error']?.toString(),
            statusCode: statusCode,
          );
        }

        if (data.containsKey('details') && data['details'] is List) {
          final issues = (data['details'] as List).join('\n');
          return ApiException(
            message: issues,
            code: data['error']?.toString() ?? 'VALIDATION_ERROR',
            statusCode: statusCode,
          );
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException(
            message: 'Tiempo de espera agotado al comunicar con el servidor.',
            code: 'TIMEOUT',
            statusCode: statusCode,
          );
        case DioExceptionType.connectionError:
          return ApiException(
            message: 'No se pudo conectar al servidor. Verificá tu red y que el backend esté activo.',
            code: 'CONNECTION_ERROR',
            statusCode: statusCode,
          );
        case DioExceptionType.badResponse:
          return ApiException(
            message: 'Respuesta inválida del servidor ($statusCode).',
            code: 'BAD_RESPONSE',
            statusCode: statusCode,
          );
        case DioExceptionType.cancel:
          return ApiException(
            message: 'La solicitud fue cancelada.',
            code: 'CANCELLED',
          );
        default:
          return ApiException(
            message: 'Error de comunicación inesperado.',
            code: 'UNKNOWN_NETWORK_ERROR',
          );
      }
    }

    return ApiException(
      message: error?.toString() ?? 'Ocurrió un error inesperado.',
      code: 'UNEXPECTED_ERROR',
    );
  }
}
