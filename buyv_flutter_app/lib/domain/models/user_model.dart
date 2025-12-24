class UserModel {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int reelsCount;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> interests;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.profileImageUrl,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.reelsCount = 0,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.interests = const [],
    this.settings,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      bio: json['bio'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      reelsCount: json['reelsCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      interests: List<String>.from(json['interests'] ?? []),
      settings: json['settings'],
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'reelsCount': reelsCount,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'interests': interests,
      'settings': settings,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? profileImageUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? reelsCount,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? interests,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      reelsCount: reelsCount ?? this.reelsCount,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      interests: interests ?? this.interests,
      settings: settings ?? this.settings,
    );
  }
}