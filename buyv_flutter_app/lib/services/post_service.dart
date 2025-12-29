import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/post_model.dart';
import '../services/auth_api_service.dart';
import '../services/cloudinary_service.dart';
import 'post_api_service.dart';

class PostService {
  // Get current user ID via backend
  Future<String?> get currentUserId async {
    try {
      final me = await AuthApiService.me();
      return me['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  // Create a new post/reel
  Future<PostModel?> createPost({
    required String type, // 'reel', 'product', 'photo'
    required XFile file,
    String? caption,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final uid = await currentUserId;
      if (uid == null) {
        debugPrint('createPost: no current user');
        return null;
      }

      // Upload media based on type
      String mediaUrl;
      try {
        if (type == 'reel') {
          mediaUrl = await CloudinaryService.uploadReelVideo(file);
        } else {
          // Default to image
          mediaUrl = await CloudinaryService.uploadImage(file);
        }
      } on CloudinaryUploadException catch (e) {
        debugPrint('createPost: media upload failed: ${e.message}');
        return null;
      } catch (e) {
        debugPrint('createPost: unexpected error during upload: $e');
        return null;
      }

      final createdMap = await PostApiService.createPost(
        type: type,
        mediaUrl: mediaUrl,
        caption: caption,
        additionalData: additionalData,
      );

      return PostModel.fromJson(createdMap);
    } catch (e) {
      debugPrint('createPost error: $e');
      return null;
    }
  }

  // Get user's posts by type via backend
  Future<List<PostModel>> getUserPosts(
    String userId, {
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final List<Map<String, dynamic>> maps = await PostApiService.getUserPosts(
        userId,
        type: type,
        limit: limit,
        offset: offset,
      );
      return maps.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getUserPosts error: $e');
      return [];
    }
  }

  // Get feed posts
  Future<List<PostModel>> getFeedPosts({int limit = 20, int offset = 0}) async {
    try {
      final maps = await PostApiService.getFeedPosts(
        limit: limit,
        offset: offset,
      );
      return maps.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getFeedPosts error: $e');
      return [];
    }
  }

  // Get user's reels
  Future<List<PostModel>> getUserReels(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return getUserPosts(userId, type: 'reel', limit: limit, offset: offset);
  }

  // Get user's products
  Future<List<PostModel>> getUserProducts(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return getUserPosts(userId, type: 'product', limit: limit, offset: offset);
  }

  // Get user's photos
  Future<List<PostModel>> getUserPhotos(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return getUserPosts(userId, type: 'photo', limit: limit, offset: offset);
  }

  // Get posts count by type
  Future<int> getPostsCount(String userId, String type) async {
    try {
      return await PostApiService.getPostsCount(userId, type: type);
    } catch (e) {
      debugPrint('getPostsCount error: $e');
      return 0;
    }
  }

  // Get total posts count
  Future<int> getTotalPostsCount(String userId) async {
    try {
      return await PostApiService.getPostsCount(userId);
    } catch (e) {
      debugPrint('getTotalPostsCount error: $e');
      return 0;
    }
  }

  // Like a post
  Future<bool> likePost(String postId) async {
    try {
      return await PostApiService.likePost(postId);
    } catch (e) {
      debugPrint('likePost error: $e');
      return false;
    }
  }

  // Unlike a post
  Future<bool> unlikePost(String postId) async {
    try {
      return await PostApiService.unlikePost(postId);
    } catch (e) {
      debugPrint('unlikePost error: $e');
      return false;
    }
  }

  // Check if user liked a post
  Future<bool> isPostLiked(String postId) async {
    try {
      return await PostApiService.isPostLiked(postId);
    } catch (e) {
      debugPrint('isPostLiked error: $e');
      return false;
    }
  }

  // Get user's liked posts
  Future<List<PostModel>> getUserLikedPosts(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final maps = await PostApiService.getUserLikedPosts(
        userId,
        limit: limit,
        offset: offset,
      );
      return maps.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getUserLikedPosts error: $e');
      return [];
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      return await PostApiService.deletePost(postId);
    } catch (e) {
      debugPrint('deletePost error: $e');
      return false;
    }
  }

  // Bookmark a post
  static Future<bool> bookmarkPost(String postId) async {
    try {
      final result = await PostApiService.bookmarkPost(postId);
      return result['status'] == 'bookmarked' || result['status'] == 'already_bookmarked';
    } catch (e) {
      debugPrint('bookmarkPost error: $e');
      return false;
    }
  }

  // Unbookmark a post
  static Future<bool> unbookmarkPost(String postId) async {
    try {
      final result = await PostApiService.unbookmarkPost(postId);
      return result['status'] == 'unbookmarked' || result['status'] == 'not_bookmarked';
    } catch (e) {
      debugPrint('unbookmarkPost error: $e');
      return false;
    }
  }

  // Check if post is bookmarked
  static Future<bool> isPostBookmarked(String postId) async {
    try {
      return await PostApiService.isPostBookmarked(postId);
    } catch (e) {
      debugPrint('isPostBookmarked error: $e');
      return false;
    }
  }
}
