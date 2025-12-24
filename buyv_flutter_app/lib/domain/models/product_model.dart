class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String category;
  final List<String> imageUrls;
  final String? videoUrl;
  final int stockQuantity;
  final bool isAvailable;
  final double rating;
  final int reviewsCount;
  final String sellerId;
  final String sellerName;
  final List<String> tags;
  final Map<String, dynamic>? specifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewsCount;
  final int likesCount;
  final bool isFeatured;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.category,
    required this.imageUrls,
    this.videoUrl,
    required this.stockQuantity,
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviewsCount = 0,
    required this.sellerId,
    required this.sellerName,
    this.tags = const [],
    this.specifications,
    required this.createdAt,
    required this.updatedAt,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.isFeatured = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice']?.toDouble(),
      category: json['category'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      videoUrl: json['videoUrl'],
      stockQuantity: json['stockQuantity'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      sellerId: json['sellerId'] ?? '',
      sellerName: json['sellerName'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      specifications: json['specifications'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      viewsCount: json['viewsCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'category': category,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'tags': tags,
      'specifications': specifications,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'isFeatured': isFeatured,
    };
  }

  double get finalPrice => discountPrice ?? price;
  
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  
  double get discountPercentage {
    if (!hasDiscount) return 0.0;
    return ((price - discountPrice!) / price * 100);
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? category,
    List<String>? imageUrls,
    String? videoUrl,
    int? stockQuantity,
    bool? isAvailable,
    double? rating,
    int? reviewsCount,
    String? sellerId,
    String? sellerName,
    List<String>? tags,
    Map<String, dynamic>? specifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewsCount,
    int? likesCount,
    bool? isFeatured,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      tags: tags ?? this.tags,
      specifications: specifications ?? this.specifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}