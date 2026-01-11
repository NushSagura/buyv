import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../widgets/reel_video_player.dart';
import '../../widgets/buy_bottom_sheet.dart';
import '../../../domain/models/reel_model.dart';
import '../../../data/models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/route_names.dart';
import '../../../constants/app_constants.dart';
import '../../../services/security/secure_token_manager.dart';
import '../../widgets/require_login_prompt.dart';
import 'widgets/reel_top_bar.dart';
import 'widgets/reel_content_overlay.dart';
import 'widgets/reel_comments_sheet.dart';

/// ReelsScreen - Migré depuis Kotlin ReelsView.kt
/// Structure simplifiée avec widgets modulaires
class ReelsScreen extends StatefulWidget {
  final String? targetReelId;

  const ReelsScreen({super.key, this.targetReelId});

  @override
  State<ReelsScreen> createState() => ReelsScreenState();
}

/// État public pour permettre au HomeScreen de contrôler les vidéos
class ReelsScreenState extends State<ReelsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<ReelModel> _reels = [];

  // Tabs
  final List<String> _tabs = ['Explore', 'Following', 'For you'];
  String _selectedTab = 'For you';

  // Video control - Map pour savoir si chaque vidéo doit jouer
  final Map<String, bool> _videoPlayStates = {};
  bool _isActive = true; // Est-ce que l'écran Reels est visible?

  // Heart animation
  final Map<String, bool> _showHeartAnimation = {};
  final Map<String, Offset> _heartPositions = {};
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _initHeartAnimation();
    _loadReels();
  }

  void _initHeartAnimation() {
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _heartScaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartAnimationController, curve: Curves.elasticOut),
    );
    _heartOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _heartAnimationController, curve: const Interval(0.5, 1.0)),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoPlayStates.clear();
    _pageController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      pauseAllVideos();
    } else if (state == AppLifecycleState.resumed && _isActive) {
      resumeCurrentVideo();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC METHODS (appelées depuis HomeScreen)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Retourne le reel actuellement affiché
  ReelModel? getCurrentReel() {
    if (_reels.isEmpty || _currentIndex >= _reels.length) return null;
    return _reels[_currentIndex];
  }

  /// Pause TOUTES les vidéos (quand on quitte l'onglet Reels)
  void pauseAllVideos() {
    debugPrint('🛑 ReelsScreen: Pausing all videos');
    _isActive = false;
    if (mounted) {
      setState(() {
        _videoPlayStates.clear();
      });
    }
  }

  /// Reprend la vidéo courante (quand on revient sur l'onglet Reels)
  void resumeCurrentVideo() {
    debugPrint('▶️ ReelsScreen: Resuming current video');
    _isActive = true;
    if (mounted && _reels.isNotEmpty && _currentIndex < _reels.length) {
      setState(() {
        _videoPlayStates[_reels[_currentIndex].id] = true;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _loadReels() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await SecureTokenManager.getAccessToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Not authenticated';
        });
        return;
      }

      // Si targetReelId, charge ce reel en premier
      if (widget.targetReelId != null) {
        await _loadTargetReelFirst(widget.targetReelId!, token);
        _loadFeedInBackground(token);
        return;
      }

      await _loadFeed(token);
    } catch (e) {
      debugPrint('❌ Error loading reels: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadTargetReelFirst(String targetReelId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.fastApiBaseUrl}/posts/$targetReelId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final post = PostModel.fromJson(json.decode(response.body));
        if ((post.type == 'reel' || post.type == 'video') && post.videoUrl.isNotEmpty) {
          final reel = _postToReel(post);
          if (mounted) {
            setState(() {
              _reels = [reel];
              _currentIndex = 0;
              _isLoading = false;
              if (_isActive) _videoPlayStates[reel.id] = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading target reel: $e');
      await _loadFeed(token);
    }
  }

  Future<void> _loadFeed(String token) async {
    final response = await http.get(
      Uri.parse('${AppConstants.fastApiBaseUrl}/posts/feed?limit=20'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final postsJson = data is List ? data : (data['posts'] as List?) ?? [];
      
      final reels = <ReelModel>[];
      for (var postJson in postsJson) {
        try {
          final post = PostModel.fromJson(postJson);
          if ((post.type == 'reel' || post.type == 'video') && post.videoUrl.isNotEmpty) {
            reels.add(_postToReel(post));
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _reels = reels;
          _isLoading = false;
        });
      }
    } else {
      throw Exception('Failed to load feed: ${response.statusCode}');
    }
  }

  void _loadFeedInBackground(String token) {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      try {
        final response = await http.get(
          Uri.parse('${AppConstants.fastApiBaseUrl}/posts/feed?limit=20'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200 && mounted) {
          final data = json.decode(response.body);
          final postsJson = data is List ? data : (data['posts'] as List?) ?? [];
          
          final reels = <ReelModel>[];
          for (var postJson in postsJson) {
            try {
              final post = PostModel.fromJson(postJson);
              if ((post.type == 'reel' || post.type == 'video') && post.videoUrl.isNotEmpty) {
                reels.add(_postToReel(post));
              }
            } catch (_) {}
          }

          if (reels.isNotEmpty && widget.targetReelId != null) {
            final idx = reels.indexWhere((r) => r.id == widget.targetReelId);
            if (idx >= 0) {
              final target = reels[idx];
              _reels = [target, ...reels.sublist(0, idx), ...reels.sublist(idx + 1)];
            }
          }
        }
      } catch (_) {}
    });
  }

  ReelModel _postToReel(PostModel post) {
    return ReelModel(
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
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _videoPlayStates.clear();
      if (_isActive && _reels.isNotEmpty && index < _reels.length) {
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
      if (mounted) setState(() => _showHeartAnimation[reelId] = false);
    });
    _toggleLike(reelId);
  }

  void _toggleLike(String reelId) {
    final idx = _reels.indexWhere((r) => r.id == reelId);
    if (idx >= 0) {
      setState(() {
        final reel = _reels[idx];
        _reels[idx] = reel.copyWith(
          isLiked: !reel.isLiked,
          likesCount: reel.isLiked ? reel.likesCount - 1 : reel.likesCount + 1,
        );
      });
    }
  }

  Future<void> _handleBookmark(String reelId) async {
    final idx = _reels.indexWhere((r) => r.id == reelId);
    if (idx < 0) return;

    final reel = _reels[idx];
    
    try {
      bool success;
      if (reel.isBookmarked) {
        // Unbookmark
        final token = await SecureTokenManager.getAccessToken();
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication required')),
          );
          return;
        }
        
        final response = await http.delete(
          Uri.parse('${AppConstants.fastApiBaseUrl}/posts/$reelId/bookmark'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        success = response.statusCode == 200;
        
        if (success && mounted) {
          setState(() {
            _reels[idx] = reel.copyWith(isBookmarked: false);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from bookmarks'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Bookmark
        final token = await SecureTokenManager.getAccessToken();
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication required')),
          );
          return;
        }
        
        final response = await http.post(
          Uri.parse('${AppConstants.fastApiBaseUrl}/posts/$reelId/bookmark'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        success = response.statusCode == 200;
        
        if (success && mounted) {
          setState(() {
            _reels[idx] = reel.copyWith(isBookmarked: true);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to bookmarks'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error bookmarking reel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _shareReel(ReelModel reel) {
    SharePlus.instance.share(ShareParams(
      text: 'Check out this amazing product: ${reel.caption}\n\n${reel.hashtags.map((t) => '#$t').join(' ')}\n\nDownload our app!',
    ));
  }

  void _showComments(String reelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReelCommentsSheet(
        reelId: reelId,
        onCommentsCountChanged: (count) {
          final idx = _reels.indexWhere((r) => r.id == reelId);
          if (idx >= 0 && mounted) {
            setState(() => _reels[idx] = _reels[idx].copyWith(commentsCount: count));
          }
        },
      ),
    );
  }

  void _onCartPressed(ReelModel reel) {
    if (!reel.hasProduct || reel.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product linked to this reel')),
      );
      return;
    }

    final isAuth = context.read<AuthProvider>().isAuthenticated;
    if (!isAuth) {
      _showLoginPrompt();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => BuyBottomSheet(
        product: reel.product!,
        promoterId: reel.userId,
        onAddToCart: (qty, pid) {
          Navigator.pop(ctx);
          context.read<CartProvider>().addToCart(reel.product!, quantity: qty, promoterId: pid);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added to cart')),
          );
        },
        onBuyNow: (qty, pid) {
          Navigator.pop(ctx);
          context.read<CartProvider>().addToCart(reel.product!, quantity: qty, promoterId: pid);
          context.go('/cart');
        },
      ),
    );
  }

  void _showLoginPrompt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: RequireLoginPrompt(
          onLogin: () { Navigator.pop(ctx); context.go('/login'); },
          onSignUp: () { Navigator.pop(ctx); context.go('/signup'); },
          onDismiss: () => Navigator.pop(ctx),
          showCloseButton: true,
        ),
      ),
    );
  }

  void _onTabChanged(String newTab) {
    if (_selectedTab == newTab) return;
    setState(() => _selectedTab = newTab);
    
    if (newTab == 'Explore') {
      pauseAllVideos();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(RouteNames.searchReels);
      });
    } else {
      setState(() { _isLoading = true; _currentIndex = 0; });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadReels();
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.isAuthenticated) return _buildLoginRequired();
          if (_isLoading) return _buildLoading();
          if (_errorMessage != null) return _buildError();
          if (_reels.isEmpty) return _buildEmpty();
          return _buildReelsView();
        },
      ),
    );
  }

  Widget _buildReelsView() {
    return Stack(
      children: [
        // LAYER 1: Video PageView
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemCount: _reels.length,
          pageSnapping: true,
          itemBuilder: (context, index) {
            final reel = _reels[index];
            final isPlaying = _isActive && (_videoPlayStates[reel.id] ?? (index == _currentIndex));

            return GestureDetector(
              key: ValueKey('reel_${reel.id}'),
              onDoubleTapDown: (d) => _onDoubleTap(reel.id, d.globalPosition),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ReelVideoPlayer(
                    reel: reel,
                    isPlaying: isPlaying,
                    isCurrentReel: index == _currentIndex,
                    onTogglePlay: () {
                      setState(() => _videoPlayStates[reel.id] = !isPlaying);
                    },
                  ),
                  if (_showHeartAnimation[reel.id] == true)
                    _buildHeartAnimation(reel.id),
                ],
              ),
            );
          },
        ),

        // LAYER 2: Top bar
        ReelTopBar(
          tabs: _tabs,
          selectedTab: _selectedTab,
          onTabChanged: _onTabChanged,
          onSearchTap: () {
            pauseAllVideos();
            context.push(RouteNames.searchReels);
          },
        ),

        // LAYER 3: Content overlay
        if (_reels.isNotEmpty && _currentIndex < _reels.length)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: ReelContentOverlay(
              reel: _reels[_currentIndex],
              onLikeTap: () => _toggleLike(_reels[_currentIndex].id),
              onCommentTap: () => _showComments(_reels[_currentIndex].id),
              onCartTap: () => _onCartPressed(_reels[_currentIndex]),
              onShareTap: () => _shareReel(_reels[_currentIndex]),
              onBookmarkTap: () => _handleBookmark(_reels[_currentIndex].id),
              onUserTap: () => context.go('/user/${_reels[_currentIndex].userId}'),
              onProductTap: () {
                final p = _reels[_currentIndex].product;
                if (p != null) context.go('/product/${p.id}');
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeartAnimation(String reelId) {
    final pos = _heartPositions[reelId];
    if (pos == null) return const SizedBox.shrink();
    return Positioned(
      left: pos.dx - 40,
      top: pos.dy - 40,
      child: AnimatedBuilder(
        animation: _heartAnimationController,
        builder: (_, __) => Transform.scale(
          scale: _heartScaleAnimation.value,
          child: Opacity(
            opacity: _heartOpacityAnimation.value,
            child: const Icon(Icons.favorite, color: Colors.red, size: 80),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.secondary, Color(0xFF1A1A1A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text('Not logged in!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Please log in to view reels', style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Loading reels...', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('Error loading reels', style: TextStyle(color: AppColors.error, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_errorMessage ?? 'Unknown error', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadReels,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No reels', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Create reels or follow users', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadReels,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
