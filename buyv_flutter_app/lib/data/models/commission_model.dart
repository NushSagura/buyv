class CommissionModel {
  final String id;
  final String userId;
  final String userName;
  final String postId;
  final String productId;
  final String productName;
  final double productPrice;
  final double commissionRate; // 0.01 for 1%
  final double commissionAmount;
  final String status; // pending, paid, cancelled
  final DateTime createdAt;
  final DateTime? paidAt;
  final Map<String, dynamic>? metadata;

  CommissionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.postId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.commissionRate,
    required this.commissionAmount,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.metadata,
  });

  factory CommissionModel.fromMap(Map<String, dynamic> map) {
    return CommissionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      postId: map['postId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productPrice: (map['productPrice'] ?? 0).toDouble(),
      commissionRate: (map['commissionRate'] ?? 0.01).toDouble(),
      commissionAmount: (map['commissionAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      paidAt: map['paidAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['paidAt'])
          : null,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'postId': postId,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'paidAt': paidAt?.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  CommissionModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? postId,
    String? productId,
    String? productName,
    double? productPrice,
    double? commissionRate,
    double? commissionAmount,
    String? status,
    DateTime? createdAt,
    DateTime? paidAt,
    Map<String, dynamic>? metadata,
  }) {
    return CommissionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      postId: postId ?? this.postId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class UserCommissionSummary {
  final String userId;
  final double totalEarned;
  final double pendingAmount;
  final double paidAmount;
  final int totalSales;
  final int pendingSales;
  final int paidSales;
  final DateTime lastUpdated;

  UserCommissionSummary({
    required this.userId,
    required this.totalEarned,
    required this.pendingAmount,
    required this.paidAmount,
    required this.totalSales,
    required this.pendingSales,
    required this.paidSales,
    required this.lastUpdated,
  });

  factory UserCommissionSummary.fromMap(Map<String, dynamic> map) {
    return UserCommissionSummary(
      userId: map['userId'] ?? '',
      totalEarned: (map['totalEarned'] ?? 0).toDouble(),
      pendingAmount: (map['pendingAmount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      totalSales: map['totalSales'] ?? 0,
      pendingSales: map['pendingSales'] ?? 0,
      paidSales: map['paidSales'] ?? 0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalEarned': totalEarned,
      'pendingAmount': pendingAmount,
      'paidAmount': paidAmount,
      'totalSales': totalSales,
      'pendingSales': pendingSales,
      'paidSales': paidSales,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }
}