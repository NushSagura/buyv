// Firestore removed: use DateTime ISO strings or epoch for serialization

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  canceled,
  returned,
  refunded
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.canceled:
        return 'Canceled';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String orderNumber;
  final List<OrderItem> items;
  final OrderStatus status;
  final double subtotal;
  final double shipping;
  final double tax;
  final double total;
  final Address? shippingAddress;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? estimatedDelivery;
  final String? trackingNumber;
  final String notes;
  final String? promoterId; // ID of the user who promoted the product (for commission)

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
    this.shippingAddress,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedDelivery,
    this.trackingNumber,
    this.notes = '',
    this.promoterId,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      id: map['id'] ?? documentId,
      userId: map['userId'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ??
          [],
      status: OrderStatusExtension.fromString(map['status'] ?? 'pending'),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      shipping: (map['shipping'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      shippingAddress: map['shippingAddress'] != null
          ? Address.fromMap(map['shippingAddress'])
          : null,
      paymentMethod: map['paymentMethod'] ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
      estimatedDelivery: _parseDate(map['estimatedDelivery']),
      trackingNumber: map['trackingNumber'],
      notes: map['notes'] ?? '',
      promoterId: map['promoterId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.name,
      'subtotal': subtotal,
      'shipping': shipping,
      'tax': tax,
      'total': total,
      'shippingAddress': shippingAddress?.toMap(),
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      'trackingNumber': trackingNumber,
      'notes': notes,
      'promoterId': promoterId,
    };
  }

  // Helper to parse various date formats
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    if (value is int) {
      try {
        // assume milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }
    if (value is Map) {
      // Firestore-like {seconds: x, nanoseconds: y}
      final seconds = value['seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    return null;
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? orderNumber,
    List<OrderItem>? items,
    OrderStatus? status,
    double? subtotal,
    double? shipping,
    double? tax,
    double? total,
    Address? shippingAddress,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? estimatedDelivery,
    String? trackingNumber,
    String? notes,
    String? promoterId,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      shipping: shipping ?? this.shipping,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      notes: notes ?? this.notes,
      promoterId: promoterId ?? this.promoterId,
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String? size;
  final String? color;
  final Map<String, String> attributes;
  final bool isPromotedProduct; // Whether this is a CJ Dropshipping promoted product
  final String? promoterId; // ID of the user who promoted this product

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    this.size,
    this.color,
    this.attributes = const {},
    this.isPromotedProduct = false,
    this.promoterId,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      size: map['size'],
      color: map['color'],
      attributes: Map<String, String>.from(map['attributes'] ?? {}),
      isPromotedProduct: map['isPromotedProduct'] ?? false,
      promoterId: map['promoterId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'size': size,
      'color': color,
      'attributes': attributes,
      'isPromotedProduct': isPromotedProduct,
      'promoterId': promoterId,
    };
  }

  double get totalPrice => price * quantity;
}

class Address {
  final String id;
  final String name;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String phone;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.phone,
    this.isDefault = false,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      country: map['country'] ?? '',
      phone: map['phone'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phone': phone,
      'isDefault': isDefault,
    };
  }

  String get fullAddress => '$street, $city, $state $zipCode, $country';
}