import 'package:flutter/foundation.dart';
import '../../domain/models/cart_model.dart';
import '../../domain/models/product_model.dart';
import '../../services/secure_storage_service.dart';

class CartProvider extends ChangeNotifier {
  Cart _cart = Cart(
    id: 'default_cart',
    userId: 'current_user',
    items: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Discount related properties
  String? _appliedDiscountCode;
  double _discountAmount = 0.0;
  double _discountPercentage = 0.0;

  Cart get cart => _cart;
  
  List<CartItem> get items => _cart.items;
  
  int get totalItems => _cart.totalItems;
  
  int get itemCount => _cart.totalItems; // Add itemCount property
  
  double get subtotal => _cart.subtotal;
  
  double get shipping => _cart.shipping;
  
  double get tax => _cart.tax;
  
  double get total => _cart.total - _discountAmount;
  
  bool get isEmpty => _cart.isEmpty;
  
  bool get isNotEmpty => _cart.isNotEmpty;

  // Discount getters
  String? get appliedDiscountCode => _appliedDiscountCode;
  double get discountAmount => _discountAmount;
  double get discountPercentage => _discountPercentage;

  // Add item to cart
  void addToCart(ProductModel product, {
    int quantity = 1,
    String? selectedSize,
    String? selectedColor,
    Map<String, dynamic>? selectedAttributes,
    String? promoterId,
  }) {
    final existingItemIndex = _cart.items.indexWhere(
      (item) => item.product.id == product.id &&
                item.selectedSize == selectedSize &&
                item.selectedColor == selectedColor,
    );

    if (existingItemIndex != -1) {
      // Update existing item quantity
      final existingItem = _cart.items[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      
      final updatedItems = List<CartItem>.from(_cart.items);
      updatedItems[existingItemIndex] = updatedItem;
      
      _cart = _cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
    } else {
      // Add new item
      final newItem = CartItem(
        id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
        product: product,
        quantity: quantity,
        selectedSize: selectedSize,
        selectedColor: selectedColor,
        selectedAttributes: selectedAttributes,
        addedAt: DateTime.now(),
        promoterId: promoterId,
      );

      final updatedItems = List<CartItem>.from(_cart.items)..add(newItem);
      
      _cart = _cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
    }
    
    // Auto-save cart after adding item
    saveCart();
    notifyListeners();
  }

  // Remove item from cart
  void removeFromCart(String itemId) {
    final updatedItems = _cart.items.where((item) => item.id != itemId).toList();
    
    _cart = _cart.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );
    
    // Auto-save cart after removing item
    saveCart();
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(itemId);
      return;
    }

    final itemIndex = _cart.items.indexWhere((item) => item.id == itemId);
    
    if (itemIndex != -1) {
      final updatedItem = _cart.items[itemIndex].copyWith(quantity: newQuantity);
      final updatedItems = List<CartItem>.from(_cart.items);
      updatedItems[itemIndex] = updatedItem;
      
      _cart = _cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      
      // Auto-save cart after updating quantity
      saveCart();
      notifyListeners();
    }
  }

  // Increment item quantity
  void incrementQuantity(String itemId) {
    final item = _cart.items.firstWhere((item) => item.id == itemId);
    updateQuantity(itemId, item.quantity + 1);
  }

  // Decrement item quantity
  void decrementQuantity(String itemId) {
    final item = _cart.items.firstWhere((item) => item.id == itemId);
    updateQuantity(itemId, item.quantity - 1);
  }

  // Clear cart
  void clearCart() {
    _cart = _cart.copyWith(
      items: [],
      updatedAt: DateTime.now(),
    );
    
    // Clear discount when clearing cart
    _appliedDiscountCode = null;
    _discountAmount = 0.0;
    _discountPercentage = 0.0;
    
    // Auto-save cart after clearing
    saveCart();
    notifyListeners();
  }

  // Check if product is in cart
  bool isProductInCart(String productId) {
    return _cart.containsProduct(productId);
  }

  // Get product quantity in cart
  int getProductQuantity(String productId) {
    final item = _cart.findItemByProductId(productId);
    return item?.quantity ?? 0;
  }

  // Get cart item by product ID
  CartItem? getCartItemByProductId(String productId) {
    return _cart.findItemByProductId(productId);
  }

