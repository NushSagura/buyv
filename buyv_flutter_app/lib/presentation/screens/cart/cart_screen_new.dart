import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../domain/models/cart_model.dart';
import '../../../domain/models/order_model.dart';
import '../../../data/services/order_service.dart';
import '../../../services/stripe_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';

/// CartScreen style Kotlin
/// - Header: "Cart" centré en bleu (#0066CC)
/// - Liste de CartProductCard avec image, nom, size/color, prix, quantité
/// - CostSummary: Subtotal, Shipping, Tax, Total
/// - PromoCodeField avec icône %
/// - Bouton Checkout orange (#FF6600)
class CartScreenNew extends StatefulWidget {
  const CartScreenNew({super.key});

  @override
  State<CartScreenNew> createState() => _CartScreenNewState();
}

class _CartScreenNewState extends State<CartScreenNew> {
  bool _isLoading = false;
  String? _error;
  double _discount = 0.0;
  String? _appliedPromoCode;
  final TextEditingController _promoCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ne pas appeler loadCart() ici car cela écrase le panier en mémoire
    // Le panier est déjà géré par CartProvider qui notifie les changements
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  // Seulement utilisé pour le refresh manuel (pull-to-refresh)
  Future<void> _refreshCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Force sync with storage if needed
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.saveCart(); // Ensure current state is saved
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, double> _calculateTotals(List<CartItem> items) {
    final subtotal = items.fold(0.0, (sum, item) => 
        sum + ((item.product.discountPrice ?? item.product.price) * item.quantity));
    final shipping = items.isEmpty ? 0.0 : 5.0;
    final tax = subtotal * 0.08;
    final total = subtotal + shipping + tax - _discount;
    return {'subtotal': subtotal, 'shipping': shipping, 'tax': tax, 'total': total};
  }

