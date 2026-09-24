import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Thin wrapper around flutter_secure_storage so the rest of the app
/// never touches the plugin directly (keeps it swappable/testable).
class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService instance = SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveAuthToken(String token) =>
      _storage.write(key: AppConstants.storageKeyAuthToken, value: token);

  Future<String?> getAuthToken() => _storage.read(key: AppConstants.storageKeyAuthToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: AppConstants.storageKeyRefreshToken, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: AppConstants.storageKeyRefreshToken);

  Future<void> saveUserId(String userId) =>
      _storage.write(key: AppConstants.storageKeyUserId, value: userId);

  Future<String?> getUserId() => _storage.read(key: AppConstants.storageKeyUserId);

  Future<void> saveUserRole(String role) =>
      _storage.write(key: AppConstants.storageKeyUserRole, value: role);

  Future<String?> getUserRole() => _storage.read(key: AppConstants.storageKeyUserRole);

  Future<void> clearAll() => _storage.deleteAll();
}
