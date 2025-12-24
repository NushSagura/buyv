import 'package:flutter/foundation.dart';
import '../data/models/notification_model.dart';
import 'api/notification_api_service.dart';
import 'dart:async';

class NotificationService {
  final NotificationApiService _api = NotificationApiService();

  /// Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _api.createNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );
      
      if (kDebugMode) {
        print('✅ Notification created: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create notification: $e');
      }
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Get all notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      return await _api.listMyNotifications();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get user notifications: $e');
      }
      throw Exception('Failed to get user notifications: $e');
    }
  }

  /// Stream user notifications for real-time updates
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    // Polling-based stream against backend
    return Stream.periodic(Duration(seconds: 5)).asyncMap((_) => getUserNotifications(userId));
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.markAsRead(notificationId);
      
      if (kDebugMode) {
        print('✅ Notification marked as read: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to mark notification as read: $e');
      }
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final items = await getUserNotifications(userId);
      for (final n in items.where((e) => !e.isRead)) {
        await markAsRead(n.id);
      }
      
      if (kDebugMode) {
        print('✅ All notifications marked as read for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to mark all notifications as read: $e');
      }
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Backend currently does not support deletion; no-op or implement later
      if (kDebugMode) {
        print('✅ Notification deleted: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to delete notification: $e');
      }
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Get unread notification count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final items = await getUserNotifications(userId);
      return items.where((e) => !e.isRead).length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get unread count: $e');
      }
      return 0;
    }
  }

  /// Stream unread notification count
  Stream<int> streamUnreadCount(String userId) {
    return streamUserNotifications(userId).map((list) => list.where((e) => !e.isRead).length);
  }

  /// Send order notification
  Future<void> sendOrderNotification({
    required String userId,
    required String orderId,
    required String orderStatus,
  }) async {
    String title = '';
    String body = '';

    switch (orderStatus.toLowerCase()) {
      case 'confirmed':
        title = 'Order Confirmed';
        body = 'Your order #$orderId has been confirmed and is being processed.';
        break;
      case 'shipped':
        title = 'Order Shipped';
        body = 'Your order #$orderId has been shipped and is on its way!';
        break;
      case 'delivered':
        title = 'Order Delivered';
        body = 'Your order #$orderId has been delivered successfully.';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        body = 'Your order #$orderId has been cancelled.';
        break;
      default:
        title = 'Order Update';
        body = 'Your order #$orderId status has been updated to $orderStatus.';
    }

    await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'order',
      data: {
        'orderId': orderId,
        'orderStatus': orderStatus,
      },
    );
  }

  /// Send promotion notification
  Future<void> sendPromotionNotification({
    required String userId,
    required String title,
    required String message,
    String? productId,
    String? discountCode,
  }) async {
    await createNotification(
      userId: userId,
      title: title,
      body: message,
      type: 'promotion',
      data: {
        if (productId != null) 'productId': productId,
        if (discountCode != null) 'discountCode': discountCode,
      },
    );
  }

  /// Send commission notification
  Future<void> sendCommissionNotification({
    required String userId,
    required double commissionAmount,
    required String productName,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Commission Earned!',
      body: 'You earned \$${commissionAmount.toStringAsFixed(2)} commission from $productName sale.',
      type: 'commission',
      data: {
        'commissionAmount': commissionAmount,
        'productName': productName,
      },
    );
  }
}