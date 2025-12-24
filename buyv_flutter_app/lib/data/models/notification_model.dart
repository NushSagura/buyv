class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'order', 'promotion', 'commission', 'social', 'security', 'general'
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        if (v is String) return DateTime.parse(v);
        if (v is DateTime) return v;
        // Support Firestore Timestamp-like objects
        final toDate = (v as dynamic)?.toDate;
        if (toDate != null) {
          return toDate();
        }
      } catch (_) {}
      return DateTime.now();
    }

    return NotificationModel(
      id: '${map['id'] ?? ''}',
      userId: '${map['userId'] ?? map['user_id'] ?? ''}',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['isRead'] ?? map['is_read'] ?? false,
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
      readAt: map['readAt'] != null ? parseDate(map['readAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt,
      'readAt': readAt,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, title: $title, body: $body, type: $type, isRead: $isRead, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is NotificationModel &&
      other.id == id &&
      other.userId == userId &&
      other.title == title &&
      other.body == body &&
      other.type == type &&
      other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      body.hashCode ^
      type.hashCode ^
      isRead.hashCode;
  }
}