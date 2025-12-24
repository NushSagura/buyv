import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'data_encryption_service.dart';

/// مدير آمن للرموز المميزة (Tokens)
/// يوفر تخزين وإدارة آمنة لرموز الوصول ورموز التحديث
class SecureTokenManager {
  static const String _accessTokenKey = 'secure_access_token';
  static const String _refreshTokenKey = 'secure_refresh_token';
  static const String _tokenExpiryKey = 'token_expiry_time';
  static const String _sessionIdKey = 'session_id';
  static const String _lastActivityKey = 'last_activity';
  
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

  /// تخزين رمز الوصول بشكل آمن
  static Future<void> storeAccessToken({
    required String token,
    required String refreshToken,
    required DateTime expiryTime,
  }) async {
    try {
      // تشفير الرموز
      final encryptedAccessToken = await DataEncryptionService.encryptAccessToken(token);
      final encryptedRefreshToken = await DataEncryptionService.encryptText(refreshToken);
      
      // إنشاء معرف جلسة جديد
      final sessionId = _generateSessionId();
      
      // تخزين البيانات
      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: encryptedAccessToken),
        _secureStorage.write(key: _refreshTokenKey, value: encryptedRefreshToken),
        _secureStorage.write(key: _tokenExpiryKey, value: expiryTime.millisecondsSinceEpoch.toString()),
        _secureStorage.write(key: _sessionIdKey, value: sessionId),
        _updateLastActivity(),
      ]);
      
      // تم تخزين الرموز بنجاح
    } catch (e) {
      throw Exception('فشل في تخزين الرموز: $e');
    }
  }

  /// استرداد رمز الوصول
  static Future<String?> getAccessToken() async {
    try {
      final encrypted = await _secureStorage.read(key: _accessTokenKey);
      if (encrypted == null) return null;

      // فك تشفير رمز الوصول قبل الاستخدام
      final decrypted = await DataEncryptionService.decryptAccessToken(encrypted);
      await _updateLastActivity();
      return decrypted;
    } catch (e) {
      // خطأ في استرداد رمز الوصول
      return null;
    }
  }

  /// استرداد رمز التحديث
  static Future<String?> getRefreshToken() async {
    try {
      final encrypted = await _secureStorage.read(key: _refreshTokenKey);
      if (encrypted == null) return null;

      // فك تشفير رمز التحديث قبل الاستخدام
      final decrypted = await DataEncryptionService.decryptText(encrypted);
      await _updateLastActivity();
      return decrypted;
    } catch (e) {
      // خطأ في استرداد رمز التحديث
      return null;
    }
  }

  /// التحقق من صحة رمز الوصول
  static Future<bool> isAccessTokenValid() async {
    try {
      // التحقق من وجود الرمز
      final token = await getAccessToken();
      if (token == null) return false;
      
      // التحقق من انتهاء الصلاحية
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryString == null) return false;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
      final now = DateTime.now();
      
      // إضافة هامش أمان 5 دقائق قبل انتهاء الصلاحية
      final safetyMargin = Duration(minutes: 5);
      
      return now.isBefore(expiryTime.subtract(safetyMargin));
    } catch (e) {
      // خطأ في التحقق من صحة الرمز
      return false;
    }
  }

  /// تحديث رمز الوصول
  static Future<void> updateAccessToken({
    required String newToken,
    required DateTime newExpiryTime,
  }) async {
    try {
      final encryptedToken = await DataEncryptionService.encryptAccessToken(newToken);
      
      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: encryptedToken),
        _secureStorage.write(key: _tokenExpiryKey, value: newExpiryTime.millisecondsSinceEpoch.toString()),
        _updateLastActivity(),
      ]);
      
      // تم تحديث رمز الوصول بنجاح
    } catch (e) {
      throw Exception('فشل في تحديث رمز الوصول: $e');
    }
  }

  /// مسح جميع الرموز
  static Future<void> clearAllTokens() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _tokenExpiryKey),
        _secureStorage.delete(key: _sessionIdKey),
        _secureStorage.delete(key: _lastActivityKey),
      ]);
      
      // تم مسح جميع الرموز بنجاح
    } catch (e) {
      // خطأ في مسح الرموز
    }
  }

  /// التحقق من صحة الجلسة
  static Future<bool> _isSessionValid() async {
    try {
      // التحقق من وجود معرف الجلسة
      final sessionId = await _secureStorage.read(key: _sessionIdKey);
      if (sessionId == null) return false;
      
      // التحقق من آخر نشاط (انتهاء الجلسة بعد 24 ساعة من عدم النشاط)
      final lastActivityString = await _secureStorage.read(key: _lastActivityKey);
      if (lastActivityString == null) return false;
      
      final lastActivity = DateTime.fromMillisecondsSinceEpoch(int.parse(lastActivityString));
      final now = DateTime.now();
      final sessionTimeout = Duration(hours: 24);
      
      return now.difference(lastActivity) < sessionTimeout;
    } catch (e) {
      return false;
    }
  }

  /// تحديث آخر نشاط
  static Future<void> _updateLastActivity() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      await _secureStorage.write(key: _lastActivityKey, value: now);
    } catch (e) {
      // خطأ في تحديث آخر نشاط
    }
  }

  /// تحديث آخر نشاط (طريقة عامة)
  static Future<void> updateLastActivity() async {
    await _updateLastActivity();
  }

  /// تخزين الرموز المميزة
  static Future<void> storeTokens(String accessToken, String refreshToken) async {
    final expiryTime = DateTime.now().add(Duration(hours: 1)); // مدة انتهاء افتراضية
    await storeAccessToken(
      token: accessToken,
      refreshToken: refreshToken,
      expiryTime: expiryTime,
    );
  }

  /// تخزين رمز التحديث
  static Future<void> storeRefreshToken(String refreshToken) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      // تم تخزين رمز التحديث بنجاح
    } catch (e) {
      // خطأ في تخزين رمز التحديث
    }
  }

  /// إنشاء معرف جلسة عشوائي
  static String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// الحصول على معلومات الجلسة
  static Future<Map<String, dynamic>?> getSessionInfo() async {
    try {
      final sessionId = await _secureStorage.read(key: _sessionIdKey);
      final lastActivityString = await _secureStorage.read(key: _lastActivityKey);
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
      
      if (sessionId == null || lastActivityString == null) return null;
      
      final lastActivity = DateTime.fromMillisecondsSinceEpoch(int.parse(lastActivityString));
      final tokenExpiry = expiryString != null 
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString))
          : null;
      
      return {
        'sessionId': sessionId,
        'lastActivity': lastActivity.toIso8601String(),
        'tokenExpiry': tokenExpiry?.toIso8601String(),
        'isValid': await _isSessionValid(),
        'tokenValid': await isAccessTokenValid(),
      };
    } catch (e) {
      return null;
    }
  }

  /// فرض انتهاء الجلسة
  static Future<void> forceSessionExpiry() async {
    await clearAllTokens();
    // تم إنهاء الجلسة بالقوة
  }

  /// تجديد الجلسة
  static Future<void> refreshSession() async {
    await _updateLastActivity();
    final newSessionId = _generateSessionId();
    await _secureStorage.write(key: _sessionIdKey, value: newSessionId);
    // تم تجديد الجلسة
  }

  /// التحقق من وجود رموز محفوظة
  static Future<bool> hasStoredTokens() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      return accessToken != null && refreshToken != null;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على وقت انتهاء الرمز
  static Future<DateTime?> getTokenExpiryTime() async {
    try {
      final expiryString = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryString == null) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
    } catch (e) {
      return null;
    }
  }

  /// التحقق من أمان التخزين
  static Future<bool> verifyStorageSecurity() async {
    try {
      // اختبار تشفير وفك تشفير
      const testData = 'test_security_data';
      final encrypted = await DataEncryptionService.encryptText(testData);
      final decrypted = await DataEncryptionService.decryptText(encrypted);
      
      return decrypted == testData;
    } catch (e) {
      return false;
    }
  }

  /// تصدير بيانات الجلسة للنسخ الاحتياطي (مشفرة)
  static Future<String?> exportSessionData() async {
    try {
      final sessionInfo = await getSessionInfo();
      if (sessionInfo == null) return null;
      
      final exportData = {
        'sessionInfo': sessionInfo,
        'exportedAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
      };
      
      return await DataEncryptionService.encryptText(jsonEncode(exportData));
    } catch (e) {
      return null;
    }
  }
}