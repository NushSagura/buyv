import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../../data/services/order_service.dart';
import '../../../domain/models/order_model.dart';
import '../../../services/auth_api_service.dart';
import '../../../services/stripe_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final OrderService _orderService = OrderService();
  bool _isProcessing = false;

  Future<void> _processPayment(CartProvider cart) async {
    String? userId;
    try {
      final me = await AuthApiService.me();
      userId = me['id'] as String?;
    } catch (_) {}
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to continue')),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Call Stripe Service
    await StripeService.instance.makePayment(
      context: context,
      amount: cart.total,
      currency: 'usd', // Changed to USD for default Stripe testing
      onSuccess: () async {
        await _finalizeOrder(cart, userId!);
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          setState(() {
            _isProcessing = false;
          });
        }
      },
    );
  }

  Future<void> _finalizeOrder(CartProvider cart, String userId) async {
    try {
      // Create order items from cart
      final orderItems = cart.items
          .map(
            (cartItem) => OrderItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              productId: cartItem.product.id,
              productName: cartItem.product.name,
              productImage: cartItem.product.imageUrls.isNotEmpty
                  ? cartItem.product.imageUrls.first
                  : '',
              quantity: cartItem.quantity,
              price: cartItem.product.finalPrice,
            ),
          )
          .toList();

      // Create Order
      final order = OrderModel(
        id: '',
        userId: userId,
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        items: orderItems,
        status: OrderStatus.pending,
        subtotal: cart.subtotal,
        shipping: 10.0,
        tax: cart.subtotal * 0.1,
        total: cart.total,
        paymentMethod: 'Stripe', // Updated payment method
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save Order
      await _orderService.createOrder(order);

      // Clear Cart
      cart.clearCart();

      // Show Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );

        // Navigate Home
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error finalizing order: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const Center(
              child: Text('Your cart is empty, add products first'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildRow('Subtotal', cart.subtotal),
                _buildRow('Shipping', cart.shipping),
                _buildRow('Tax', cart.tax),
                const Divider(height: 24),
                _buildRow('Total', cart.total, isTotal: true),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _processPayment(cart),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Pay Now'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14)),
          Text(
            '${value.toStringAsFixed(2)} SAR',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