  void _updateQuantity(String itemId, int newQuantity) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (newQuantity > 0) {
      cartProvider.updateQuantity(itemId, newQuantity);
    } else {
      cartProvider.removeFromCart(itemId);
    }
  }

  void _removeItem(String itemId) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.removeFromCart(itemId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item removed from cart'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _applyPromoCode(double subtotal) {
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a promo code')),
      );
      return;
    }

    Map<String, double> validCodes = {
      'SAVE10': 0.10,
      'SAVE20': 0.20,
      'WELCOME': 0.15,
      'FIRST': 0.25,
    };

    if (validCodes.containsKey(code)) {
      setState(() {
        _discount = subtotal * validCodes[code]!;
        _appliedPromoCode = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promo code applied! You saved \$${_discount.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePromoCode() {
    setState(() {
      _discount = 0.0;
      _appliedPromoCode = null;
      _promoCodeController.clear();
    });
  }

  Future<void> _processCheckout(List<CartItem> cartItems, double total) async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isDesktopOrWeb = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
      
      if (isDesktopOrWeb) {
        await _showMockPaymentDialog(cartItems, total);
      } else {
        await StripeService.instance.makePayment(
          context: context,
          amount: total,
          currency: 'usd',
          onSuccess: () async {
            await _createOrder(cartItems, total);
          },
          onError: (error) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createOrder(List<CartItem> cartItems, double total) async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final totals = _calculateTotals(cartItems);
      final subtotal = totals['subtotal']!;
      final shipping = totals['shipping']!;
      final tax = totals['tax']!;

      final orderItems = cartItems.map((item) => OrderItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: item.product.id,
        productName: item.product.name,
        productImage: item.product.imageUrls.isNotEmpty ? item.product.imageUrls.first : '',
        price: item.product.price,
        quantity: item.quantity,
        size: item.selectedSize,
        color: item.selectedColor,
        attributes: item.selectedAttributes?.map((key, value) => MapEntry(key, value.toString())) ?? {},
        isPromotedProduct: item.promoterId != null,
        promoterId: item.promoterId,
      )).toList();

      final order = OrderModel(
        id: '',
        userId: currentUser.id,
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        items: orderItems,
        status: OrderStatus.pending,
        subtotal: subtotal,
        shipping: shipping,
        tax: tax,
        total: total,
        paymentMethod: 'stripe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: 'Order from BuyV app',
      );

      final orderId = await OrderService().createOrder(order);

      if (orderId == null) {
        throw Exception('Failed to create order');
      }

      cartProvider.clearCart();
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      context.push('/orders-history');
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showMockPaymentDialog(List<CartItem> cartItems, double total) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedCornerShape(borderRadius: BorderRadius.circular(16)),
          title: const Text('Test Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payment, size: 64, color: Color(0xFF4CAF50)),
              const SizedBox(height: 16),
              Text(
                'Total: \$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Stripe is not available on desktop.\nThis is a test payment for development.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() => _isLoading = false);
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _createOrder(cartItems, total);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Provider.of<AuthProvider>(context).currentUser;

    debugPrint('🛒 CartScreenNew build - authUser: ${authUser?.email ?? "NULL"}');

    // Écran de connexion requis
    if (authUser == null) {
      debugPrint('🛒 User not authenticated, showing login screen');
      return _buildRequireLoginScreen();
    }

    debugPrint('🛒 User authenticated, showing cart');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            debugPrint('🛒 Cart items count: ${cartProvider.items.length}');
            debugPrint('🛒 Cart isNotEmpty: ${cartProvider.items.isNotEmpty}');
            final cartItems = cartProvider.items;
            final totals = _calculateTotals(cartItems);
            final subtotal = totals['subtotal']!;
            final shipping = totals['shipping']!;
            final tax = totals['tax']!;
            final total = totals['total']!;

            return Column(
              children: [
                // Header "Cart" avec Clear All
                _buildHeader(cartItems.isNotEmpty),

                // Contenu scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_error != null)
                          _buildErrorState()
                        else if (cartItems.isEmpty)
                          _buildEmptyState()
                        else ...[
                          // Liste des produits
                          ...cartItems.map((item) => CartProductCard(
                            item: item,
                            onQuantityChange: (newQty) => _updateQuantity(item.id, newQty),
                            onRemove: () => _removeItem(item.id),
                          )),

                          const SizedBox(height: 16),

                          // Résumé des coûts
                          CostSummary(
                            subtotal: subtotal,
                            shipping: shipping,
                            tax: tax,
                            total: total,
                            discount: _discount,
                            promoCode: _appliedPromoCode,
                          ),

                          const SizedBox(height: 12),

                          // Champ code promo
                          PromoCodeField(
                            controller: _promoCodeController,
                            appliedCode: _appliedPromoCode,
                            onApply: () => _applyPromoCode(subtotal),
                            onRemove: _removePromoCode,
                          ),

                          const SizedBox(height: 16),

                          // Bouton Checkout
                          _buildCheckoutButton(cartItems, total),

                          // Espace pour bottom nav
                          const SizedBox(height: 86),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasItems) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Espace pour équilibrer
          const SizedBox(width: 70),
          
          // Titre centré
          const Expanded(
            child: Text(
              'Cart',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF0066CC),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Bouton Clear All
          if (hasItems)
            TextButton(
              onPressed: _showClearCartDialog,
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
          else
            const SizedBox(width: 70),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllItems() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clearCart();
    
    // Reset promo code
    setState(() {
      _discount = 0.0;
      _appliedPromoCode = null;
      _promoCodeController.clear();
    });
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cart cleared'),
        backgroundColor: Color(0xFF0066CC),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(
          color: Color(0xFF0066CC),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              'Error: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _error = null);
                _refreshCart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Naviguer vers HomeScreen et sélectionner l'onglet Products (index 1)
                context.go('/home?tab=1');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedCornerShape(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Start Shopping',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton(List<CartItem> cartItems, double total) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _processCheckout(cartItems, total),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6600),
          shape: RoundedCornerShape(borderRadius: BorderRadius.circular(10)),
          elevation: 6,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Checkout',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildRequireLoginScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0066CC), Color(0xFF073050)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Unlock the Full Experience!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign in or create an account to add items to your cart and enjoy exclusive shopping features.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go('/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0066CC),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedCornerShape(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go('/signup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6600),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedCornerShape(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte produit dans le panier style Kotlin
class CartProductCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChange;
  final VoidCallback onRemove;

  const CartProductCard({
    super.key,
    required this.item,
    required this.onQuantityChange,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.product.imageUrls.isNotEmpty 
        ? item.product.imageUrls.first 
        : '';
    final price = item.product.discountPrice ?? item.product.price;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedCornerChoice(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image produit
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 30,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Détails produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Size / Color
                  if (item.selectedSize != null || item.selectedColor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (item.selectedSize != null) 'Size: ${item.selectedSize}',
                        if (item.selectedColor != null) 'Color: ${item.selectedColor}',
                      ].join('  •  '),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Prix orange
                  Text(
                    '${price.toStringAsFixed(2)}\$',
                    style: const TextStyle(
                      color: Color(0xFFFF5722),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Contrôles quantité et suppression
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Bouton supprimer (X rouge)
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Quantité -/+
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: '-',
                      onTap: () {
                        if (item.quantity > 1) {
                          onQuantityChange(item.quantity - 1);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: '+',
                      onTap: () => onQuantityChange(item.quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({required String icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFFE0E0E0),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            icon,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/// Résumé des coûts style Kotlin
class CostSummary extends StatelessWidget {
  final double subtotal;
  final double shipping;
  final double tax;
  final double total;
  final double discount;
  final String? promoCode;

  const CostSummary({
    super.key,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
    this.discount = 0.0,
    this.promoCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow('Subtotal', '${subtotal.toStringAsFixed(2)} \$'),
        const SizedBox(height: 4),
        _buildRow('Shipping', '${shipping.toStringAsFixed(2)} \$'),
        const SizedBox(height: 4),
        _buildRow('Tax', '${tax.toStringAsFixed(2)} \$'),
        if (discount > 0) ...[
          const SizedBox(height: 4),
          _buildRow(
            'Discount ($promoCode)',
            '-${discount.toStringAsFixed(2)} \$',
            isDiscount: true,
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '${total.toStringAsFixed(2)} \$',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.green : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount ? Colors.green : null,
            fontWeight: isDiscount ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

/// Champ code promo style Kotlin
class PromoCodeField extends StatelessWidget {
  final TextEditingController controller;
  final String? appliedCode;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const PromoCodeField({
    super.key,
    required this.controller,
    required this.appliedCode,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (appliedCode == null)
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Enter your code',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.percent,
                    color: Color(0xFF0B74DA),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onApply,
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        color: Color(0xFF0B74DA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0B74DA)),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Promo code "$appliedCode" applied!',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRemove,
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Alias pour RoundedRectangleBorder (compatibilité)
class RoundedCornerShape extends RoundedRectangleBorder {
  RoundedCornerShape({required BorderRadius borderRadius})
      : super(borderRadius: borderRadius);
}

/// Alias alternatif
class RoundedCornerChoice extends RoundedRectangleBorder {
  RoundedCornerChoice({required BorderRadius borderRadius})
      : super(borderRadius: borderRadius);
}