  // Load cart from secure storage
  Future<void> loadCart() async {
    try {
      // Load cart data from secure storage
      final cartData = await SecureStorageService.getUserData('user_cart');
      
      if (cartData != null) {
        // Parse cart data
        final cartItems = <CartItem>[];
        if (cartData['items'] != null) {
          for (final itemData in cartData['items']) {
            try {
              final cartItem = CartItem.fromJson(itemData);
              cartItems.add(cartItem);
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing cart item: $e');
              }
            }
          }
        }
        
        // Update cart with loaded data
        _cart = Cart(
          id: cartData['id'] ?? 'default_cart',
          userId: cartData['userId'] ?? 'current_user',
          items: cartItems,
          createdAt: DateTime.tryParse(cartData['createdAt'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(cartData['updatedAt'] ?? '') ?? DateTime.now(),
        );
        
        // Load discount information
        _appliedDiscountCode = cartData['appliedDiscountCode'];
        _discountAmount = (cartData['discountAmount'] ?? 0.0).toDouble();
        _discountPercentage = (cartData['discountPercentage'] ?? 0.0).toDouble();
        
        if (kDebugMode) {
          print('✅ Cart loaded successfully with ${_cart.items.length} items');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ No saved cart found, using empty cart');
        }
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading cart: $e');
      }
      // Keep current cart if loading fails
    }
  }

  // Save cart to secure storage
  Future<void> saveCart() async {
    try {
      final cartData = {
        'id': _cart.id,
        'userId': _cart.userId,
        'items': _cart.items.map((item) => item.toJson()).toList(),
        'createdAt': _cart.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'appliedDiscountCode': _appliedDiscountCode,
        'discountAmount': _discountAmount,
        'discountPercentage': _discountPercentage,
      };
      
      await SecureStorageService.storeUserData('user_cart', cartData);
      
      if (kDebugMode) {
        print('✅ Cart saved successfully with ${_cart.items.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving cart: $e');
      }
    }
  }

  // Apply discount code with validation
  Future<void> applyDiscountCode(String code) async {
    try {
      // Validate discount code format
      if (code.trim().isEmpty) {
        throw Exception('كود الخصم فارغ');
      }
      
      // Simulate discount code validation (replace with actual API call)
      final discountInfo = await _validateDiscountCode(code.trim().toUpperCase());
      
      if (discountInfo != null) {
        _appliedDiscountCode = code.trim().toUpperCase();
        _discountPercentage = discountInfo['percentage'] ?? 0.0;
        
        // Calculate discount amount based on subtotal
        final subtotalAmount = _cart.subtotal;
        _discountAmount = (subtotalAmount * _discountPercentage / 100).clamp(0.0, subtotalAmount);
        
        // Apply maximum discount limit if specified
        final maxDiscount = discountInfo['maxAmount'];
        if (maxDiscount != null && _discountAmount > maxDiscount) {
          _discountAmount = maxDiscount.toDouble();
        }
        
        // Save cart with applied discount
        await saveCart();
        
        if (kDebugMode) {
          print('✅ Discount code applied: $code (${_discountPercentage}% = \$${_discountAmount.toStringAsFixed(2)})');
        }
        
        notifyListeners();
      } else {
        throw Exception('كود الخصم غير صالح أو منتهي الصلاحية');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error applying discount code: $e');
      }
      rethrow;
    }
  }

  // Remove applied discount code
  Future<void> removeDiscountCode() async {
    try {
      _appliedDiscountCode = null;
      _discountAmount = 0.0;
      _discountPercentage = 0.0;
      
      // Save cart without discount
      await saveCart();
      
      if (kDebugMode) {
        print('✅ Discount code removed');
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing discount code: $e');
      }
    }
  }

  // Private method to validate discount codes
  Future<Map<String, dynamic>?> _validateDiscountCode(String code) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Sample discount codes for testing (replace with actual API call)
    final discountCodes = {
      'WELCOME10': {'percentage': 10.0, 'maxAmount': 50.0, 'active': true},
      'SAVE20': {'percentage': 20.0, 'maxAmount': 100.0, 'active': true},
      'FIRST15': {'percentage': 15.0, 'maxAmount': 75.0, 'active': true},
      'SUMMER25': {'percentage': 25.0, 'maxAmount': 150.0, 'active': true},
      'EXPIRED': {'percentage': 30.0, 'maxAmount': 200.0, 'active': false},
    };
    
    final discountInfo = discountCodes[code];
    
    if (discountInfo != null && discountInfo['active'] == true) {
      return discountInfo;
    }
    
    return null; // Invalid or expired code
  }

  // Get discount summary for UI display
  Map<String, dynamic> getDiscountSummary() {
    return {
      'hasDiscount': _appliedDiscountCode != null,
      'code': _appliedDiscountCode,
      'percentage': _discountPercentage,
      'amount': _discountAmount,
      'originalTotal': _cart.total,
      'finalTotal': total,
      'savings': _discountAmount,
    };
  }
}