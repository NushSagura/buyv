import 'package:flutter/foundation.dart';

/// Centralized logging utility for the app
/// Logs are only shown in debug mode and can be easily disabled for production
class AppLogger {
  static const bool _enableLogs = kDebugMode; // Only log in debug mode
  
  /// Log information message
  static void info(String message, {String? tag}) {
    if (!_enableLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('ℹ️ $prefix $message');
  }
  
  /// Log success message
  static void success(String message, {String? tag}) {
    if (!_enableLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('✅ $prefix $message');
  }
  
  /// Log warning message
  static void warning(String message, {String? tag}) {
    if (!_enableLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('⚠️ $prefix $message');
  }
  
  /// Log error message
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (!_enableLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('❌ $prefix $message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   StackTrace: $stackTrace');
    }
  }
  
  /// Log debug message (most verbose, can be disabled separately)
  static void debug(String message, {String? tag}) {
    if (!_enableLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('🔍 $prefix $message');
  }
  
  /// Log network request
  static void network(String message, {String? tag}) {
    if (!_enableLogs) return;
    final prefix = tag != null ? '[$tag]' : '';
    debugPrint('🌐 $prefix $message');
  }
}
