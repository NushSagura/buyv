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
    return PostModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '', // Expecting String UID now
      username: json['username'] ?? '',
      userProfileImage: json['userProfileImage'],
      isUserVerified: json['isUserVerified'] ?? false,
      type: json['type'] ?? 'photo',
      // Backend returns videoUrl (aliased from media_url)
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      caption: json['caption'],
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      viewsCount: json['viewsCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      metadata: json['metadata'],
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
}
