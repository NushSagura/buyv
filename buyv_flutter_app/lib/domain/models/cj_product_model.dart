class CJProduct {
  final String pid;
  final String productName;
  final String productNameEn;
  final String productSku;
  final double sellPrice;
  final double originalPrice;
  final String productImage;
  final List<String> productImages;
  final String categoryId;
  final String categoryName;
  final String description;
  final String descriptionEn;
  final int sellCount;
  final double rating;
  final int reviewCount;
  final List<CJProductVariant> variants;
  final Map<String, dynamic> specifications;
  final bool isAvailable;
  final String sourceUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // New fields for enhanced functionality
  final int? deliveryTime; // Delivery time in days
  final bool? verifiedWarehouse; // Whether product is from verified warehouse
  final String? customizationVersion; // Product customization version
  final bool? hasInventory; // Whether product has inventory
  final String? countryCode; // Country code for shipping
  final double? weight; // Product weight
  final String? dimensions; // Product dimensions
  final List<String>? tags; // Product tags
  final Map<String, dynamic>? shippingInfo; // Shipping information
  final Map<String, dynamic>? supplierInfo; // Supplier information

  CJProduct({
    required this.pid,
    required this.productName,
    required this.productNameEn,
    required this.productSku,
    required this.sellPrice,
    required this.originalPrice,
    required this.productImage,
    required this.productImages,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.descriptionEn,
    required this.sellCount,
    required this.rating,
    required this.reviewCount,
    required this.variants,
    required this.specifications,
    required this.isAvailable,
    required this.sourceUrl,
    required this.createdAt,
    required this.updatedAt,
    // New optional parameters
    this.deliveryTime,
    this.verifiedWarehouse,
    this.customizationVersion,
    this.hasInventory,
    this.countryCode,
    this.weight,
    this.dimensions,
    this.tags,
    this.shippingInfo,
    this.supplierInfo,
  });

  factory CJProduct.fromJson(Map<String, dynamic> json) {
    return CJProduct(
      pid: json['pid'] ?? '',
      productName: json['productName'] ?? '',
      productNameEn: json['productNameEn'] ?? '',
      productSku: json['productSku'] ?? '',
      sellPrice: (json['sellPrice'] ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      productImage: json['productImage'] ?? '',
      productImages: List<String>.from(json['productImages'] ?? []),
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      description: json['description'] ?? '',
      descriptionEn: json['descriptionEn'] ?? '',
      sellCount: json['sellCount'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => CJProductVariant.fromJson(v))
              .toList() ??
          [],
      specifications: json['specifications'] ?? {},
      isAvailable: json['isAvailable'] ?? true,
      sourceUrl: json['sourceUrl'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      // New fields
      deliveryTime: json['deliveryTime'],
      verifiedWarehouse: json['verifiedWarehouse'],
      customizationVersion: json['customizationVersion'],
      hasInventory: json['hasInventory'],
      countryCode: json['countryCode'],
      weight: json['weight']?.toDouble(),
      dimensions: json['dimensions'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      shippingInfo: json['shippingInfo'],
      supplierInfo: json['supplierInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pid': pid,
      'productName': productName,
      'productNameEn': productNameEn,
      'productSku': productSku,
      'sellPrice': sellPrice,
      'originalPrice': originalPrice,
      'productImage': productImage,
      'productImages': productImages,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'descriptionEn': descriptionEn,
      'sellCount': sellCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'variants': variants.map((v) => v.toJson()).toList(),
      'specifications': specifications,
      'isAvailable': isAvailable,
      'sourceUrl': sourceUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // New fields
      'deliveryTime': deliveryTime,
      'verifiedWarehouse': verifiedWarehouse,
      'customizationVersion': customizationVersion,
      'hasInventory': hasInventory,
      'countryCode': countryCode,
      'weight': weight,
      'dimensions': dimensions,
      'tags': tags,
      'shippingInfo': shippingInfo,
      'supplierInfo': supplierInfo,
    };
  }

  // Calculate commission for this product
  double get commission => sellPrice * 0.01; // 1%

  // Get discount percentage
  double get discountPercentage {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - sellPrice) / originalPrice) * 100;
  }

  // Check if product is on sale
  bool get isOnSale => originalPrice > sellPrice;

  CJProduct copyWith({
    String? pid,
    String? productName,
    String? productNameEn,
    String? productSku,
    double? sellPrice,
    double? originalPrice,
    String? productImage,
    List<String>? productImages,
    String? categoryId,
    String? categoryName,
    String? description,
    String? descriptionEn,
    int? sellCount,
    double? rating,
    int? reviewCount,
    List<CJProductVariant>? variants,
    Map<String, dynamic>? specifications,
    bool? isAvailable,
    String? sourceUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    // New optional parameters
    int? deliveryTime,
    bool? verifiedWarehouse,
    String? customizationVersion,
    bool? hasInventory,
    String? countryCode,
    double? weight,
    String? dimensions,
    List<String>? tags,
    Map<String, dynamic>? shippingInfo,
    Map<String, dynamic>? supplierInfo,
  }) {
    return CJProduct(
      pid: pid ?? this.pid,
      productName: productName ?? this.productName,
      productNameEn: productNameEn ?? this.productNameEn,
      productSku: productSku ?? this.productSku,
      sellPrice: sellPrice ?? this.sellPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      productImage: productImage ?? this.productImage,
      productImages: productImages ?? this.productImages,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      sellCount: sellCount ?? this.sellCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      variants: variants ?? this.variants,
      specifications: specifications ?? this.specifications,
      isAvailable: isAvailable ?? this.isAvailable,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // New fields
      deliveryTime: deliveryTime ?? this.deliveryTime,
      verifiedWarehouse: verifiedWarehouse ?? this.verifiedWarehouse,
      customizationVersion: customizationVersion ?? this.customizationVersion,
      hasInventory: hasInventory ?? this.hasInventory,
      countryCode: countryCode ?? this.countryCode,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      tags: tags ?? this.tags,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      supplierInfo: supplierInfo ?? this.supplierInfo,
    );
  }
}

class CJProductVariant {
  final String vid;
  final String variantName;
  final String variantNameEn;
  final String variantSku;
  final double price;
  final String image;
  final Map<String, String> attributes; // color, size, etc.
  final int stock;
  final bool isAvailable;

  CJProductVariant({
    required this.vid,
    required this.variantName,
    required this.variantNameEn,
    required this.variantSku,
    required this.price,
    required this.image,
    required this.attributes,
    required this.stock,
    required this.isAvailable,
  });

  factory CJProductVariant.fromJson(Map<String, dynamic> json) {
    return CJProductVariant(
      vid: json['vid'] ?? '',
      variantName: json['variantName'] ?? '',
      variantNameEn: json['variantNameEn'] ?? '',
      variantSku: json['variantSku'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? '',
      attributes: Map<String, String>.from(json['attributes'] ?? {}),
      stock: json['stock'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vid': vid,
      'variantName': variantName,
      'variantNameEn': variantNameEn,
      'variantSku': variantSku,
      'price': price,
      'image': image,
      'attributes': attributes,
      'stock': stock,
      'isAvailable': isAvailable,
    };
  }
}

class CJCategory {
  final String categoryId;
  final String categoryName;
  final String categoryNameEn;
  final String parentId;
  final int level;
  final String image;
  final int productCount;

  CJCategory({
    required this.categoryId,
    required this.categoryName,
    required this.categoryNameEn,
    required this.parentId,
    required this.level,
    required this.image,
    required this.productCount,
  });

  factory CJCategory.fromJson(Map<String, dynamic> json) {
    return CJCategory(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      categoryNameEn: json['categoryNameEn'] ?? '',
      parentId: json['parentId'] ?? '',
      level: json['level'] ?? 0,
      image: json['image'] ?? '',
      productCount: json['productCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryNameEn': categoryNameEn,
      'parentId': parentId,
      'level': level,
      'image': image,
      'productCount': productCount,
    };
  }
}

// Model for tracking user commissions
class UserCommission {
  final String id;
  final String userId;
  final String orderId;
  final String productId;
  final String reelId; // The reel that promoted this product
  final double orderAmount;
  final double commissionAmount;
  final String status; // pending, paid, cancelled
  final DateTime createdAt;
  final DateTime? paidAt;

  UserCommission({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.productId,
    required this.reelId,
    required this.orderAmount,
    required this.commissionAmount,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  factory UserCommission.fromJson(Map<String, dynamic> json) {
    return UserCommission(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      orderId: json['orderId'] ?? '',
      productId: json['productId'] ?? '',
      reelId: json['reelId'] ?? '',
      orderAmount: (json['orderAmount'] ?? 0).toDouble(),
      commissionAmount: (json['commissionAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderId': orderId,
      'productId': productId,
      'reelId': reelId,
      'orderAmount': orderAmount,
      'commissionAmount': commissionAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}

// CJ Dropshipping Settings Models
class CJSettings {
  final String openId;
  final String openName;
  final String openEmail;
  final CJSettingDetails setting;
  final CJCallback callback;
  final String root;
  final bool isSandbox;

  CJSettings({
    required this.openId,
    required this.openName,
    required this.openEmail,
    required this.setting,
    required this.callback,
    required this.root,
    required this.isSandbox,
  });

  factory CJSettings.fromJson(Map<String, dynamic> json) {
    return CJSettings(
      openId: json['openId']?.toString() ?? '',
      openName: json['openName'] ?? '',
      openEmail: json['openEmail'] ?? '',
      setting: CJSettingDetails.fromJson(json['setting'] ?? {}),
      callback: CJCallback.fromJson(json['callback'] ?? {}),
      root: json['root'] ?? '',
      isSandbox: json['isSandbox'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'openId': openId,
      'openName': openName,
      'openEmail': openEmail,
      'setting': setting.toJson(),
      'callback': callback.toJson(),
      'root': root,
      'isSandbox': isSandbox,
    };
  }
}

class CJSettingDetails {
  final List<CJQuotaLimit> quotaLimits;
  final int qpsLimit;

  CJSettingDetails({
    required this.quotaLimits,
    required this.qpsLimit,
  });

  factory CJSettingDetails.fromJson(Map<String, dynamic> json) {
    final quotaLimitsList = json['quotaLimits'] as List<dynamic>? ?? [];
    return CJSettingDetails(
      quotaLimits: quotaLimitsList
          .map((item) => CJQuotaLimit.fromJson(item as Map<String, dynamic>))
          .toList(),
      qpsLimit: json['qpsLimit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quotaLimits': quotaLimits.map((item) => item.toJson()).toList(),
      'qpsLimit': qpsLimit,
    };
  }
}

class CJQuotaLimit {
  final String quotaUrl;
  final int quotaLimit;
  final int quotaType;

  CJQuotaLimit({
    required this.quotaUrl,
    required this.quotaLimit,
    required this.quotaType,
  });

  factory CJQuotaLimit.fromJson(Map<String, dynamic> json) {
    return CJQuotaLimit(
      quotaUrl: json['quotaUrl'] ?? '',
      quotaLimit: json['quotaLimit'] ?? 0,
      quotaType: json['quotaType'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quotaUrl': quotaUrl,
      'quotaLimit': quotaLimit,
      'quotaType': quotaType,
    };
  }

  // Helper method to get quota type description
  String get quotaTypeDescription {
    switch (quotaType) {
      case 0:
        return 'Total';
      case 1:
        return 'Per Year';
      case 2:
        return 'Per Quarter';
      case 3:
        return 'Per Month';
      case 4:
        return 'Per Day';
      case 5:
        return 'Per Hour';
      default:
        return 'Unknown';
    }
  }
}

// Product Sourcing Models
class CJSourcingRequest {
  final String? id;
  final String productName;
  final String productUrl;
  final String targetPrice;
  final int quantity;
  final String description;
  final List<String>? images;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? remarks;

  CJSourcingRequest({
    this.id,
    required this.productName,
    required this.productUrl,
    required this.targetPrice,
    required this.quantity,
    required this.description,
    this.images,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.remarks,
  });

  factory CJSourcingRequest.fromJson(Map<String, dynamic> json) {
    return CJSourcingRequest(
      id: json['id'],
      productName: json['productName'] ?? '',
      productUrl: json['productUrl'] ?? '',
      targetPrice: json['targetPrice'] ?? '',
      quantity: json['quantity'] ?? 1,
      description: json['description'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'productUrl': productUrl,
      'targetPrice': targetPrice,
      'quantity': quantity,
      'description': description,
      'images': images,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'remarks': remarks,
    };
  }
}

class CJCallback {
  final CJCallbackConfig product;
  final CJCallbackConfig order;

  CJCallback({
    required this.product,
    required this.order,
  });

  factory CJCallback.fromJson(Map<String, dynamic> json) {
    return CJCallback(
      product: CJCallbackConfig.fromJson(json['product'] ?? {}),
      order: CJCallbackConfig.fromJson(json['order'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'order': order.toJson(),
    };
  }
}

class CJCallbackConfig {
  final String type;
  final List<String> urls;

  CJCallbackConfig({
    required this.type,
    required this.urls,
  });

  factory CJCallbackConfig.fromJson(Map<String, dynamic> json) {
    final urlsList = json['urls'] as List<dynamic>? ?? [];
    return CJCallbackConfig(
      type: json['type'] ?? '',
      urls: urlsList.map((url) => url.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'urls': urls,
    };
  }
}