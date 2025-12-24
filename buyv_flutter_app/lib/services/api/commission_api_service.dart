import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';
import '../security/secure_token_manager.dart';

class CommissionApiService {
  final String _baseUrl = AppConstants.fastApiBaseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await SecureTokenManager.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path, [Map<String, String>? query]) {
    final base = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: {
      ...base.queryParameters,
      ...query,
    });
  }

  Future<List<Map<String, dynamic>>> listMyCommissions() async {
    final url = _url('/commissions/me');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to list commissions: ${res.statusCode} ${res.body}');
  }

  Future<bool> updateStatus(String commissionId, String status) async {
    final url = _url('/commissions/$commissionId/status');
    final res = await http.post(url, headers: await _headers(), body: jsonEncode({'status': status}));
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}