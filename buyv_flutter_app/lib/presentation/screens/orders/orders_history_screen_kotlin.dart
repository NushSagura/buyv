import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/order_service.dart';
import '../../../domain/models/order_model.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

/// Orders History Screen - Design Kotlin
/// Avec TabController et layout en colonnes (Item, Status, Total)
class OrdersHistoryScreenKotlin extends StatefulWidget {
  const OrdersHistoryScreenKotlin({super.key});

  @override
  State<OrdersHistoryScreenKotlin> createState() => _OrdersHistoryScreenKotlinState();
}

class _OrdersHistoryScreenKotlinState extends State<OrdersHistoryScreenKotlin> 
    with SingleTickerProviderStateMixin {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  
  final List<String> _tabs = ['All', 'Completed', 'Pending', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';

    if (userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please login to view your orders';
      });
      return;
    }

    try {
      final orders = await OrderService().getUserOrders(userId).first;
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load orders';
        });
      }
    }
  }

  List<OrderModel> get _filteredOrders {
    final currentTab = _tabs[_tabController.index];
    if (currentTab == 'All') return _orders;
    
    return _orders.where((order) {
      final statusName = order.status.toString().split('.').last.toLowerCase();
      
      if (currentTab == 'Completed') {
        return statusName == 'delivered';
      } else if (currentTab == 'Pending') {
        return statusName == 'pending' || statusName == 'processing' || statusName == 'shipped';
      } else if (currentTab == 'Cancelled') {
        return statusName == 'canceled' || statusName == 'cancelled';
      }
      return false;
    }).toList();
  }

  int _getTabCount(String tabName) {
    if (tabName == 'All') return _orders.length;
    
    return _orders.where((order) {
      final statusName = order.status.toString().split('.').last.toLowerCase();
      
      if (tabName == 'Completed') {
        return statusName == 'delivered';
      } else if (tabName == 'Pending') {
        return statusName == 'pending' || statusName == 'processing' || statusName == 'shipped';
      } else if (tabName == 'Cancelled') {
        return statusName == 'canceled' || statusName == 'cancelled';
      }
      return false;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Orders History',
          style: TextStyle(
            color: Color(0xFF0066CC),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0066CC)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Tab Bar with counts
          _buildTabBar(),
          
          // Header row with column labels
          _buildTableHeader(),
          
          const Divider(color: Color(0xFFE9E9E9), height: 1),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0066CC)),
                  )
                : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9E9E9), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Color(0xFF0066CC),
        unselectedLabelColor: Colors.grey,
        indicatorColor: Color(0xFF0066CC),
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        onTap: (index) => setState(() {}),
        tabs: _tabs.map((tab) {
          final count = _getTabCount(tab);
          return Tab(text: '$tab ($count)');
        }).toList(),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: const [
          Expanded(
            flex: 3,
            child: Text(
              'Item',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF181D23),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF181D23),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF181D23),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: const Color(0xFF0066CC),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusName = order.status.toString().split('.').last.toLowerCase();
    final isDelivered = statusName == 'delivered';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9E9E9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Table row layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item column (image + name + quantity)
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      // Product image
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF5F5F5),
                        ),
                        child: order.items.isNotEmpty && order.items.first.productImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: order.items.first.productImage,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.shopping_bag,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : const Icon(Icons.shopping_bag, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.items.isNotEmpty 
                                  ? order.items.first.productName 
                                  : 'Product',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF181D23),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (order.items.length > 1)
                              Text(
                                '+${order.items.length - 1} more',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 2),
                            if (order.items.isNotEmpty)
                              Text(
                                'Qty: ${order.items.first.quantity}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status column
                Expanded(
                  flex: 2,
                  child: Center(
                    child: _buildStatusBadge(order.status),
                  ),
                ),
                
                // Total column
                Expanded(
                  flex: 1,
                  child: Text(
                    '\$${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFFF6F00),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            
            // Upload video button for delivered orders
            if (isDelivered) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE9E9E9), height: 1),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to video upload
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upload video feature coming soon'),
                      backgroundColor: Color(0xFF0066CC),
                    ),
                  );
                },
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Upload video'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF176DBA),
                  side: const BorderSide(color: Color(0xFF176DBA), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFFEFF6FA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    final statusName = status.toString().split('.').last.toLowerCase();
    Color statusColor;
    String displayText;
    
    switch (statusName) {
      case 'pending':
      case 'processing':
      case 'confirmed':
        statusColor = const Color(0xFFFF9800); // Yellow/Orange
        displayText = 'Pending';
        break;
      case 'shipped':
      case 'out_for_delivery':
        statusColor = const Color(0xFF2196F3); // Blue
        displayText = 'Shipped';
        break;
      case 'delivered':
        statusColor = const Color(0xFF4CAF50); // Green
        displayText = 'Delivered';
        break;
      case 'canceled':
      case 'cancelled':
      case 'returned':
      case 'refunded':
        statusColor = const Color(0xFFFF5722); // Red
        displayText = 'Canceled';
        break;
      default:
        statusColor = Colors.grey;
        displayText = statusName;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start shopping to see your orders here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
