import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../widgets/reel_video_player.dart';
import '../../widgets/reel_interactions.dart';
import '../../widgets/buy_bottom_sheet.dart';
import '../../../domain/models/reel_model.dart';
import '../../../data/models/post_model.dart';
import '../../../domain/models/comment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../constants/app_constants.dart';
import '../../../services/security/secure_token_manager.dart';
import '../../widgets/require_login_prompt.dart';
import '../shop/shop_screen.dart';
import '../../../services/api/comment_api_service.dart';

class ReelsScreen extends StatefulWidget {
  final String? targetReelId;

  const ReelsScreen({super.key, this.targetReelId});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<ReelModel> _reels = [];

  // Tab management - matching Kotlin structure
  final List<String> _tabs = ['Following', 'For you', 'Explore'];
  String _selectedTab = 'For you';

  // Video state management
  final Map<String, bool> _videoPlayStates = {};
  bool _wasAppInBackground = false;

  // Heart animation states per reel
  final Map<String, bool> _showHeartAnimation = {};
  final Map<String, Offset> _heartPositions = {};

  // Animation controllers
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  // Comment controller
  final TextEditingController _commentController = TextEditingController();

  // Real comment data
  List<CommentModel> _comments = [];
  bool _commentsLoading = false;
  bool _addingComment = false;
  int _commentsOffset = 0;
  final int _commentsLimit = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController();

