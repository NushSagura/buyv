import 'package:flutter/foundation.dart';
import '../../domain/models/user_model.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_api_service.dart';
import '../../services/security/secure_token_manager.dart';

class AuthRepositoryFastApi {
  AuthRepositoryFastApi();

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final res = await AuthApiService.register(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
    );
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final res = await AuthApiService.login(email: email, password: password);
    return UserModel.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    await SecureTokenManager.clearAllTokens();
  }

  Future<void> resetPassword(String email) async {
    // Not implemented on backend yet
    throw Exception('Reset password not implemented');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Not implemented on backend yet
    throw Exception('Change password not implemented');
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final res = await AuthApiService.me();
      return UserModel.fromJson(res);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final res = await AuthApiService.getUser(uid);
      return UserModel.fromJson(res);
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  Future<UserModel> updateUserData(UserModel updated) async {
    final res = await AuthApiService.updateUser(updated.id, updated.toJson());
    return UserModel.fromJson(res);
  }
}