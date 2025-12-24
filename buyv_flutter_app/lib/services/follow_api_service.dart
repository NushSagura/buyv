import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'security/secure_token_manager.dart';

class FollowApiService {
  static Uri _url(String path) => Uri.parse('${AppConstants.fastApiBaseUrl}$path');

  static Future<Map<String, String>> _authHeaders() async {
    final token = await SecureTokenManager.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parse(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (!ok) {
      final detail = body is Map && body['detail'] != null ? body['detail'].toString() : 'Request failed (${res.statusCode})';
      throw Exception(detail);
    }
    return body as Map<String, dynamic>;
  }

  static Future<bool> followUser(String targetUid) async {
    final res = await http.post(_url('/follows/$targetUid'), headers: await _authHeaders());
    final data = _parse(res);
    return (data['status'] ?? '') == 'followed' || (data['status'] ?? '') == 'already_following';
  }

  static Future<bool> unfollowUser(String targetUid) async {
    final res = await http.delete(_url('/follows/$targetUid'), headers: await _authHeaders());
    final data = _parse(res);
    return (data['status'] ?? '') == 'unfollowed' || (data['status'] ?? '') == 'not_following';
  }

  static Future<bool> isFollowing(String targetUid) async {
    final res = await http.get(_url('/follows/is_following/$targetUid'), headers: await _authHeaders());
    final data = _parse(res);
    return (data['isFollowing'] ?? false) as bool;
  }

  static Future<List<String>> getFollowers(String uid) async {
    final res = await http.get(_url('/follows/$uid/followers'), headers: await _authHeaders());
    final data = _parse(res);
    return List<String>.from(data['followers'] ?? []);
  }

  static Future<List<String>> getFollowing(String uid) async {
    final res = await http.get(_url('/follows/$uid/following'), headers: await _authHeaders());
    final data = _parse(res);
    return List<String>.from(data['following'] ?? []);
  }

  static Future<Map<String, int>> getCounts(String uid) async {
    final res = await http.get(_url('/follows/$uid/counts'), headers: await _authHeaders());
    final data = _parse(res);
    return {
      'followers': (data['followers'] ?? 0) as int,
      'following': (data['following'] ?? 0) as int,
    };
  }

  static Future<List<String>> getSuggested({int limit = 20}) async {
    final res = await http.get(_url('/follows/suggested?limit=$limit'), headers: await _authHeaders());
    final data = _parse(res);
    return List<String>.from(data['suggested'] ?? []);
  }
}