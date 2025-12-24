import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';
import '../security/secure_token_manager.dart';
import '../../domain/models/order_model.dart';

class OrderApiService {
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

  Future<Map<String, dynamic>> createOrder(OrderModel order) async {
    final url = _url('/orders');
    final payload = {
      'orderNumber': order.orderNumber.isNotEmpty ? order.orderNumber : null,
      'items': order.items.map((item) => item.toMap()).toList(),
      'status': order.status.name,
      'subtotal': order.subtotal,
      'shipping': order.shipping,
      'tax': order.tax,
      'total': order.total,
      'shippingAddress': order.shippingAddress?.toMap(),
      'paymentMethod': order.paymentMethod,
      'estimatedDelivery': order.estimatedDelivery?.toIso8601String(),
      'trackingNumber': order.trackingNumber,
      'notes': order.notes,
      'promoterId': order.promoterId,
    };

    final res = await http.post(url, headers: await _headers(), body: jsonEncode(payload));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create order: ${res.statusCode} ${res.body}');
  }

  Future<List<Map<String, dynamic>>> listMyOrders() async {
    final url = _url('/orders/me');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to list orders: ${res.statusCode} ${res.body}');
  }

  Future<List<Map<String, dynamic>>> listMyOrdersByStatus(String status) async {
    final url = _url('/orders/me/by_status', {'status': status});
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to list orders by status: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    final url = _url('/orders/$orderId');
    final res = await http.get(url, headers: await _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    if (res.statusCode == 404) return null;
    throw Exception('Failed to get order: ${res.statusCode} ${res.body}');
  }

  Future<bool> updateStatus(String orderId, String status) async {
    final url = _url('/orders/$orderId/status');
    final res = await http.patch(url, headers: await _headers(), body: jsonEncode({'status': status}));
    if (res.statusCode >= 200 && res.statusCode < 300) return true;
    return false;
  }

  Future<bool> cancelOrder(String orderId) async {
    final url = _url('/orders/$orderId/cancel');
    final res = await http.post(url, headers: await _headers());
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> updateTrackingNumber(String orderId, String trackingNumber) async {
    final url = _url('/orders/$orderId/tracking');
    final res = await http.patch(url, headers: await _headers(), body: jsonEncode({'trackingNumber': trackingNumber}));
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}