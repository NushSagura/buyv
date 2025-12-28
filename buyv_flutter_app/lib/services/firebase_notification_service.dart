import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📱 Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  
  // Process notification in background
  await FirebaseNotificationService._handleBackgroundMessageStatic(message);
}

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  static FirebaseNotificationService get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _fcmToken;
  
  // Callback for when notification is tapped
  Function(RemoteMessage)? onMessageTapped;
  
  // Callback for when notification is received while app is in foreground
  Function(RemoteMessage)? onMessageReceived;

  FirebaseNotificationService._internal();

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ Firebase notifications already initialized');
      return;
    }

    try {
      debugPrint('🔥 Initializing Firebase Notifications...');

      // Initialize Firebase
      await Firebase.initializeApp();

      // Request permission (iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      debugPrint('✅ Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ User granted provisional permission');
      } else {
        debugPrint('❌ User declined or has not accepted permission');
      }

      // Initialize local notifications (for Android)
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      // Send token to backend
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _sendTokenToBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification that opened the app from terminated state
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📱 App opened from terminated state via notification');
        _handleNotificationTap(initialMessage);
      }

      // Configure background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _initialized = true;
      debugPrint('✅ Firebase Notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Notifications: $e');
      rethrow;
    }
  }

  /// Initialize Flutter Local Notifications (for Android foreground notifications)
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Show local notification
    _showLocalNotification(message);

    // Call callback if set
    onMessageReceived?.call(message);
  }

  /// Show local notification (for foreground messages)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: Color(0xFFFF6F00), // Buyv orange color
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap (when app is in background)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 Notification tapped: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Call callback if set
    onMessageTapped?.call(message);

    // Route based on notification type
    _routeNotification(message);
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(NotificationResponse response) {
    debugPrint('📱 Local notification tapped: ${response.payload}');
    
    // Parse payload and route
    // You can enhance this to parse the payload and route accordingly
  }

  /// Route notification based on type
  void _routeNotification(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    debugPrint('🔀 Routing notification of type: $type');

    switch (type) {
      case 'follow':
        // Navigate to followers screen
        debugPrint('→ Route to followers');
        break;
      case 'like':
        // Navigate to post detail
        final postId = data['post_id'] as String?;
        debugPrint('→ Route to post: $postId');
        break;
      case 'comment':
        // Navigate to post detail with comments
        final postId = data['post_id'] as String?;
        debugPrint('→ Route to post comments: $postId');
        break;
      case 'order':
        // Navigate to order detail
        final orderId = data['order_id'] as String?;
        debugPrint('→ Route to order: $orderId');
        break;
      case 'commission':
        // Navigate to commissions screen
        debugPrint('→ Route to commissions');
        break;
      default:
        debugPrint('→ No specific route for type: $type');
    }
  }

  /// Handle background message (static for background isolate)
  static Future<void> _handleBackgroundMessageStatic(RemoteMessage message) async {
    // Process notification data
    // Save to local storage if needed
    // Update badge count, etc.
    
    debugPrint('✅ Background message processed');
  }

  /// Handle background message (instance method)
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _handleBackgroundMessageStatic(message);
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      debugPrint('📤 Sending FCM token to backend...');
      
      // Use the auth API service to update the token
      final response = await AuthApiService.updateFCMToken(token);
      
      debugPrint('✅ FCM token sent to backend successfully');
    } catch (e) {
      debugPrint('❌ Failed to send FCM token to backend: $e');
      // Don't throw - we can retry later
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic: $e');
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Delete FCM token (call on logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Failed to delete FCM token: $e');
    }
  }
}
