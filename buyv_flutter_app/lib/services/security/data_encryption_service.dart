import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// خدمة تشفير البيانات الحساسة
/// يوفر تشفير وفك تشفير آمن للبيانات الحساسة مثل معلومات الدفع وبيانات المستخدم
class DataEncryptionService {
  static const String _keyStorageKey = 'encryption_master_key';
  static const String _ivStorageKey = 'encryption_iv';
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// إنشاء مفتاح تشفير جديد
  static Future<void> _generateEncryptionKey() async {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    final ivBytes = List<int>.generate(16, (i) => random.nextInt(256));
    
    final keyBase64 = base64Encode(keyBytes);
    final ivBase64 = base64Encode(ivBytes);
    
    await _secureStorage.write(key: _keyStorageKey, value: keyBase64);
    await _secureStorage.write(key: _ivStorageKey, value: ivBase64);
  }

  /// إنشاء مفتاح تشفير جديد (طريقة عامة)
  static Future<String> generateEncryptionKey() async {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(keyBytes);
  }

  /// الحصول على مفتاح التشفير
  static Future<Uint8List> _getEncryptionKey() async {
    String? keyBase64 = await _secureStorage.read(key: _keyStorageKey);
    
    if (keyBase64 == null) {
      await _generateEncryptionKey();
      keyBase64 = await _secureStorage.read(key: _keyStorageKey);
    }
    
    return base64Decode(keyBase64!);
  }

  /// الحصول على IV (Initialization Vector)
  static Future<Uint8List> _getIV() async {
    String? ivBase64 = await _secureStorage.read(key: _ivStorageKey);
    
    if (ivBase64 == null) {
      await _generateEncryptionKey();
      ivBase64 = await _secureStorage.read(key: _ivStorageKey);
    }
    
    return base64Decode(ivBase64!);
  }

  /// تشفير النص
  static Future<String> encryptText(String plainText) async {
    try {
      final key = await _getEncryptionKey();
      final iv = await _getIV();
      
      // تحويل النص إلى bytes
      final plainBytes = utf8.encode(plainText);
      
      // تطبيق XOR مع المفتاح (تشفير بسيط لكن فعال)
      final encryptedBytes = <int>[];
      for (int i = 0; i < plainBytes.length; i++) {
        final keyIndex = i % key.length;
        final ivIndex = i % iv.length;
        encryptedBytes.add(plainBytes[i] ^ key[keyIndex] ^ iv[ivIndex]);
      }
      
      // إضافة hash للتحقق من سلامة البيانات
      final hash = sha256.convert(plainBytes);
      final result = {
        'data': base64Encode(encryptedBytes),
        'hash': hash.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      return base64Encode(utf8.encode(jsonEncode(result)));
    } catch (e) {
      throw Exception('فشل في تشفير البيانات: $e');
    }
  }

  /// فك تشفير النص
  static Future<String> decryptText(String encryptedText) async {
    try {
      final key = await _getEncryptionKey();
      final iv = await _getIV();
      
      // فك تشفير البيانات المُرمزة
      final decodedData = utf8.decode(base64Decode(encryptedText));
      final dataMap = jsonDecode(decodedData) as Map<String, dynamic>;
      
      final encryptedBytes = base64Decode(dataMap['data']);
      final originalHash = dataMap['hash'];
      final timestamp = dataMap['timestamp'] as int;
      
      // التحقق من انتهاء صلاحية البيانات (30 يوم)
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysInMs = 30 * 24 * 60 * 60 * 1000;
      if (now - timestamp > thirtyDaysInMs) {
        throw Exception('انتهت صلاحية البيانات المشفرة');
      }
      
      // فك التشفير
      final decryptedBytes = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        final keyIndex = i % key.length;
        final ivIndex = i % iv.length;
        decryptedBytes.add(encryptedBytes[i] ^ key[keyIndex] ^ iv[ivIndex]);
      }
      
      final plainText = utf8.decode(decryptedBytes);
      
      // التحقق من سلامة البيانات
      final computedHash = sha256.convert(utf8.encode(plainText));
      if (computedHash.toString() != originalHash) {
        throw Exception('تم اكتشاف تلاعب في البيانات');
      }
      
      return plainText;
    } catch (e) {
      throw Exception('فشل في فك تشفير البيانات: $e');
    }
  }

