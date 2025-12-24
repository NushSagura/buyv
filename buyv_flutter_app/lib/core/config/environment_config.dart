import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvironmentConfig {
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000';
  static const String _iosSimulatorUrl = 'http://localhost:8000';
  static const String _webUrl = 'http://127.0.0.1:8000';
  static const String _physicalDeviceUrl =
      'http://192.168.1.7:8000'; // Placeholder, should be updated or config via dart-define

  static String get fastApiBaseUrl {
    if (kIsWeb) return _webUrl;
    if (Platform.isAndroid) return _androidEmulatorUrl;
    if (Platform.isIOS) return _iosSimulatorUrl;
    return _physicalDeviceUrl;
  }

  static String get cjBaseUrl {
    const String path = '/api/cj';
    if (kIsWeb) return 'http://127.0.0.1:3001$path';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001$path';
    if (Platform.isIOS) return 'http://localhost:3001$path';
    return 'http://192.168.1.100:3001$path'; // Update as needed
  }
}
