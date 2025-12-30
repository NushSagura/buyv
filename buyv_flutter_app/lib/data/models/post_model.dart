class PostModel {
  final String id;
  final String userId;
  final String username;
  final String? userProfileImage;
  final bool isUserVerified;
  final String type; // 'reel', 'product', 'photo'
  final String
  videoUrl; // Maps from 'mediaUrl' in backend if aliases work, or we map explicitly
  final String? thumbnailUrl;
  final String? caption;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final bool isLiked;
  final bool isBookmarked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfileImage,
    this.isUserVerified = false,
    required this.type,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Safe int parsing helper
    int parseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return PostModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      userProfileImage: json['userProfileImage']?.toString(),
      isUserVerified: json['isUserVerified'] == true,
      type: json['type']?.toString() ?? 'photo',
      videoUrl: json['videoUrl']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      caption: json['caption']?.toString(),
      likesCount: parseInt(json['likesCount']),
      commentsCount: parseInt(json['commentsCount']),
      sharesCount: parseInt(json['sharesCount']),
      viewsCount: parseInt(json['viewsCount']),
      isLiked: json['isLiked'] == true,
      isBookmarked: json['isBookmarked'] == true,
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'isUserVerified': isUserVerified,
      'type': type,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'viewsCount': viewsCount,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImage,
    bool? isUserVerified,
    String? type,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    bool? isLiked,
    bool? isBookmarked,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      type: type ?? this.type,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
