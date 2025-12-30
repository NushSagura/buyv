import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration d'environnement pour basculer entre dev et production
class EnvironmentConfig {
  // ═══════════════════════════════════════════════════════════════════
  // 🔧 CONFIGURATION PRINCIPALE - CHANGEZ ICI POUR SWITCHER MODE
  // ═══════════════════════════════════════════════════════════════════

  /// Définit le mode de l'application
  /// - true  : Mode DÉVELOPPEMENT (backend local)
  /// - false : Mode PRODUCTION (backend Railway)
  static const bool isDevelopment = false; // ← MODE PRODUCTION ACTIVÉ 🟢

  // ═══════════════════════════════════════════════════════════════════
  // 🌐 URLS DES BACKENDS
  // ═══════════════════════════════════════════════════════════════════

  /// URL du backend FastAPI en production (Railway)
  static const String _productionApiUrl =
      'https://buyv-production.up.railway.app';

  /// Port du backend local (défaut FastAPI = 8000)
  static const int _localPort = 8000;

  /// Votre adresse IP locale pour tester sur appareil physique
  /// Pour trouver votre IP :
  /// - Windows : ouvrez cmd et tapez "ipconfig"
  /// - Mac/Linux : ouvrez terminal et tapez "ifconfig" ou "ip addr"
  /// Cherchez l'adresse IPv4 (ex: 192.168.1.100)
  static const String _localNetworkIp =
      '192.168.11.109'; // ← CHANGEZ SELON VOTRE IP

  // ═══════════════════════════════════════════════════════════════════
  // 🚀 CONFIGURATION FASTAPI (Backend principal)
  // ═══════════════════════════════════════════════════════════════════

  /// Retourne l'URL du backend FastAPI selon le mode et la plateforme
  static String get fastApiBaseUrl {
    if (isDevelopment) {
      // Mode Développement - Backend local
      if (kIsWeb) {
        // Web : localhost avec protocole HTTP
        return 'http://127.0.0.1:$_localPort';
      }

      if (Platform.isAndroid) {
        // Android : utilise l'IP du réseau local pour appareils physiques
        // Pour émulateur, changez temporairement en 'http://10.0.2.2:$_localPort'
        return 'http://$_localNetworkIp:$_localPort';
      }

      if (Platform.isIOS) {
        // iOS Simulator : localhost fonctionne directement
        return 'http://localhost:$_localPort';
      }

      // Appareil physique (Android/iOS) : utilise l'IP du réseau local
      // ⚠️ Assurez-vous que votre appareil et PC sont sur le même réseau WiFi
      return 'http://$_localNetworkIp:$_localPort';
    } else {
      // Mode Production - Backend Railway
      return _productionApiUrl;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 🛒 CONFIGURATION CJ DROPSHIPPING
  // ═══════════════════════════════════════════════════════════════════

  /// URL directe de l'API CJ pour mobile (pas de CORS)
  static const String _cjApiDirectUrl =
      'https://developers.cjdropshipping.com/api2.0/v1';

  /// Port du serveur proxy CORS pour le Web
  static const int _cjProxyPort = 3001;

  /// Retourne l'URL de l'API CJ selon la plateforme
  /// Web → Proxy CORS (localhost:3001/api/cj)
  /// Mobile → Appel direct (pas de restrictions CORS)
  static String get cjBaseUrl {
    if (kIsWeb) {
      // Web nécessite le proxy CORS
      return 'http://127.0.0.1:$_cjProxyPort/api/cj';
    }

    // Mobile (Android/iOS) : appel direct sans proxy
    return _cjApiDirectUrl;
  }

  // ═══════════════════════════════════════════════════════════════════
  // 🔍 HELPERS DE DEBUG
  // ═══════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════
  // 🐛 DEBUG & LOGGING
  // ═══════════════════════════════════════════════════════════════════
  
  /// Active les logs de debug en console
  /// ⚠️ TOUJOURS FALSE EN PRODUCTION pour éviter lag/lenteur
  static const bool enableDebugLogs = false; // ← DÉSACTIVÉ EN PRODUCTION

  /// Affiche la configuration au démarrage uniquement en mode développement
  static void printConfig() {
    // N'affiche rien en production pour optimiser les performances
    if (!isDevelopment || !enableDebugLogs) return;
    
    if (kDebugMode) {
      print('════════════════════════════════════════');
      print('🔧 CONFIGURATION ENVIRONNEMENT');
      print('════════════════════════════════════════');
      print('Mode : ${isDevelopment ? "🟡 DÉVELOPPEMENT" : "🟢 PRODUCTION"}');
      print('FastAPI URL : $fastApiBaseUrl');
      print('CJ Proxy URL : $cjBaseUrl');
      print('Plateforme : ${_getCurrentPlatform()}');
      print('════════════════════════════════════════');
    }
  }

  /// Retourne le nom de la plateforme actuelle
  static String _getCurrentPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'MacOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Vérifie si l'application tourne en mode debug
  static bool get isDebugMode => kDebugMode;

  /// Vérifie si l'application tourne en mode release
  static bool get isReleaseMode => kReleaseMode;
}
