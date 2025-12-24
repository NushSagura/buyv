import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'security/secure_token_manager.dart';

class AuthApiService {
  static Uri _url(String path) => Uri.parse('${AppConstants.fastApiBaseUrl}$path');

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final res = await http.post(
      _url('/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
        'displayName': displayName,
      }),
    );
    final data = _parseResponse(res);
    await _storeTokenFromAuthResponse(data);
    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _url('/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final data = _parseResponse(res);
    await _storeTokenFromAuthResponse(data);
    return data;
  }

  static Future<Map<String, dynamic>> me() async {
    final token = await SecureTokenManager.getAccessToken();
    final res = await http.get(
      _url('/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> getUser(String uid) async {
    final token = await SecureTokenManager.getAccessToken();
    final res = await http.get(
      _url('/users/$uid'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> updateUser(String uid, Map<String, dynamic> update) async {
    final token = await SecureTokenManager.getAccessToken();
    final res = await http.put(
      _url('/users/$uid'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(update),
    );
    return _parseResponse(res);
  }

  static Map<String, dynamic> _parseResponse(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (!ok) {
      final detail = body is Map && body['detail'] != null ? body['detail'].toString() : 'Request failed (${res.statusCode})';
      throw Exception(detail);
    }
    return body as Map<String, dynamic>;
  }

  static Future<void> _storeTokenFromAuthResponse(Map<String, dynamic> data) async {
    if (data.containsKey('access_token')) {
      final token = data['access_token'] as String;
      final expiresIn = (data['expires_in'] ?? 3600) as int;
      final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
      // Backend currently doesn't issue refresh tokens; store empty safely
      await SecureTokenManager.storeAccessToken(token: token, refreshToken: '', expiryTime: expiryTime);
    }
  }
}