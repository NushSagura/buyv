import 'package:flutter/foundation.dart';
import '../domain/models/user_model.dart';
import '../services/auth_api_service.dart';
import 'follow_api_service.dart';
import 'post_api_service.dart';

class UserService {
  // Get current user via backend
  Future<String?> get currentUserId async {
    try {
      final res = await AuthApiService.me();
      return res['id'] as String?; // backend maps uid to id
    } catch (_) {
      return null;
    }
  }

  // Get user profile by ID
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final res = await AuthApiService.getUser(userId);
      return UserModel.fromJson(res);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    final userId = await currentUserId;
    if (userId == null) return null;
    return getUserProfile(userId);
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel user) async {
    try {
      await AuthApiService.updateUser(user.id, user.toJson());
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  // Get user posts count
  Future<int> getUserPostsCount(String userId) async {
    try {
      return await PostApiService.getPostsCount(userId);
    } catch (e) {
      debugPrint('Error getting user posts count: $e');
      return 0;
    }
  }

  // Get user reels count
  Future<int> getUserReelsCount(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile?.reelsCount ?? 0;
    } catch (e) {
      debugPrint('Error getting user reels count: $e');
      return 0;
    }
  }

  // Get user products count
  Future<int> getUserProductsCount(String userId) async {
    try {
      return await PostApiService.getPostsCount(userId, type: 'product');
    } catch (e) {
      debugPrint('Error getting user products count: $e');
      return 0;
    }
  }

  // Get followers count
  Future<int> getFollowersCount(String userId) async {
    try {
      final counts = await FollowApiService.getCounts(userId);
      return counts['followers'] ?? 0;
    } catch (e) {
      debugPrint('Error getting followers count: $e');
      return 0;
    }
  }

  // Get following count
  Future<int> getFollowingCount(String userId) async {
    try {
      final counts = await FollowApiService.getCounts(userId);
      return counts['following'] ?? 0;
    } catch (e) {
      debugPrint('Error getting following count: $e');
      return 0;
    }
  }

  // Get user statistics (posts, followers, following)
  Future<Map<String, int>> getUserStatistics(String userId) async {
    try {
      final results = await Future.wait([
        getUserPostsCount(userId),
        getFollowersCount(userId),
        getFollowingCount(userId),
      ]);

      return {
        'posts': results[0],
        'followers': results[1],
        'following': results[2],
      };
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return {
        'posts': 0,
        'followers': 0,
        'following': 0,
      };
    }
  }

  // Update user statistics in profile document (handled server-side; no-op here)
  Future<bool> updateUserStatistics(String userId) async {
    try {
      final stats = await getUserStatistics(userId);
      debugPrint('Computed user stats for $userId: $stats');
      // Backend should update counts; nothing to do client-side
      return true;
    } catch (e) {
      debugPrint('Error computing user statistics: $e');
      return false;
    }
  }

  // Stream user profile changes
  Stream<UserModel?> getUserProfileStream(String userId) async* {
    // REST polling placeholder
    while (true) {
      yield await getUserProfile(userId);
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Stream current user profile changes
  Stream<UserModel?> getCurrentUserProfileStream() async* {
    final userId = await currentUserId;
    if (userId == null) {
      yield null;
      return;
    }
    yield* getUserProfileStream(userId);
  }

  // Search users by username or display name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];
      // No search endpoint yet; fetch current user only
      final me = await AuthApiService.me();
      final user = UserModel.fromJson(me);
      if (user.username.toLowerCase().contains(query.toLowerCase()) ||
          user.displayName.toLowerCase().contains(query.toLowerCase())) {
        return [user];
      }
      return [];
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Get user posts/reels
  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      // TODO: Implement FastAPI posts endpoint
      debugPrint('getUserPosts not implemented on backend yet for user $userId');
      return [];
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      return [];
    }
  }

  // Get user products
  Future<List<Map<String, dynamic>>> getUserProducts(String userId) async {
    try {
      // TODO: Implement FastAPI products endpoint
      debugPrint('getUserProducts not implemented on backend yet for user $userId');
      return [];
    } catch (e) {
      debugPrint('Error getting user products: $e');
      return [];
    }
  }
}