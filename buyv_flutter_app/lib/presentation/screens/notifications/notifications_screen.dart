import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/notification_service.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/auth_provider.dart';

/// Notifications Screen - Design conforme au screenshot Kotlin
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _todayNotifications = [];
  List<NotificationModel> _yesterdayNotifications = [];
  List<NotificationModel> _olderNotifications = [];
  bool _isLoading = true;

  String? get _currentUserId => Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _notificationService.streamUserNotifications(_currentUserId!).listen(
      (notifications) {
        if (mounted) {
          _categorizeNotifications(notifications);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  void _categorizeNotifications(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayList = <NotificationModel>[];
    final yesterdayList = <NotificationModel>[];
    final olderList = <NotificationModel>[];

    for (final notification in notifications) {
      final notifDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      if (notifDate == today) {
        todayList.add(notification);
      } else if (notifDate == yesterday) {
        yesterdayList.add(notification);
      } else {
        olderList.add(notification);
      }
    }

    setState(() {
      _todayNotifications = todayList;
      _yesterdayNotifications = yesterdayList;
      _olderNotifications = olderList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return _buildNotLoggedIn();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B7ACE)))
                  : _buildNotificationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 32, color: Color(0xFF0066CC)),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              'Notification',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0066CC),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Please login to view notifications',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    final hasNotifications = _todayNotifications.isNotEmpty ||
        _yesterdayNotifications.isNotEmpty ||
        _olderNotifications.isNotEmpty;

    if (!hasNotifications) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_todayNotifications.isNotEmpty) ...[
            _buildSectionHeader('Today'),
            const SizedBox(height: 12),
            ..._todayNotifications.asMap().entries.map((entry) {
              return _buildNotificationTile(entry.value, entry.key);
            }),
            const SizedBox(height: 24),
          ],
          if (_yesterdayNotifications.isNotEmpty) ...[
            _buildSectionHeader('Yesterday'),
            const SizedBox(height: 12),
            ..._yesterdayNotifications.asMap().entries.map((entry) {
              return _buildNotificationTile(entry.value, entry.key);
            }),
            const SizedBox(height: 24),
          ],
          if (_olderNotifications.isNotEmpty) ...[
            _buildSectionHeader('Earlier'),
            const SizedBox(height: 12),
            ..._olderNotifications.asMap().entries.map((entry) {
              return _buildNotificationTile(entry.value, entry.key);
            }),
          ],
          if (hasNotifications) ...[
            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6F00),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification, int index) {
    final hasBlueBackground = index % 2 == 1;
    final backgroundColor = hasBlueBackground ? Color(0xFFE3F2FD) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationIcon(notification),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getNotificationTitle(notification),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0066CC),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(notification.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    final type = notification.type.toLowerCase();

    if (type.contains('order') || type.contains('shipped')) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        backgroundImage: notification.data['senderAvatar'] != null
            ? NetworkImage(notification.data['senderAvatar'])
            : null,
        child: notification.data['senderAvatar'] == null
            ? Icon(Icons.person, color: Colors.grey[600])
            : null,
      );
    } else if (type.contains('discount') || type.contains('wishlist')) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Center(
          child: Text(
            'buyv',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0066CC),
            ),
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Color(0xFFE3F2FD),
        child: Icon(Icons.notifications, color: Color(0xFF0066CC)),
      );
    }
  }

  String _getNotificationTitle(NotificationModel notification) {
    final type = notification.type.toLowerCase();
    
    if (type.contains('order') && type.contains('shipped')) {
      return 'Order Shipped';
    } else if (type.contains('discount') || type.contains('wishlist')) {
      return 'Wishlist Discount';
    } else if (type.contains('cart')) {
      return 'Item Left in Cart';
    } else {
      return notification.title;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      final day = timestamp.day;
      final month = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'][timestamp.month - 1];
      final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = timestamp.hour >= 12 ? 'pm' : 'am';
      return '$day$month ,$hour:$minute $period';
    }
  }
}
