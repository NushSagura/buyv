import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'security/data_encryption_service.dart';

/// خدمة التخزين الآمن للبيانات الحساسة
/// تدمج بين FlutterSecureStorage و Hive مع التشفير
class SecureStorageService {
  static const String _keyPrefix = 'buyv_secure_';
  static const String _encryptionKeyName = '${_keyPrefix}encryption_key';
  static const String _userDataBoxName = 'secure_user_data';
  static const String _settingsBoxName = 'secure_settings';
  
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  static Box<String>? _userDataBox;
  static Box<String>? _settingsBox;
  static String? _encryptionKey;
  
  /// تهيئة الخدمة
  static Future<void> initialize() async {
    try {
      // الحصول على مفتاح التشفير أو إنشاء واحد جديد
      _encryptionKey = await _secureStorage.read(key: _encryptionKeyName);
      if (_encryptionKey == null) {
        _encryptionKey = await DataEncryptionService.generateEncryptionKey();
        await _secureStorage.write(key: _encryptionKeyName, value: _encryptionKey!);
      }
      
      // تهيئة صناديق Hive المشفرة
      final encryptionKeyBytes = base64Decode(_encryptionKey!);
      final encryptionKey = HiveAesCipher(encryptionKeyBytes);
      
      _userDataBox = await Hive.openBox<String>(
        _userDataBoxName,
        encryptionCipher: encryptionKey,
      );
      
      _settingsBox = await Hive.openBox<String>(
        _settingsBoxName,
        encryptionCipher: encryptionKey,
      );
      
      if (kDebugMode) {
        print('🔐 SecureStorageService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SecureStorageService initialization failed: $e');
      }
      rethrow;
    }
  }
  
  /// تخزين بيانات المستخدم بشكل آمن
  static Future<void> storeUserData(String key, Map<String, dynamic> data) async {
    await _ensureInitialized();
    
    try {
      final encryptedData = await DataEncryptionService.encryptUserData(data);
      await _userDataBox!.put('$_keyPrefix$key', encryptedData);
      
      if (kDebugMode) {
        print('🔐 User data stored securely: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store user data: $e');
      }
      rethrow;
    }
  }
  
  /// استرجاع بيانات المستخدم
  static Future<Map<String, dynamic>?> getUserData(String key) async {
    await _ensureInitialized();
    
    try {
      final encryptedData = _userDataBox!.get('$_keyPrefix$key');
      if (encryptedData == null) return null;
      
      return DataEncryptionService.decryptUserData(encryptedData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to retrieve user data: $e');
      }
      return null;
    }
  }
  
  /// تخزين الإعدادات بشكل آمن
  static Future<void> storeSetting(String key, dynamic value) async {
    await _ensureInitialized();
    
    try {
      final jsonValue = jsonEncode(value);
      final encryptedValue = await DataEncryptionService.encryptText(jsonValue);
      await _settingsBox!.put('$_keyPrefix$key', encryptedValue);
      
      if (kDebugMode) {
        print('🔐 Setting stored securely: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store setting: $e');
      }
      rethrow;
    }
  }
  
