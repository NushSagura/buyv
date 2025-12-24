import 'package:flutter/material.dart';

/// مزود بيانات الثيم
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  /// الحصول على حالة الثيم المظلم
  bool get isDarkMode => _isDarkMode;

  /// تبديل الثيم
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// تعيين الثيم المظلم
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  /// الحصول على بيانات الثيم
  ThemeData get themeData {
    return _isDarkMode ? ThemeData.dark() : ThemeData.light();
  }
}