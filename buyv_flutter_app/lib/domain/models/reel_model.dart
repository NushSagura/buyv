import 'product_model.dart';

class ReelModel {
  final String id;
  final String userId;
  final String username;
  final String userProfileImage;
  final bool isUserVerified;
  final String videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final List<String> hashtags;
  final String? musicId;
  final String? musicTitle;
  final String? musicArtist;
  final ProductModel? product;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final bool isLiked;
  final bool isBookmarked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double duration; // in seconds
  final Map<String, dynamic>? metadata;

  ReelModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    this.isUserVerified = false,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.caption,
    this.hashtags = const [],
    this.musicId,
    this.musicTitle,
    this.musicArtist,
    this.product,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    required this.createdAt,
    required this.updatedAt,
    this.duration = 0.0,
    this.metadata,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userProfileImage: json['userProfileImage'] ?? '',
      isUserVerified: json['isUserVerified'] ?? false,
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      caption: json['caption'] ?? '',
      hashtags: List<String>.from(json['hashtags'] ?? []),
      musicId: json['musicId'],
      musicTitle: json['musicTitle'],
      musicArtist: json['musicArtist'],
      product: json['product'] != null 
          ? ProductModel.fromJson(json['product']) 
          : null,
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      viewsCount: json['viewsCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      duration: (json['duration'] ?? 0).toDouble(),
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
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'hashtags': hashtags,
      'musicId': musicId,
      'musicTitle': musicTitle,
      'musicArtist': musicArtist,
      'product': product?.toJson(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'viewsCount': viewsCount,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'duration': duration,
      'metadata': metadata,
    };
  }

  bool get hasProduct => product != null;
  
  bool get hasMusic => musicId != null && musicTitle != null;

  String get formattedDuration {
    final minutes = (duration / 60).floor();
    final seconds = (duration % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ReelModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImage,
    bool? isUserVerified,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    List<String>? hashtags,
    String? musicId,
    String? musicTitle,
    String? musicArtist,
    ProductModel? product,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    bool? isLiked,
    bool? isBookmarked,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? duration,
    Map<String, dynamic>? metadata,
  }) {
    return ReelModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      musicId: musicId ?? this.musicId,
      musicTitle: musicTitle ?? this.musicTitle,
      musicArtist: musicArtist ?? this.musicArtist,
      product: product ?? this.product,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
    );
  }
}