    // Initialize heart animation
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _heartScaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _heartOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: const Interval(0.5, 1.0),
      ),
    );

    _loadReels();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _heartAnimationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _wasAppInBackground = true;
        _pauseAllVideos();
        break;
      case AppLifecycleState.resumed:
        if (_wasAppInBackground) {
          _wasAppInBackground = false;
          // Resume current video if it was playing
          _resumeCurrentVideo();
        }
        break;
      case AppLifecycleState.detached:
        _pauseAllVideos();
        break;
      default:
        break;
    }
  }

  void _pauseAllVideos() {
    setState(() {
      _videoPlayStates.clear();
    });
  }

  void _resumeCurrentVideo() {
    if (_reels.isNotEmpty && _currentIndex < _reels.length) {
      final currentReelId = _reels[_currentIndex].id;
      setState(() {
        _videoPlayStates[currentReelId] = true;
      });
    }
  }

  void _loadReelsForTab(String tab) {
    // Simulate loading reels for different tabs
    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // In real app, this would load different reels based on tab
          _loadReels();
        });
      }
    });
  }

  Future<void> _loadReels() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load reels from backend API
      final token = await SecureTokenManager.getAccessToken();

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Not authenticated';
        });
        return;
      }

      // Fetch reels/videos from posts API
      final response = await http.get(
        Uri.parse('${AppConstants.fastApiBaseUrl}/posts/feed?limit=50'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('📦 Response type: ${responseData.runtimeType}');
        
        // Handle both formats: direct list or object with 'posts' key
        List<dynamic> postsJson;
        
        if (responseData is List) {
          // Direct list format
          postsJson = responseData;
          debugPrint('📦 Direct list format: ${postsJson.length} items');
        } else if (responseData is Map && responseData.containsKey('posts')) {
          // Object with 'posts' key
          postsJson = responseData['posts'] as List;
          debugPrint('📦 Object format with posts key: ${postsJson.length} items');
        } else {
          debugPrint('❌ Unexpected response format: ${responseData.runtimeType}');
          setState(() {
            _isLoading = false;
            _errorMessage = 'Invalid API response format';
          });
          return;
        }
        
        debugPrint('📦 Found ${postsJson.length} posts in feed');
        
        // Convert PostModel to ReelModel for reels/videos only
        final reels = <ReelModel>[];
        
        for (var i = 0; i < postsJson.length; i++) {
          try {
            final postJson = postsJson[i];
            debugPrint('🔍 Processing post $i: type=${postJson['type']}, videoUrl=${postJson['videoUrl']}');
            
            final post = PostModel.fromJson(postJson);
            
            // Only include reels/videos with valid URLs
            if ((post.type == 'reel' || post.type == 'video') && 
                post.videoUrl.isNotEmpty) {
              final reel = ReelModel(
                id: post.id,
                userId: post.userId,
                username: post.username,
                userProfileImage: post.userProfileImage ?? '',
                isUserVerified: post.isUserVerified,
                videoUrl: post.videoUrl,
                thumbnailUrl: post.thumbnailUrl,
                caption: post.caption ?? '',
                hashtags: [],
                likesCount: post.likesCount,
                commentsCount: post.commentsCount,
                sharesCount: post.sharesCount,
                viewsCount: post.viewsCount,
                isLiked: post.isLiked,
                isBookmarked: post.isBookmarked,
                createdAt: post.createdAt,
                updatedAt: post.updatedAt,
                duration: 0.0,
              );
              reels.add(reel);
              debugPrint('✅ Added reel: ${reel.id}');
            }
          } catch (e, stackTrace) {
            debugPrint('⚠️ Error converting post $i to reel: $e');
            debugPrint('Stack trace: $stackTrace');
            // Skip problematic posts
            continue;
          }
        }

        debugPrint('✅ Loaded ${reels.length} reels from ${postsJson.length} total posts');

        setState(() {
          _reels = reels;
          _isLoading = false;

          // Navigate to target reel if specified
          if (widget.targetReelId != null) {
            final targetIndex = _reels.indexWhere(
              (reel) => reel.id == widget.targetReelId,
            );
            if (targetIndex >= 0) {
              _currentIndex = targetIndex;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _pageController.animateToPage(
                  targetIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            }
          }
        });
      } else {
        throw Exception('Failed to load reels: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading reels: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;

      // Pause all videos except current
      _videoPlayStates.clear();
      if (_reels.isNotEmpty && index < _reels.length) {
        _videoPlayStates[_reels[index].id] = true;
      }
    });
  }

  void _onDoubleTap(String reelId, Offset position) {
    setState(() {
      _showHeartAnimation[reelId] = true;
      _heartPositions[reelId] = position;
    });

    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reset();
      setState(() {
        _showHeartAnimation[reelId] = false;
      });
    });

    // Toggle like
    _toggleLike(reelId);
  }

  void _toggleLike(String reelId) {
    setState(() {
      final reelIndex = _reels.indexWhere((reel) => reel.id == reelId);
      if (reelIndex >= 0) {
        final reel = _reels[reelIndex];
        _reels[reelIndex] = reel.copyWith(
          isLiked: !reel.isLiked,
          likesCount: reel.isLiked ? reel.likesCount - 1 : reel.likesCount + 1,
        );
      }
    });
  }

  void _toggleBookmark(String reelId) async {
    final reelIndex = _reels.indexWhere((reel) => reel.id == reelId);
    if (reelIndex < 0) return;

    final reel = _reels[reelIndex];
    final newBookmarkState = !reel.isBookmarked;

    // Optimistic update
    setState(() {
      _reels[reelIndex] = reel.copyWith(isBookmarked: newBookmarkState);
    });

    // Call backend
    try {
      final success = newBookmarkState
          ? await PostService.bookmarkPost(reelId)
          : await PostService.unbookmarkPost(reelId);

      if (!success) {
        // Revert on failure
        if (mounted) {
          setState(() {
            _reels[reelIndex] = reel.copyWith(isBookmarked: !newBookmarkState);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la sauvegarde')),
          );
        }
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _reels[reelIndex] = reel.copyWith(isBookmarked: !newBookmarkState);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: \$e')),
        );
      }
    }
  }

  void _shareReel(ReelModel reel) {
    final shareContent =
        '''
Check out this amazing product: ${reel.caption}

${reel.hashtags.map((tag) => '#$tag').join(' ')}

Download our app to see more amazing products!
''';

    SharePlus.instance.share(ShareParams(text: shareContent));
  }

  void _showComments(String reelId) {
    // Reset comments state
    setState(() {
      _comments = [];
      _commentsOffset = 0;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCommentsSheet(reelId),
    );
  }

  Future<void> _loadComments(String reelId) async {
    if (_commentsLoading) return;

    setState(() {
      _commentsLoading = true;
    });

    try {
      final commentsData = await CommentApiService.getComments(
        reelId,
        limit: _commentsLimit,
        offset: _commentsOffset,
      );

      final newComments = commentsData
          .map((data) => CommentModel.fromJson(data))
          .toList();

      setState(() {
        _comments.addAll(newComments);
        _commentsOffset += newComments.length;
        _commentsLoading = false;
      });
    } catch (e) {
      setState(() {
        _commentsLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading comments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addComment(String reelId) async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _addingComment) return;

    setState(() {
      _addingComment = true;
    });

    try {
      final commentData = await CommentApiService.addComment(reelId, content);
      final newComment = CommentModel.fromJson(commentData);

      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
        _addingComment = false;

        // Update reel comments count
        final reelIndex = _reels.indexWhere((r) => r.id == reelId);
        if (reelIndex >= 0) {
          _reels[reelIndex] = _reels[reelIndex].copyWith(
            commentsCount: _reels[reelIndex].commentsCount + 1,
          );
        }
      });
      
      // Reload comments to ensure we have the latest from server
      Future.microtask(() {
        setState(() {
          _comments.clear();
          _commentsOffset = 0;
        });
        _loadComments(reelId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added!'),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _addingComment = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCommentsSheet(String reelId) {
    // Load comments when sheet opens - always reload to get latest
    Future.microtask(() {
      setState(() {
        _comments.clear();
        _commentsOffset = 0;
      });
      _loadComments(reelId);
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Comments list
          Expanded(
            child: _comments.isEmpty && !_commentsLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!_commentsLoading &&
                          scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent) {
                        _loadComments(reelId);
                      }
                      return true;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length + (_commentsLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _comments.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildCommentItem(_comments[index]);
                      },
                    ),
                  ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addingComment ? null : () => _addComment(reelId),
                  icon: _addingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            backgroundImage: comment.userProfileImage != null
                ? NetworkImage(comment.userProfileImage!)
                : null,
            child: comment.userProfileImage == null
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isAuthenticated) {
            return _buildLoginPrompt();
          }

          if (_isLoading) {
            return _buildLoadingState();
          }

          if (_errorMessage != null) {
            return _buildErrorState();
          }

          if (_reels.isEmpty) {
            return _buildEmptyState();
          }

          return _buildReelsView();
        },
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Not logged in!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please log in to view reels',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Log In',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading reels...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error loading reels',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReels,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No reels',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create reels or follow users to see content',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReels,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelsView() {
    return Stack(
      children: [
        // Main video pager
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemCount: _reels.length,
          itemBuilder: (context, index) {
            final reel = _reels[index];
            final isCurrentReel = index == _currentIndex;
            final isPlaying = _videoPlayStates[reel.id] ?? isCurrentReel;

            return GestureDetector(
              onDoubleTapDown: (details) {
                _onDoubleTap(reel.id, details.globalPosition);
              },
              child: Stack(
                children: [
                  // Video player
                  ReelVideoPlayer(
                    reel: reel,
                    isPlaying: isPlaying,
                    isCurrentReel: isCurrentReel,
                    onTogglePlay: () {
                      setState(() {
                        _videoPlayStates[reel.id] = !isPlaying;
                      });
                    },
                  ),

                  // Heart animation
                  if (_showHeartAnimation[reel.id] == true)
                    Positioned(
                      left: _heartPositions[reel.id]?.dx ?? 0,
                      top: _heartPositions[reel.id]?.dy ?? 0,
                      child: AnimatedBuilder(
                        animation: _heartAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _heartScaleAnimation.value,
                            child: Opacity(
                              opacity: _heartOpacityAnimation.value,
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 80,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Right side interactions
                  Positioned(
                    right: 12,
                    bottom: 100,
                    child: ReelInteractions(
                      reel: reel,
                      onLike: () => _toggleLike(reel.id),
                      onComment: () => _showComments(reel.id),
                      onShare: () => _shareReel(reel),
                      onBookmark: () => _toggleBookmark(reel.id),
                      onProfile: () {
                        context.go('/user/${reel.userId}');
                      },
                      onCart: () => _onCartPressed(reel),
                      isInCart:
                          reel.product != null &&
                          context.watch<CartProvider>().isProductInCart(
                            reel.product!.id,
                          ),
                    ),
                  ),

                  // Bottom info
                  Positioned(
                    left: 12,
                    right: 80,
                    bottom: 100,
                    child: _buildReelInfo(reel),
                  ),
                  // Product bubble
                  if (reel.hasProduct)
                    Positioned(
                      right: 12,
                      top: 100,
                      child: _buildProductBubble(reel),
                    ),
                ],
              ),
            );
          },
        ),

        // Top bar with tabs
        _buildTopBar(),

        // Center Buy button overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 48,
          child: Center(child: _buildBuyFab()),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).padding.top + 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tabs Row - matching Kotlin order
                Row(
                  children: _tabs.map((tab) {
                    final isSelected = tab == _selectedTab;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = tab;
                        });

                        // Handle tab navigation like Kotlin
                        if (tab == 'Explore') {
                          context.go('/search_reels');
                        } else {
                          // Load reels for selected tab
                          _loadReelsForTab(tab);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border(
                                  bottom: BorderSide(
                                    color: tab == 'Explore'
                                        ? const Color(0xFF0066CC)
                                        : Colors.white,
                                    width: 2,
                                  ),
                                )
                              : null,
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isSelected
                                ? (tab == 'Explore'
                                      ? const Color(0xFF0066CC)
                                      : Colors.white)
                                : Colors.grey[300],
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Search Icon
                IconButton(
                  onPressed: () {
                    context.go('/search_reels');
                  },
                  icon: Icon(
                    Icons.search,
                    color: _selectedTab == 'Explore'
                        ? const Color(0xFF0066CC)
                        : Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReelInfo(ReelModel reel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User info
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: reel.userProfileImage.isNotEmpty
                  ? NetworkImage(reel.userProfileImage)
                  : null,
              backgroundColor: Colors.grey[300],
              child: reel.userProfileImage.isEmpty
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              reel.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (reel.isUserVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.blue, size: 16),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Follow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Caption
        Text(
          reel.caption,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Hashtags
        if (reel.hashtags.isNotEmpty)
          Wrap(
            children: reel.hashtags.map((hashtag) {
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: Text(
                  '#$hashtag',
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 8),

        // Music info
        if (reel.musicTitle?.isNotEmpty ?? false)
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${reel.musicTitle} - ${reel.musicArtist}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _onCartPressed(ReelModel reel) {
    if (!reel.hasProduct || reel.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product linked to this reel')),
      );
      return;
    }

    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    if (!isAuthenticated) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: RequireLoginPrompt(
              onLogin: () {
                Navigator.pop(ctx);
                context.go('/login');
              },
              onSignUp: () {
                Navigator.pop(ctx);
                context.go('/signup');
              },
              onDismiss: () {
                Navigator.pop(ctx);
              },
              showCloseButton: true,
            ),
          );
        },
      );
      return;
    }

    final product = reel.product!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BuyBottomSheet(
          product: product,
          promoterId: reel.userId, // معرف المروج من الريل
          onAddToCart: (qty, promoterId) {
            Navigator.pop(ctx);
            context.read<CartProvider>().addToCart(
              product,
              quantity: qty,
              promoterId: promoterId,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product added to cart')),
            );
          },
          onBuyNow: (qty, promoterId) {
            Navigator.pop(ctx);
            context.read<CartProvider>().addToCart(
              product,
              quantity: qty,
              promoterId: promoterId,
            );
            context.go('/cart');
          },
        );
      },
    );
  }

  // Center Buy button similar to Kotlin app
  Widget _buildBuyFab() {
    final hasReel = _reels.isNotEmpty && _currentIndex < _reels.length;
    final reel = hasReel ? _reels[_currentIndex] : null;
    final isEnabled = reel?.hasProduct == true;

    return GestureDetector(
      onTap: isEnabled && reel != null ? () => _onCartPressed(reel) : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled ? AppTheme.primaryColor : Colors.grey.shade600,
          border: Border.all(color: Colors.white, width: 6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Buy',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // Product info bubble with View button
  Widget _buildProductBubble(ReelModel reel) {
    final product = reel.product;
    if (product == null) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: (product.imageUrls.isNotEmpty)
                ? Image.network(
                    product.imageUrls.first,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.category,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShopScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'View',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${product.finalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFFFC107),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
