import 'product_model.dart';

class CartItem {
  final String id;
  final ProductModel product;
  final int quantity;
  final String? selectedSize;
  final String? selectedColor;
  final Map<String, dynamic>? selectedAttributes;
  final DateTime addedAt;
  final String? promoterId; // معرف المروج

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedSize,
    this.selectedColor,
    this.selectedAttributes,
    required this.addedAt,
    this.promoterId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      product: ProductModel.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 1,
      selectedSize: json['selectedSize'],
      selectedColor: json['selectedColor'],
      selectedAttributes: json['selectedAttributes'],
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
      promoterId: json['promoterId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'selectedAttributes': selectedAttributes,
      'addedAt': addedAt.toIso8601String(),
      'promoterId': promoterId,
    };
  }

  CartItem copyWith({
    String? id,
    ProductModel? product,
    int? quantity,
    String? selectedSize,
    String? selectedColor,
    Map<String, dynamic>? selectedAttributes,
    DateTime? addedAt,
    String? promoterId,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedAttributes: selectedAttributes ?? this.selectedAttributes,
      addedAt: addedAt ?? this.addedAt,
      promoterId: promoterId ?? this.promoterId,
    );
  }

  double get totalPrice {
    final price = product.discountPrice ?? product.price;
    return price * quantity;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CartItem(id: $id, product: ${product.name}, quantity: $quantity)';
  }
}

class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Cart copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get shipping => subtotal > 100 ? 0.0 : 10.0; // Free shipping over $100

  double get tax => subtotal * 0.08; // 8% tax

  double get total => subtotal + shipping + tax;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  CartItem? findItemByProductId(String productId) {
    try {
      return items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  bool containsProduct(String productId) {
    return items.any((item) => item.product.id == productId);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cart && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Cart(id: $id, userId: $userId, items: ${items.length})';
  }
}