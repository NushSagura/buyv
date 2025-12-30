import '../../../data/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart' as auth_provider;
import '../../widgets/require_login_prompt.dart';
import '../../../domain/models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../services/post_service.dart';
import 'follow_list_screen.dart';
import '../../../data/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTabIndex = 0;
  final UserService _userService = UserService();
  final PostService _postService = PostService();

  // Statistics
  int _followersCount = 0;
  int _followingCount = 0;
  int _likesCount = 0;
  int _reelsCount = 0;
  int _productsCount = 0;

  // Content lists
  List<PostModel> _userReels = [];
  List<PostModel> _userProducts = [];
  List<PostModel> _userLikedPosts = [];
  List<PostModel> _userSavedPosts = [];

  bool _isLoadingStats = true;
  bool _isLoadingContent = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<auth_provider.AuthProvider>(
        context,
        listen: false,
      );
      if (authProvider.isAuthenticated && authProvider.currentUser != null) {
        authProvider.reloadUserData();
        _loadProfileData();
      }
    });
  }

  DateTime? _lastPostUpdate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    if (_lastPostUpdate != null &&
        userProvider.lastPostUpdate != _lastPostUpdate) {
      _lastPostUpdate = userProvider.lastPostUpdate;
      _loadProfileData();
    }
    _lastPostUpdate ??= userProvider.lastPostUpdate;
  }

  Future<void> _loadProfileData() async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(
      context,
      listen: false,
    );
    final String? currentUserId = authProvider.currentUser?.id;

    if (currentUserId == null) return;

    setState(() {
      _isLoadingStats = true;
      _isLoadingContent = true;
    });

    try {
      // Load ALL statistics in ONE call
      final stats = await _userService.getUserStatistics(currentUserId);

      _followersCount = stats['followers'] ?? 0;
      _followingCount = stats['following'] ?? 0;
      _reelsCount = stats['reels'] ?? 0;
      _productsCount = stats['products'] ?? 0;
      _likesCount = stats['likes'] ?? 0;

      setState(() {
        _isLoadingStats = false;
      });

      // Load content for current tab
      await _loadTabContent();
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      setState(() {
        _isLoadingStats = false;
        _isLoadingContent = false;
      });
    }
  }

  Future<void> _loadTabContent() async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(
      context,
      listen: false,
    );
    final String? currentUserId = authProvider.currentUser?.id;
    if (currentUserId == null) return;

    setState(() {
      _isLoadingContent = true;
    });

    try {
      switch (_selectedTabIndex) {
        case 0: // Reels
          _userReels = await _postService.getUserReels(currentUserId);
          break;
        case 1: // Products
          _userProducts = await _postService.getUserProducts(currentUserId);
          break;
        case 2: // Saved
          _userSavedPosts = await _postService.getUserBookmarkedPosts(
            currentUserId,
          );
          break;
        case 3: // Liked
          _userLikedPosts = await _postService.getUserLikedPosts(currentUserId);
          break;
      }
    } catch (e) {
      debugPrint('Error loading tab content: $e');
    }

    setState(() {
      _isLoadingContent = false;
    });
  }

  // ... (build methods stay similar until _buildContentGrid)

  @override
  Widget build(BuildContext context) {
    return Consumer<auth_provider.AuthProvider>(
      builder: (context, auth_provider.AuthProvider authProvider, child) {
        // ... (existing build logic mainly calls stats widgets which take ints/strings)
        // Check if user is authenticated - but don't show prompt if just loading
        if (!authProvider.isAuthenticated && !authProvider.isLoading) {
          return RequireLoginPrompt(
            onLogin: () {
              context.go('/login');
            },
            onSignUp: () {
              context.go('/register');
            },
            onDismiss: () {
              Navigator.pop(context);
            },
          );
        }

        // Show loading indicator while checking authentication
        if (authProvider.isLoading || authProvider.currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show error message if any
        if (authProvider.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(child: Text('Error: ${authProvider.errorMessage}')),
          );
        }

        // Get user data
        UserModel? user = authProvider.currentUser;

        return Scaffold(
          backgroundColor: Colors.white,
          body: user == null
              ? const Center(child: Text('No user data available'))
              : RefreshIndicator(
                  onRefresh: _loadProfileData,
                  child: CustomScrollView(
                    slivers: [
                      // AppBar with Settings button
                      SliverAppBar(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        pinned: false,
                        floating: true,
                        title: Text(
                          user.username,
                          style: const TextStyle(
                            color: Color(0xFF0D3D67),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(
                              Icons.add_box_outlined,
                              color: Color(0xFF0D3D67),
                            ),
                            onPressed: () {
                              context.push('/add-post');
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Color(0xFF0D3D67),
                            ),
                            onPressed: () {
                              context.push('/settings');
                            },
                          ),
                        ],
                      ),
                      // Header with profile info
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Stats Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildProfileStat(
                                        _followingCount.toString(),
                                        'Following',
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FollowListScreen(
                                                userId: user.id,
                                                username: user.username,
                                                initialTabIndex: 1,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Avatar
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundImage:
                                            user.profileImageUrl != null &&
                                                user.profileImageUrl!.isNotEmpty
                                            ? NetworkImage(
                                                user.profileImageUrl!,
                                              )
                                            : null,
                                        backgroundColor: Colors.grey[200],
                                        child:
                                            user.profileImageUrl == null ||
                                                user.profileImageUrl!.isEmpty
                                            ? const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Color(0xFFFF6F00),
                                              )
                                            : null,
                                      ),
                                      _buildProfileStat(
                                        _followersCount.toString(),
                                        'Followers',
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FollowListScreen(
                                                userId: user.id,
                                                username: user.username,
                                                initialTabIndex: 0,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Name
                                Text(
                                  user.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF0D3D67),
                                  ),
                                ),
                                Text(
                                  '@${user.username}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                if (user.bio != null &&
                                    user.bio!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    user.bio!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                // Actions
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32.0,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                _shareProfile(context, user);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFF2F2F2,
                                                ),
                                                foregroundColor: Colors.black,
                                                elevation: 0,
                                              ),
                                              child: const Text(
                                                'Share Profile',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                // Edit Profile nav
                                                context.push('/edit-profile');
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFFF6F00,
                                                ),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                              ),
                                              child: const Text('Edit Profile'),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            context.push('/orders-history');
                                          },
                                          icon: const Icon(Icons.shopping_bag),
                                          label: const Text('My Orders'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF0D3D67,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Tabs
                                Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFEEEEEE),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildTabIconWithCount(
                                        0,
                                        Icons.video_library,
                                        Icons.video_library_outlined,
                                        _reelsCount,
                                      ),
                                      _buildTabIconWithCount(
                                        1,
                                        Icons.shopping_bag,
                                        Icons.shopping_bag_outlined,
                                        _productsCount,
                                      ),
                                      _buildTabIconWithCount(
                                        2,
                                        Icons.bookmark,
                                        Icons.bookmark_border,
                                        null,
                                      ), // Saved
                                      _buildTabIconWithCount(
                                        3,
                                        Icons.favorite,
                                        Icons.favorite_border,
                                        _userLikedPosts.isNotEmpty
                                            ? _userLikedPosts.length
                                            : null,
                                      ), // Liked
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 650,
                          child: _isLoadingContent
                              ? const Center(child: CircularProgressIndicator())
                              : _buildTabContent(),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileStat(String number, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Color(0xFF0D3D67),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTabIconWithCount(
    int index,
    IconData filledIcon,
    IconData outlineIcon,
    int? count,
  ) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        _loadTabContent();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: isSelected
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFFF6F00), width: 2),
                ),
              )
            : null,
        child: Column(
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? const Color(0xFFFF6F00) : Colors.grey,
              size: 24,
            ),
            if (count != null)
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color(0xFFFF6F00) : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildContentGrid(
          _userReels,
          'No reels yet',
          'Start creating reels to see them here',
        );
      case 1:
        return _buildContentGrid(
          _userProducts,
          'No products yet',
          'Start adding products to see them here',
        );
      case 2:
        return _buildContentGrid(
          _userSavedPosts,
          'No saved content yet',
          'Save posts to see them here',
        );
      case 3:
        return _buildContentGrid(
          _userLikedPosts,
          'No liked content yet',
          'Like posts to see them here',
        );
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  Widget _buildContentGrid(
    List<PostModel> items,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(emptyTitle, emptySubtitle);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // debugPrint('📹 Profile Grid: Rendering item ${item.id}');

        return GestureDetector(
          onTap: () {
            // Navigate to video player or reels screen with this post
            if (item.type == 'reel' || item.type == 'video') {
              context.push('/reels', extra: {'startPostId': item.id});
            } else {
              // Could navigate to full post detail screen
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: item.videoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _getThumbnailUrl(item),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error);
                      },
                    ),
                  )
                : const Icon(Icons.image),
          ),
        );
      },
    );
  }

  String _getThumbnailUrl(PostModel item) {
    if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty) {
      return item.thumbnailUrl!;
    }
    // Generate Cloudinary thumbnail from video URL
    if (item.videoUrl.contains('cloudinary.com') &&
        item.videoUrl.endsWith('.mp4')) {
      return item.videoUrl.replaceAll('.mp4', '.jpg');
    }
    return item.videoUrl;
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getEmptyStateIcon(), size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedTabIndex) {
      case 0:
        return Icons.video_library_outlined;
      case 1:
        return Icons.shopping_bag_outlined;
      case 2:
        return Icons.bookmark_border;
      case 3:
        return Icons.favorite_border;
      default:
        return Icons.help_outline;
    }
  }

  void _shareProfile(BuildContext context, UserModel user) {
    final String profileUrl = 'https://buyv.app/profile/${user.id}';
    final String shareText =
        'Check out ${user.displayName ?? user.username}\'s profile on BuyV!\n\n'
        'Followers: ${user.followersCount}\n'
        'Following: ${user.followingCount}\n'
        'Posts: ${user.reelsCount}\n\n'
        '$profileUrl';

    Share.share(
      shareText,
      subject: '${user.displayName ?? user.username}\'s BuyV Profile',
    );
  }
}
