import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository_fastapi.dart';
import '../../domain/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepositoryFastApi _authRepository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider(this._authRepository) {
    _initializeAuth();
  }

  void _initializeAuth() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      
      // Vérifier d'abord si un token existe
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        debugPrint('✅ Utilisateur authentifié automatiquement: ${user.displayName}');
      } else {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        debugPrint('⚠️ Aucun utilisateur connecté');
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      debugPrint('❌ Erreur d\'initialisation auth: $e');
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final userData = await _authRepository.getUserData(uid);
      if (userData != null) {
        _currentUser = userData;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final user = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );

      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _errorMessage = 'Google sign-in not supported';
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _authRepository.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      await _authRepository.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  /// Delete account permanently
  /// Required for Google Play Store and Apple App Store compliance
  Future<void> deleteAccount({
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      
      await _authRepository.deleteAccount(password: password);
      
      // Clear user data and sign out
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<void> updateUserData(UserModel updatedUser) async {
    try {
      await _authRepository.updateUserData(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Update user profile (displayName, avatarUrl, phoneNumber)
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName,
        profileImageUrl: avatarUrl,
        phoneNumber: phoneNumber,
      );

      await updateUserData(updatedUser);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      throw Exception('Failed to update profile: $e');
      rethrow;
    }
  }

  Future<void> reloadUserData() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        debugPrint('✅ Données utilisateur rechargées: ${user.displayName}');
      } else {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        debugPrint('⚠️ Impossible de recharger les données utilisateur');
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      _errorMessage = e.toString();
      debugPrint('❌ Erreur rechargement données: $e');
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}