  /// استرجاع الإعدادات
  static Future<T?> getSetting<T>(String key) async {
    await _ensureInitialized();
    
    try {
      final encryptedValue = _settingsBox!.get('$_keyPrefix$key');
      if (encryptedValue == null) return null;
      
      final decryptedValue = await DataEncryptionService.decryptText(encryptedValue);
      return jsonDecode(decryptedValue) as T;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to retrieve setting: $e');
      }
      return null;
    }
  }
  
  /// تخزين كلمة مرور مشفرة
  static Future<void> storePassword(String key, String password) async {
    try {
      final salt = DataEncryptionService.generateSalt();
      final hashedPassword = DataEncryptionService.hashPassword(password, salt);
      
      // تخزين كلمة المرور المشفرة والـ salt
      await _secureStorage.write(key: '${_keyPrefix}password_$key', value: hashedPassword);
      await _secureStorage.write(key: '${_keyPrefix}salt_$key', value: salt);
      
      if (kDebugMode) {
        print('🔐 Password stored securely: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store password: $e');
      }
      rethrow;
    }
  }
  
  /// التحقق من كلمة المرور
  static Future<bool> verifyPassword(String key, String password) async {
    try {
      final storedHash = await _secureStorage.read(key: '${_keyPrefix}password_$key');
      final storedSalt = await _secureStorage.read(key: '${_keyPrefix}salt_$key');
      
      if (storedHash == null || storedSalt == null) return false;
      
      return DataEncryptionService.verifyPassword(password, storedHash, storedSalt);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to verify password: $e');
      }
      return false;
    }
  }
  
  /// تخزين بيانات الدفع بشكل آمن
  static Future<void> storePaymentData(String key, Map<String, dynamic> paymentData) async {
    try {
      final encryptedData = await DataEncryptionService.encryptPaymentData(paymentData);
      await _secureStorage.write(key: '${_keyPrefix}payment_$key', value: encryptedData);
      
      if (kDebugMode) {
        print('🔐 Payment data stored securely: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to store payment data: $e');
      }
      rethrow;
    }
  }
  
  /// استرجاع بيانات الدفع
  static Future<Map<String, dynamic>?> getPaymentData(String key) async {
    try {
      final encryptedData = await _secureStorage.read(key: '${_keyPrefix}payment_$key');
      if (encryptedData == null) return null;
      
      return await DataEncryptionService.decryptPaymentData(encryptedData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to retrieve payment data: $e');
      }
      return null;
    }
  }
  
  /// حذف بيانات محددة
  static Future<void> deleteData(String key) async {
    await _ensureInitialized();
    
    try {
      await _userDataBox!.delete('$_keyPrefix$key');
      await _settingsBox!.delete('$_keyPrefix$key');
      await _secureStorage.delete(key: '$_keyPrefix$key');
      await _secureStorage.delete(key: '${_keyPrefix}password_$key');
      await _secureStorage.delete(key: '${_keyPrefix}payment_$key');
      
      if (kDebugMode) {
        print('🗑️ Data deleted: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete data: $e');
      }
    }
  }
  
  /// مسح جميع البيانات الآمنة
  static Future<void> clearAllData() async {
    await _ensureInitialized();
    
    try {
      await _userDataBox!.clear();
      await _settingsBox!.clear();
      await _secureStorage.deleteAll();
      
      if (kDebugMode) {
        print('🗑️ All secure data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear all data: $e');
      }
    }
  }
  
  /// الحصول على إحصائيات التخزين
  static Future<Map<String, dynamic>> getStorageStats() async {
    await _ensureInitialized();
    
    try {
      final userDataCount = _userDataBox!.length;
      final settingsCount = _settingsBox!.length;
      final secureStorageKeys = await _secureStorage.readAll();
      final secureStorageCount = secureStorageKeys.keys
          .where((key) => key.startsWith(_keyPrefix))
          .length;
      
      return {
        'userDataEntries': userDataCount,
        'settingsEntries': settingsCount,
        'secureStorageEntries': secureStorageCount,
        'totalEntries': userDataCount + settingsCount + secureStorageCount,
        'isEncrypted': true,
        'encryptionAlgorithm': 'AES-256-GCM',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get storage stats: $e');
      }
      return {
        'error': e.toString(),
      };
    }
  }
  
  /// التأكد من تهيئة الخدمة
  static Future<void> _ensureInitialized() async {
    if (_userDataBox == null || _settingsBox == null || _encryptionKey == null) {
      await initialize();
    }
  }
  
  /// إغلاق الخدمة وتنظيف الموارد
  static Future<void> dispose() async {
    try {
      await _userDataBox?.close();
      await _settingsBox?.close();
      _userDataBox = null;
      _settingsBox = null;
      _encryptionKey = null;
      
      if (kDebugMode) {
        print('🔐 SecureStorageService disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to dispose SecureStorageService: $e');
      }
    }
  }
}