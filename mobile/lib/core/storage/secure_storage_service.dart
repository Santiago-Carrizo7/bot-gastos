import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyApiBaseUrl = 'api_base_url';
  static const String _keyTelegramId = 'telegram_id';
  static const String _keyUserId = 'user_id';

  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return _storage.read(key: _keyToken);
  }

  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<void> saveApiBaseUrl(String url) async {
    await _storage.write(key: _keyApiBaseUrl, value: url);
  }

  Future<String?> getApiBaseUrl() async {
    return _storage.read(key: _keyApiBaseUrl);
  }

  Future<void> saveUserInfo({required String userId, required String telegramId}) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyTelegramId, value: telegramId);
  }

  Future<String?> getUserId() async {
    return _storage.read(key: _keyUserId);
  }

  Future<String?> getTelegramId() async {
    return _storage.read(key: _keyTelegramId);
  }

  Future<void> clearAll() async {
    final currentBaseUrl = await getApiBaseUrl();
    await _storage.deleteAll();
    // Preservar la URL personalizada del servidor si fue configurada
    if (currentBaseUrl != null) {
      await saveApiBaseUrl(currentBaseUrl);
    }
  }
}
