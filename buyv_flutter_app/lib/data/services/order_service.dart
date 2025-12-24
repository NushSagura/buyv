import 'package:flutter/foundation.dart';
import '../../domain/models/order_model.dart';
import '../../services/api/order_api_service.dart';
import '../../services/auth_api_service.dart';

class OrderService {
  final OrderApiService _api = OrderApiService();

  // Create a new order
  Future<String?> createOrder(OrderModel order) async {
    try {
      // Backend derives user from JWT, client need not set userId here
      final created = await _api.createOrder(order);
      final id = created['id']?.toString();
      return id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      return await _api.updateStatus(orderId, status.name);
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  // Get user orders
  Stream<List<OrderModel>> getUserOrders(String userId) async* {
    // REST polling
    while (true) {
      try {
        final list = await _api.listMyOrders();
        yield list
            .map((m) => OrderModel.fromMap(m, (m['id']?.toString() ?? '')))
            .toList();
      } catch (e) {
        debugPrint('Error polling user orders: $e');
        yield [];
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final data = await _api.getOrder(orderId);
      if (data == null) return null;
      return OrderModel.fromMap(data, orderId);
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      // Server enforces cancelability and updates commissions atomically
      return await _api.cancelOrder(orderId);
    } catch (e) {
      debugPrint('Error canceling order: $e');
      return false;
    }
  }

  // Get orders by status
  Stream<List<OrderModel>> getOrdersByStatus(String userId, OrderStatus status) async* {
    while (true) {
      try {
        final list = await _api.listMyOrdersByStatus(status.name);
        yield list
            .map((m) => OrderModel.fromMap(m, (m['id']?.toString() ?? '')))
            .toList();
      } catch (e) {
        debugPrint('Error polling orders by status: $e');
        yield [];
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Update tracking number
  Future<bool> updateTrackingNumber(String orderId, String trackingNumber) async {
    try {
      return await _api.updateTrackingNumber(orderId, trackingNumber);
    } catch (e) {
      debugPrint('Error updating tracking number: $e');
      return false;
    }
  }

  // Get all orders (admin function)
  Stream<List<OrderModel>> getAllOrders() async* {
    // Placeholder: backend admin endpoint not implemented; use my orders
    yield* getUserOrders(await _currentUserIdSafe());
  }

  // Get orders with commissions (for tracking promoted sales)
  Stream<List<OrderModel>> getOrdersWithCommissions() async* {
    // Filter client-side for now
    await for (final orders in getUserOrders(await _currentUserIdSafe())) {
      yield orders.where((o) => o.promoterId != null && o.promoterId!.isNotEmpty).toList();
    }
  }

  // Private helper methods

  Future<String> _currentUserIdSafe() async {
    try {
      final me = await AuthApiService.me();
      return (me['id'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  // Commission processing moved to backend.
}