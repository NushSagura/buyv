import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en', 'US'); // Default to English

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void setLocale(Locale locale) async {
    if (!['en', 'ar', 'fr'].contains(locale.languageCode)) return;
    
    _locale = locale;
    notifyListeners();
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await prefs.setString('country_code', locale.countryCode ?? '');
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    final countryCode = prefs.getString('country_code') ?? 'US';
    
    _locale = Locale(languageCode, countryCode.isEmpty ? null : countryCode);
    notifyListeners();
  }

  void toggleLanguage() {
    switch (_locale.languageCode) {
      case 'en':
        setLocale(const Locale('fr', 'FR'));
        break;
      case 'fr':
        setLocale(const Locale('ar', 'SA'));
        break;
      case 'ar':
        setLocale(const Locale('en', 'US'));
        break;
      default:
        setLocale(const Locale('en', 'US'));
    }
  }

  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'Arabic';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  bool get isRTL => _locale.languageCode == 'ar';
}