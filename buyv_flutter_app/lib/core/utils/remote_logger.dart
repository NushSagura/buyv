import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../config/environment_config.dart';

/// 📡 Remote Logger - Système de logging corrélé Frontend ↔ Backend
/// 
/// Format: [HH:MM:SS.mmm] 👤 Client: action → 📱 Flutter: event → 🔧 Backend: API
/// 
/// Usage:
/// ```dart
/// final actionId = RemoteLogger.logUserAction('Tap video in profile');
/// RemoteLogger.logFlutterEvent('Navigate to /reels', actionId: actionId);
/// RemoteLogger.logBackendCall('GET /posts', actionId: actionId);
/// ```
class RemoteLogger {
  static final List<LogEntry> _logs = [];
  static const int _maxLogs = 200; // Augmenté pour meilleures traces

  /// Active/désactive le logging en production
  static const bool enableProductionLogs = true;
  
  /// UUID generator pour correlation IDs
  static const _uuid = Uuid();

  /// Log une ACTION CLIENT (ce que l'utilisateur fait)
  /// Retourne un actionId pour tracer tout le flow
  static String logUserAction(
    String action, {
    Map<String, dynamic>? context,
  }) {
    final actionId = _uuid.v4().substring(0, 8); // Short ID
    log(
      '👤 CLIENT: $action',
      level: LogLevel.info,
      data: {
        'actionId': actionId,
        'type': 'USER_ACTION',
        if (context != null) ...context,
      },
    );
    return actionId;
  }

  /// Log un ÉVÉNEMENT FLUTTER (ce que l'app fait)
  static void logFlutterEvent(
    String event, {
    String? actionId,
    Map<String, dynamic>? data,
  }) {
    log(
      '📱 FLUTTER: $event',
      level: LogLevel.debug,
      data: {
        if (actionId != null) 'actionId': actionId,
        'type': 'FLUTTER_EVENT',
        if (data != null) ...data,
      },
    );
  }

  /// Log un APPEL BACKEND (requête API)
  static void logBackendCall(
    String endpoint, {
    String? actionId,
    String method = 'GET',
    Map<String, dynamic>? data,
  }) {
    log(
      '🔧 BACKEND: $method $endpoint',
      level: LogLevel.debug,
      data: {
        if (actionId != null) 'actionId': actionId,
        'type': 'BACKEND_CALL',
        'method': method,
        if (data != null) ...data,
      },
    );
  }

  /// Log un RÉSULTAT BACKEND (réponse API)
  static void logBackendResponse(
    String endpoint, {
    String? actionId,
    int? statusCode,
    Map<String, dynamic>? data,
  }) {
    log(
      '✅ BACKEND RESPONSE: $endpoint',
      level: LogLevel.info,
      data: {
        if (actionId != null) 'actionId': actionId,
        'type': 'BACKEND_RESPONSE',
        if (statusCode != null) 'statusCode': statusCode,
        if (data != null) ...data,
      },
    );
  }

  /// Log un message générique
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? data,
  }) {
    if (!enableProductionLogs && kReleaseMode) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      data: data,
    );

    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0); // Remove oldest
    }

    // Print to console (visible in adb logcat)
    final prefix = _getLevelPrefix(level);
    final timeStr = _formatTimestamp(entry.timestamp);
    final dataStr = data != null ? ' | ${_formatData(data)}' : '';
    debugPrint('$timeStr $prefix $message$dataStr');
  }

  /// Log une erreur
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    log(
      message,
      level: LogLevel.error,
      data: {
        if (data != null) ...data,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      },
    );
  }

  /// Log une information de debug vidéo
  static void videoLog(String message, {Map<String, dynamic>? data}) {
    log('🎥 VIDEO: $message', level: LogLevel.debug, data: data);
  }

  /// Récupère tous les logs (pour affichage in-app)
  static List<LogEntry> getLogs() => List.unmodifiable(_logs);

  /// Récupère les logs en texte pour partage
  static String getLogsAsText() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('📋 BUYV APP LOGS - Corrélation Frontend ↔ Backend');
    buffer.writeln('Device: ${_getDeviceInfo()}');
    buffer.writeln('Mode: ${EnvironmentConfig.isDevelopment ? "DEV" : "PROD"}');
    buffer.writeln('═══════════════════════════════════════\n');

    for (final log in _logs) {
      buffer.writeln(log.toString());
    }

    buffer.writeln('\n═══════════════════════════════════════');
    buffer.writeln('Format: [HH:MM:SS.mmm] Type: Message | actionId');
    buffer.writeln('Types: 👤 CLIENT → 📱 FLUTTER → 🔧 BACKEND → ✅ RESPONSE');

    return buffer.toString();
  }

  /// Efface tous les logs
  static void clear() {
    _logs.clear();
  }

  static String _formatTimestamp(DateTime time) {
    return '[${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}]';
  }

  static String _formatData(Map<String, dynamic> data) {
    final actionId = data['actionId'];
    final type = data['type'];
    final filtered = Map<String, dynamic>.from(data)
      ..remove('actionId')
      ..remove('type');
    
    final parts = <String>[];
    if (actionId != null) parts.add('ID:$actionId');
    if (filtered.isNotEmpty) parts.add(filtered.toString());
    
    return parts.join(' ');
  }

  static String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  static String _getDeviceInfo() {
    // Simplified - can be enhanced with device_info_plus package
    return kIsWeb ? 'Web' : 'Mobile';
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? data;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.data,
  });

  @override
  String toString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    final dataStr = data != null && data!.isNotEmpty ? ' | $data' : '';
    return '[$timeStr] ${_levelToString(level)}: $message$dataStr';
  }

  String _levelToString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}
