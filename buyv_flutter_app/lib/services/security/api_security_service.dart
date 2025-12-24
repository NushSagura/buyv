import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'data_encryption_service.dart';
import 'secure_token_manager.dart';

/// خدمة أمان API
/// توفر حماية شاملة لطلبات API مع التوقيع والتشفير
class APISecurityService {
  static const String _secretKey = 'your_secret_key_here'; // يجب تغييرها في الإنتاج
  static const int _maxRequestsPerMinute = 60;
  static const int _maxRequestsPerHour = 1000;
  
  static final Map<String, List<DateTime>> _requestHistory = {};
  static final Map<String, int> _failedAttempts = {};
  static const int _maxFailedAttempts = 5;

  /// إنشاء عميل Dio آمن
  static Dio createSecureClient() {
    final dio = Dio();
    
    // إعداد المهلة الزمنية
    dio.options.connectTimeout = Duration(seconds: 30);
    dio.options.receiveTimeout = Duration(seconds: 30);
    dio.options.sendTimeout = Duration(seconds: 30);
    
    // إضافة interceptors للأمان
    dio.interceptors.add(_SecurityInterceptor());
    dio.interceptors.add(_RateLimitInterceptor());
    dio.interceptors.add(_AuthenticationInterceptor());
    dio.interceptors.add(_LoggingInterceptor());
    
    return dio;
  }

  /// توقيع الطلب
  static String signRequest({
    required String method,
    required String path,
    required String timestamp,
    String? body,
  }) {
    final payload = '$method$path$timestamp${body ?? ''}';
    final key = utf8.encode(_secretKey);
    final message = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(message);
    return digest.toString();
  }

  /// إنشاء headers آمنة
  static Future<Map<String, String>> getSecureHeaders({
    String? body,
    String? method = 'GET',
    String? path = '',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = _generateNonce();
    final signature = signRequest(
      method: method ?? 'GET',
      path: path ?? '',
      timestamp: timestamp,
      body: body,
    );
    
    final accessToken = await SecureTokenManager.getAccessToken();
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Timestamp': timestamp,
      'X-Nonce': nonce,
      'X-Signature': signature,
      'X-API-Version': '1.0',
      'User-Agent': 'BuyV-Flutter/1.0.0',
    };
    
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    
    // إضافة CJ API headers إذا كان الطلب لـ CJ
    if (path?.contains('cj') == true) {
      headers['CJ-Access-Token'] = accessToken ?? '';
    }
    
    return headers;
  }

  /// التحقق من معدل الطلبات
  static bool checkRateLimit(String endpoint) {
    final now = DateTime.now();
    final key = endpoint;
    
    // إنشاء قائمة جديدة إذا لم تكن موجودة
    _requestHistory[key] ??= [];
    
    // إزالة الطلبات القديمة (أكثر من ساعة)
    _requestHistory[key]!.removeWhere(
      (time) => now.difference(time) > Duration(hours: 1),
    );
    
    // التحقق من الحد الأقصى للطلبات في الدقيقة
    final requestsInLastMinute = _requestHistory[key]!
        .where((time) => now.difference(time) < Duration(minutes: 1))
        .length;
    
    if (requestsInLastMinute >= _maxRequestsPerMinute) {
      return false;
    }
    
    // التحقق من الحد الأقصى للطلبات في الساعة
    if (_requestHistory[key]!.length >= _maxRequestsPerHour) {
      return false;
    }
    
    // إضافة الطلب الحالي
    _requestHistory[key]!.add(now);
    return true;
  }

  /// تسجيل محاولة فاشلة
  static void recordFailedAttempt(String endpoint) {
    _failedAttempts[endpoint] = (_failedAttempts[endpoint] ?? 0) + 1;
  }

  /// التحقق من حالة القفل
  static bool isEndpointLocked(String endpoint) {
    final attempts = _failedAttempts[endpoint] ?? 0;
    return attempts >= _maxFailedAttempts;
  }

  /// إعادة تعيين محاولات الفشل
  static void resetFailedAttempts(String endpoint) {
    _failedAttempts.remove(endpoint);
  }

  /// إنشاء nonce عشوائي
  static String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// تشفير حمولة الطلب
  static Future<String> encryptRequestBody(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    return await DataEncryptionService.encryptText(jsonString);
  }

  /// فك تشفير استجابة API
  static Future<Map<String, dynamic>> decryptResponseBody(String encryptedData) async {
    final decryptedString = await DataEncryptionService.decryptText(encryptedData);
    return jsonDecode(decryptedString) as Map<String, dynamic>;
  }
}

/// Interceptor للأمان
class _SecurityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // إضافة headers الأمان
      final secureHeaders = await APISecurityService.getSecureHeaders(
        body: options.data?.toString(),
        method: options.method,
        path: options.path,
      );
      
      options.headers.addAll(secureHeaders);
      
      // التحقق من حالة القفل
      if (APISecurityService.isEndpointLocked(options.path)) {
        throw DioException(
          requestOptions: options,
          error: 'Endpoint locked due to too many failed attempts',
          type: DioExceptionType.cancel,
        );
      }
      
      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Security check failed: $e',
          type: DioExceptionType.cancel,
        ),
      );
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // إعادة تعيين محاولات الفشل عند النجاح
    APISecurityService.resetFailedAttempts(response.requestOptions.path);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // تسجيل محاولة فاشلة
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      APISecurityService.recordFailedAttempt(err.requestOptions.path);
    }
    
    handler.next(err);
  }
}

/// Interceptor لمعدل الطلبات
class _RateLimitInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!APISecurityService.checkRateLimit(options.path)) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Rate limit exceeded',
          type: DioExceptionType.cancel,
        ),
      );
      return;
    }
    
    handler.next(options);
  }
}

/// Interceptor للمصادقة
class _AuthenticationInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // التحقق من صحة الرمز المميز
    if (options.headers['Authorization'] != null) {
      final isValid = await SecureTokenManager.isAccessTokenValid();
      if (!isValid) {
        // محاولة تجديد الرمز
        final refreshToken = await SecureTokenManager.getRefreshToken();
        if (refreshToken != null) {
          // هنا يجب إضافة منطق تجديد الرمز
          // await _refreshAccessToken(refreshToken);
        } else {
          // إزالة الرموز غير الصالحة
          await SecureTokenManager.clearAllTokens();
          handler.reject(
            DioException(
              requestOptions: options,
              error: 'Authentication required',
              type: DioExceptionType.cancel,
            ),
          );
          return;
        }
      }
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // التعامل مع أخطاء المصادقة
    if (err.response?.statusCode == 401) {
      await SecureTokenManager.clearAllTokens();
    }
    
    handler.next(err);
  }
}

/// Interceptor للتسجيل الآمن
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // لا نسجل البيانات الحساسة
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

/// استثناءات الأمان
class SecurityException implements Exception {
  final String message;
  final String code;
  
  SecurityException(this.message, this.code);
  
  @override
  String toString() => 'SecurityException: $message (Code: $code)';
}

class RateLimitException extends SecurityException {
  RateLimitException() : super('Rate limit exceeded', 'RATE_LIMIT');
}

class AuthenticationException extends SecurityException {
  AuthenticationException() : super('Authentication failed', 'AUTH_FAILED');
}

class SignatureException extends SecurityException {
  SignatureException() : super('Invalid request signature', 'INVALID_SIGNATURE');
}