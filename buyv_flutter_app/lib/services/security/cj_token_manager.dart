import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'data_encryption_service.dart';

/// مدير رموز خاص بـ CJ Dropshipping لتجنّب تعارضه مع توكن الباكند
class CJTokenManager {
  static const String _accessTokenKey = 'cj_access_token';
  static const String _refreshTokenKey = 'cj_refresh_token';
  static const String _tokenExpiryKey = 'cj_token_expiry_time';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  static Future<void> storeAccessToken({
    required String token,
    required String refreshToken,
    required DateTime expiryTime,
  }) async {
    final encryptedAccessToken = await DataEncryptionService.encryptText(token);
    final encryptedRefreshToken = await DataEncryptionService.encryptText(refreshToken);
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: encryptedAccessToken),
      _secureStorage.write(key: _refreshTokenKey, value: encryptedRefreshToken),
      _secureStorage.write(key: _tokenExpiryKey, value: expiryTime.millisecondsSinceEpoch.toString()),
    ]);
  }

  static Future<String?> getAccessToken() async {
    final encrypted = await _secureStorage.read(key: _accessTokenKey);
    if (encrypted == null) return null;
    return await DataEncryptionService.decryptText(encrypted);
  }

  static Future<String?> getRefreshToken() async {
    final encrypted = await _secureStorage.read(key: _refreshTokenKey);
    if (encrypted == null) return null;
    return await DataEncryptionService.decryptText(encrypted);
  }

  static Future<bool> isAccessTokenValid() async {
    final token = await getAccessToken();
    if (token == null) return false;
    final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
    if (expiryString == null) return false;
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
    final safetyMargin = Duration(minutes: 5);
    return DateTime.now().isBefore(expiryTime.subtract(safetyMargin));
  }

  static Future<void> updateAccessToken({
    required String newToken,
    required DateTime newExpiryTime,
  }) async {
    final encryptedToken = await DataEncryptionService.encryptText(newToken);
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: encryptedToken),
      _secureStorage.write(key: _tokenExpiryKey, value: newExpiryTime.millisecondsSinceEpoch.toString()),
    ]);
  }

  static Future<void> clear() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _tokenExpiryKey),
    ]);
  }
}