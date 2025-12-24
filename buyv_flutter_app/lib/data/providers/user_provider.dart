import 'package:flutter/material.dart';

/// مزود بيانات المستخدم
class UserProvider with ChangeNotifier {
  String? _userId;
  String? _userName;
  String? _userEmail;
  bool _isLoggedIn = false;

  // Getters
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _isLoggedIn;

  /// تسجيل دخول المستخدم
  void login(String userId, String userName, String userEmail) {
    _userId = userId;
    _userName = userName;
    _userEmail = userEmail;
    _isLoggedIn = true;
    notifyListeners();
  }

  /// تسجيل خروج المستخدم
  void logout() {
    _userId = null;
    _userName = null;
    _userEmail = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // Signal for post updates (Feed/Profile refresh)
  DateTime _lastPostUpdate = DateTime.now();
  DateTime get lastPostUpdate => _lastPostUpdate;

  void triggerPostRefresh() {
    _lastPostUpdate = DateTime.now();
    notifyListeners();
  }

  /// تحديث بيانات المستخدم
  void updateUser(String userName, String userEmail) {
    _userName = userName;
    _userEmail = userEmail;
    notifyListeners();
  }
}
