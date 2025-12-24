import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';
import '../security/secure_token_manager.dart';
import '../../data/models/notification_model.dart';

class NotificationApiService {
  final String _baseUrl = AppConstants.fastApiBaseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await SecureTokenManager.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final url = Uri.parse('$_baseUrl/notifications/');
    final res = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final map = jsonDecode(res.body);
      return NotificationModel.fromMap(map);
    }
    throw Exception('Failed to create notification: ${res.statusCode} ${res.body}');
  }

  Future<List<NotificationModel>> listMyNotifications() async {
    final url = Uri.parse('$_baseUrl/notifications/me');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => NotificationModel.fromMap(e)).toList();
    }
    throw Exception('Failed to fetch notifications: ${res.statusCode} ${res.body}');
  }

  Future<void> markAsRead(String notificationId) async {
    final id = int.tryParse(notificationId) ?? notificationId;
    final url = Uri.parse('$_baseUrl/notifications/$id/read');
    final res = await http.post(url, headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Failed to mark notification as read: ${res.statusCode} ${res.body}');
  }
}