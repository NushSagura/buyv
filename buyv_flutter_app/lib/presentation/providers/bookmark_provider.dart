import 'package:flutter/foundation.dart';
import '../../services/post_service.dart';

/// Provider to manage bookmarked posts globally
/// Ensures bookmark state is synchronized across all screens
class BookmarkProvider with ChangeNotifier {
  final Set<String> _bookmarkedPostIds = {};
  bool _isLoading = false;

  Set<String> get bookmarkedPostIds => Set.unmodifiable(_bookmarkedPostIds);
  bool get isLoading => _isLoading;

  /// Check if a post is bookmarked
  bool isBookmarked(String postId) {
    return _bookmarkedPostIds.contains(postId);
  }

  /// Load bookmarked posts from API
  Future<void> loadBookmarks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final bookmarks = await PostService().getUserBookmarkedPosts('');
      _bookmarkedPostIds.clear();
      _bookmarkedPostIds.addAll(bookmarks.map((post) => post.id));
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle bookmark for a post
  Future<bool> toggleBookmark(String postId) async {
    final wasBookmarked = _bookmarkedPostIds.contains(postId);

    // Optimistic update
    if (wasBookmarked) {
      _bookmarkedPostIds.remove(postId);
    } else {
      _bookmarkedPostIds.add(postId);
    }
    notifyListeners();

    try {
      final success = wasBookmarked
          ? await PostService.unbookmarkPost(postId)
          : await PostService.bookmarkPost(postId);

      if (!success) {
        // Revert on failure
        if (wasBookmarked) {
          _bookmarkedPostIds.add(postId);
        } else {
          _bookmarkedPostIds.remove(postId);
        }
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      // Revert on error
      if (wasBookmarked) {
        _bookmarkedPostIds.add(postId);
      } else {
        _bookmarkedPostIds.remove(postId);
      }
      notifyListeners();
      debugPrint('Error toggling bookmark: $e');
      return false;
    }
  }

  /// Add bookmark (for use when we know it's not bookmarked)
  Future<bool> addBookmark(String postId) async {
    if (_bookmarkedPostIds.contains(postId)) {
      return true; // Already bookmarked
    }

    _bookmarkedPostIds.add(postId);
    notifyListeners();

    try {
      final success = await PostService.bookmarkPost(postId);
      if (!success) {
        _bookmarkedPostIds.remove(postId);
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _bookmarkedPostIds.remove(postId);
      notifyListeners();
      debugPrint('Error adding bookmark: $e');
      return false;
    }
  }

  /// Remove bookmark (for use when we know it's bookmarked)
  Future<bool> removeBookmark(String postId) async {
    if (!_bookmarkedPostIds.contains(postId)) {
      return true; // Already not bookmarked
    }

    _bookmarkedPostIds.remove(postId);
    notifyListeners();

    try {
      final success = await PostService.unbookmarkPost(postId);
      if (!success) {
        _bookmarkedPostIds.add(postId);
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _bookmarkedPostIds.add(postId);
      notifyListeners();
      debugPrint('Error removing bookmark: $e');
      return false;
    }
  }

  /// Clear all bookmarks (e.g., on logout)
  void clear() {
    _bookmarkedPostIds.clear();
    notifyListeners();
  }
}
