import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'security/secure_token_manager.dart';

class PostApiService {
  static Uri _url(String path) =>
      Uri.parse('${AppConstants.fastApiBaseUrl}$path');

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
      final detail = body is Map && body['detail'] != null
          ? body['detail'].toString()
          : 'Request failed (${res.statusCode})';
      throw Exception(detail);
    }
    return body is Map<String, dynamic> ? body : {'data': body};
  }

  static List<Map<String, dynamic>> _parseList(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : [];
    if (!ok) {
      final msg = body is Map && body['detail'] != null
          ? body['detail'].toString()
          : 'Request failed (${res.statusCode})';
      throw Exception(msg);
    }
    if (body is List) {
      return List<Map<String, dynamic>>.from(
        body.map((e) => Map<String, dynamic>.from(e)),
      );
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getUserPosts(
    String uid, {
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    final q = [
      if (type != null) 'type=$type',
      'limit=$limit',
      'offset=$offset',
    ].join('&');
    final res = await http.get(
      _url('/posts/user/$uid?$q'),
      headers: await _authHeaders(),
    );
    return _parseList(res);
  }

  static Future<List<Map<String, dynamic>>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await http.get(
      _url('/posts/feed?limit=$limit&offset=$offset'),
      headers: await _authHeaders(),
    );
    return _parseList(res);
  }

  static Future<List<Map<String, dynamic>>> getUserLikedPosts(
    String uid, {
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await http.get(
      _url('/posts/user/$uid/liked?limit=$limit&offset=$offset'),
      headers: await _authHeaders(),
    );
    return _parseList(res);
  }

  static Future<int> getPostsCount(String uid, {String? type}) async {
    final q = type != null ? '?type=$type' : '';
    final res = await http.get(
      _url('/posts/user/$uid/count$q'),
      headers: await _authHeaders(),
    );
    final data = _parse(res);
    return (data['count'] ?? 0) as int;
  }

  static Future<bool> likePost(String postUid) async {
    final res = await http.post(
      _url('/posts/$postUid/like'),
      headers: await _authHeaders(),
    );
    final data = _parse(res);
    final status = (data['status'] ?? '') as String;
    return status == 'liked' || status == 'already_liked';
  }

  static Future<bool> unlikePost(String postUid) async {
    final res = await http.delete(
      _url('/posts/$postUid/like'),
      headers: await _authHeaders(),
    );
    final data = _parse(res);
    final status = (data['status'] ?? '') as String;
    return status == 'unliked' || status == 'not_liked';
  }

  static Future<bool> isPostLiked(String postUid) async {
    final res = await http.get(
      _url('/posts/$postUid/is_liked'),
      headers: await _authHeaders(),
    );
    final data = _parse(res);
    return (data['isLiked'] ?? false) as bool;
  }

  static Future<Map<String, dynamic>> createPost({
    required String type,
    required String mediaUrl,
    String? caption,
    Map<String, dynamic>? additionalData,
  }) async {
    final body = jsonEncode({
      'type': type,
      'mediaUrl': mediaUrl,
      if (caption != null) 'caption': caption,
      if (additionalData != null) 'additionalData': additionalData,
    });
    final res = await http.post(
      _url('/posts/'),
      headers: await _authHeaders(),
      body: body,
    );
    return _parse(res);
  }

  static Future<bool> deletePost(String postUid) async {
    final res = await http.delete(
      _url('/posts/$postUid'),
      headers: await _authHeaders(),
    );
    final data = _parse(res);
    return (data['status'] ?? '') == 'deleted';
  }
}
