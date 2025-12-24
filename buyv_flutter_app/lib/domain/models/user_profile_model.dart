class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String? profileImageUrl;
  final String bio;
  final String phone;
  final int followersCount;
  final int followingCount;
  final int likesCount;
  final int createdAt;
  final int lastUpdated;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.profileImageUrl,
    this.bio = '',
    this.phone = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.likesCount = 0,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      username: json['username'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      bio: json['bio'] ?? '',
      phone: json['phone'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      createdAt: json['createdAt'] ?? 0,
      lastUpdated: json['lastUpdated'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'phone': phone,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'likesCount': likesCount,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? profileImageUrl,
    String? bio,
    String? phone,
    int? followersCount,
    int? followingCount,
    int? likesCount,
    int? createdAt,
    int? lastUpdated,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}