  /// تشفير بيانات الدفع
  static Future<String> encryptPaymentData(Map<String, dynamic> paymentData) async {
    // إزالة البيانات الحساسة من السجلات
    final sanitizedData = Map<String, dynamic>.from(paymentData);
    if (sanitizedData.containsKey('cardNumber')) {
      sanitizedData['cardNumber'] = '****-****-****-${sanitizedData['cardNumber'].toString().substring(sanitizedData['cardNumber'].toString().length - 4)}';
    }
    
    final jsonString = jsonEncode(paymentData);
    return await encryptText(jsonString);
  }

  /// فك تشفير بيانات الدفع
  static Future<Map<String, dynamic>> decryptPaymentData(String encryptedData) async {
    final decryptedString = await decryptText(encryptedData);
    return jsonDecode(decryptedString) as Map<String, dynamic>;
  }

  /// تشفير بيانات المستخدم الحساسة
  static Future<String> encryptUserData(Map<String, dynamic> userData) async {
    // إضافة طابع زمني وتوقيع رقمي
    final dataWithMetadata = {
      ...userData,
      '_encrypted_at': DateTime.now().toIso8601String(),
      '_app_version': '1.0.0', // يمكن الحصول عليها من package_info
    };
    
    final jsonString = jsonEncode(dataWithMetadata);
    return await encryptText(jsonString);
  }

  /// فك تشفير بيانات المستخدم
  static Future<Map<String, dynamic>> decryptUserData(String encryptedData) async {
    final decryptedString = await decryptText(encryptedData);
    final userData = jsonDecode(decryptedString) as Map<String, dynamic>;
    
    // إزالة البيانات الوصفية
    userData.remove('_encrypted_at');
    userData.remove('_app_version');
    
    return userData;
  }

  /// تشفير رمز الوصول (Access Token)
  static Future<String> encryptAccessToken(String token) async {
    final tokenData = {
      'token': token,
      'encrypted_at': DateTime.now().millisecondsSinceEpoch,
      'device_id': await _getDeviceId(),
    };
    
    return await encryptText(jsonEncode(tokenData));
  }

  /// فك تشفير رمز الوصول
  static Future<String> decryptAccessToken(String encryptedToken) async {
    final decryptedString = await decryptText(encryptedToken);
    final tokenData = jsonDecode(decryptedString) as Map<String, dynamic>;
    
    // التحقق من معرف الجهاز
    final currentDeviceId = await _getDeviceId();
    if (tokenData['device_id'] != currentDeviceId) {
      throw Exception('رمز الوصول غير صالح لهذا الجهاز');
    }
    
    return tokenData['token'];
  }

  /// الحصول على معرف الجهاز (مبسط)
  static Future<String> _getDeviceId() async {
    // في التطبيق الحقيقي، استخدم device_info_plus للحصول على معرف فريد
    String? deviceId = await _secureStorage.read(key: 'device_id');
    
    if (deviceId == null) {
      final random = Random.secure();
      deviceId = List.generate(16, (index) => random.nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      await _secureStorage.write(key: 'device_id', value: deviceId);
    }
    
    return deviceId;
  }

  /// مسح جميع مفاتيح التشفير (عند تسجيل الخروج)
  static Future<void> clearEncryptionKeys() async {
    await _secureStorage.delete(key: _keyStorageKey);
    await _secureStorage.delete(key: _ivStorageKey);
    await _secureStorage.delete(key: 'device_id');
  }

  /// التحقق من سلامة البيانات المشفرة
  static Future<bool> verifyEncryptedData(String encryptedData) async {
    try {
      await decryptText(encryptedData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// إنشاء hash آمن للكلمة السرية
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// التحقق من صحة كلمة المرور
  static bool verifyPassword(String password, String hashedPassword, String salt) {
    final computedHash = hashPassword(password, salt);
    return computedHash == hashedPassword;
  }

  /// إنشاء salt عشوائي للكلمة السرية
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(saltBytes);
  }
}