import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';
import '../security/secure_token_manager.dart';

class CommentApiService {
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

  /// Add a comment to a post
  static Future<Map<String, dynamic>> addComment(
    String postUid,
    String content,
  ) async {
    final body = jsonEncode({'content': content});
    final res = await http.post(
      _url('/comments/$postUid'),
      headers: await _authHeaders(),
      body: body,
    );
    return _parse(res);
  }

  /// Get comments for a post with pagination
  static Future<List<Map<String, dynamic>>> getComments(
    String postUid, {
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await http.get(
      _url('/comments/$postUid?limit=$limit&offset=$offset'),
      headers: await _authHeaders(),
    );
    return _parseList(res);
  }
}
