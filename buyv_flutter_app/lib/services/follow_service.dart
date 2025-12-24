import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'follow_api_service.dart';
import '../presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class FollowService {
  // Get current user ID from AuthProvider
  String? currentUserIdFromContext(BuildContext context) =>
      Provider.of<AuthProvider>(context, listen: false).currentUser?.id;

  // Follow a user
  Future<bool> followUser(String targetUserId, {BuildContext? context}) async {
    try {
      final currentUser = context != null ? currentUserIdFromContext(context) : null;
      if (currentUser == null || currentUser == targetUserId) {
        return false; // Can't follow yourself or if not logged in
      }
      final ok = await FollowApiService.followUser(targetUserId);
      debugPrint('Follow result for $targetUserId: $ok');
      return ok;
    } catch (e) {
      debugPrint('Error following user: $e');
      return false;
    }
  }

  // Unfollow a user
  Future<bool> unfollowUser(String targetUserId, {BuildContext? context}) async {
    try {
      final currentUser = context != null ? currentUserIdFromContext(context) : null;
      if (currentUser == null || currentUser == targetUserId) {
        return false; // Can't unfollow yourself or if not logged in
      }
      final ok = await FollowApiService.unfollowUser(targetUserId);
      debugPrint('Unfollow result for $targetUserId: $ok');
      return ok;
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      return false;
    }
  }

  // Check if current user is following a specific user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      return await FollowApiService.isFollowing(targetUserId);
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  // Get followers list for a user
  Future<List<String>> getFollowers(String userId) async {
    try {
      return await FollowApiService.getFollowers(userId);
    } catch (e) {
      debugPrint('Error getting followers: $e');
      return [];
    }
  }

  // Get following list for a user
  Future<List<String>> getFollowing(String userId) async {
    try {
      return await FollowApiService.getFollowing(userId);
    } catch (e) {
      debugPrint('Error getting following: $e');
      return [];
    }
  }

  // Get followers count for a user
  Future<int> getFollowersCount(String userId) async {
    try {
      final counts = await FollowApiService.getCounts(userId);
      return counts['followers'] ?? 0;
    } catch (e) {
      debugPrint('Error getting followers count: $e');
      return 0;
    }
  }

  // Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final counts = await FollowApiService.getCounts(userId);
      return counts['following'] ?? 0;
    } catch (e) {
      debugPrint('Error getting following count: $e');
      return 0;
    }
  }

  // Stream follow status changes
  Stream<bool> getFollowStatusStream(String targetUserId) async* {
    // No real-time updates via REST; naive polling stream as placeholder
    while (true) {
      try {
        final status = await isFollowing(targetUserId);
        yield status;
      } catch (_) {
        yield false;
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Stream followers count changes
  Stream<int> getFollowersCountStream(String userId) async* {
    while (true) {
      yield await getFollowersCount(userId);
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Stream following count changes
  Stream<int> getFollowingCountStream(String userId) async* {
    while (true) {
      yield await getFollowingCount(userId);
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Toggle follow status (follow if not following, unfollow if following)
  Future<bool> toggleFollow(String targetUserId) async {
    try {
      final isCurrentlyFollowing = await isFollowing(targetUserId);
      
      if (isCurrentlyFollowing) {
        return await unfollowUser(targetUserId);
      } else {
        return await followUser(targetUserId);
      }
    } catch (e) {
      debugPrint('Error toggling follow status: $e');
      return false;
    }
  }

  // Get mutual followers (users who follow each other)
  Future<List<String>> getMutualFollowers(String userId) async {
    try {
      final followers = await getFollowers(userId);
      final following = await getFollowing(userId);
      
      // Find intersection of followers and following
      return followers.where((follower) => following.contains(follower)).toList();
    } catch (e) {
      debugPrint('Error getting mutual followers: $e');
      return [];
    }
  }

  // Get suggested users (users not followed by current user)
  Future<List<String>> getSuggestedUsers({int limit = 20}) async {
    try {
      // Backend computes suggestions using auth context
      return await FollowApiService.getSuggested(limit: limit);
    } catch (e) {
      debugPrint('Error getting suggested users: $e');
      return [];
    }
  }
}