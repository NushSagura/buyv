import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/cart_model.dart';
import '../../providers/auth_provider.dart';

import '../../widgets/require_login_prompt.dart';
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  String? _error;
  List<CartItem> _cartItems = [];
  double _subtotal = 0.0;
  final double _shipping = 5.0;
  double _tax = 0.0;
  double _total = 0.0;
  double _discount = 0.0;
  String? _appliedPromoCode;
  final TextEditingController _promoCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCartData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load actual cart data from Firebase or other data source
      // For now, initialize empty cart
      _cartItems = [];

      _calculateTotals();
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

  void _calculateTotals() {
    _subtotal = _cartItems.fold(0.0, (sum, item) => 
        sum + ((item.product.discountPrice ?? item.product.price) * item.quantity));
    _tax = _subtotal * 0.08; // 8% tax
    _total = _subtotal + _shipping + _tax - _discount;
  }

  void _updateQuantity(String itemId, int newQuantity) {
    setState(() {
      final itemIndex = _cartItems.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        if (newQuantity > 0) {
          _cartItems[itemIndex] = _cartItems[itemIndex].copyWith(quantity: newQuantity);
        } else {
          _cartItems.removeAt(itemIndex);
        }
        _calculateTotals();
      }
    });
  }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a promo code')),
      );
      return;
    }

    // Simulate promo code validation
    Map<String, double> validCodes = {
      'SAVE10': 0.10, // 10% discount
      'SAVE20': 0.20, // 20% discount
      'WELCOME': 0.15, // 15% discount
      'FIRST': 0.25, // 25% discount for first-time users
    };

    if (validCodes.containsKey(code)) {
      setState(() {
        _discount = _subtotal * validCodes[code]!;
        _appliedPromoCode = code;
        _calculateTotals();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promo code applied! You saved \$${_discount.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      _calculateTotals();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Promo code removed')),
    );
  }

  Future<void> _saveCart() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Simulate saving cart to storage
      await Future.delayed(Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cart saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  void _clearError() {
    setState(() {
      _error = null;
    });
  }

  void _refreshCart() {
    _loadCartData();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Provider.of<AuthProvider>(context).currentUser;

    if (authUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: RequireLoginPrompt(
          onLogin: () {
            Navigator.pushNamed(context, '/login');
          },
          onSignUp: () {
            Navigator.pushNamed(context, '/signup');
          },
          onDismiss: () {},
          showCloseButton: false,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 48,
              width: double.infinity,
              alignment: Alignment.center,
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
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_isLoading)
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          color: Color(0xFF0066CC),
                        ),
                      )
                    else if (_error != null)
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Text(
                              'Error: $_error',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                _clearError();
                                _refreshCart();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0066CC),
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_cartItems.isEmpty)
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      // Cart Items
                      ...(_cartItems.map((item) => _buildCartProductCard(item))),
                      
                      const SizedBox(height: 16),
                      
                      // Cost Summary
                      _buildCostSummary(),
                      
                      const SizedBox(height: 12),
                      
                      // Promo Code Field
                      _buildPromoCodeField(),
                      
                      const SizedBox(height: 16),
                      
                      // Checkout Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/payment');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF6600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 6,
                          ),
                          child: Text(
                            'Checkout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 86),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartProductCard(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: item.product.imageUrls.isNotEmpty
                    ? Image.network(
                        item.product.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                          );
                        },
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
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.selectedSize != null || item.selectedColor != null) ...[
                     const SizedBox(height: 4),
                     Text(
                       [
                         if (item.selectedSize != null) 'Size: ${item.selectedSize}',
                         if (item.selectedColor != null) 'Color: ${item.selectedColor}',
                       ].join('  •  '),
                       style: TextStyle(
                         color: Colors.grey,
                         fontSize: 12,
                       ),
                     ),
                   ],
                  const SizedBox(height: 8),
                  Text(
                    '\$${(item.product.discountPrice ?? item.product.price).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Color(0xFFFF5722),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity Controls
            Row(
              children: [
                GestureDetector(
                   onTap: () {
                     if (item.quantity > 1) {
                       _updateQuantity(item.id, item.quantity - 1);
                     }
                   },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                
                GestureDetector(
                   onTap: () {
                     _updateQuantity(item.id, item.quantity + 1);
                   },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSummary() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Subtotal',
                style: TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('\$${_subtotal.toStringAsFixed(2)}'),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Shipping',
                style: TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('\$${_shipping.toStringAsFixed(2)}'),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Tax',
                style: TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('\$${_tax.toStringAsFixed(2)}'),
          ],
        ),
        if (_discount > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Discount ($_appliedPromoCode)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '-\$${_discount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '\$${_total.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoCodeField() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoCodeController,
                decoration: InputDecoration(
                  labelText: 'Enter your code',
                  suffixIcon: Icon(
                    Icons.percent,
                    color: Color(0xFF0B74DA),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _appliedPromoCode == null ? _applyPromoCode : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0B74DA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Apply',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        if (_appliedPromoCode != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Promo code "$_appliedPromoCode" applied!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _removePromoCode,
                  child: Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveCart,
                icon: Icon(Icons.save),
                label: Text('Save Cart'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Extension is not needed as CartItem already has copyWith method