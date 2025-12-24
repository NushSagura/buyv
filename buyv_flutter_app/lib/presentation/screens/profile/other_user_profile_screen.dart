import '../../../data/models/post_model.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_api_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../services/follow_service.dart';
import '../../../services/post_service.dart';
import 'follow_list_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  final String? username;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    this.username,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  int _selectedTabIndex = 0;
  final UserService _userService = UserService();
  final FollowService _followService = FollowService();
  final PostService _postService = PostService();

  // User data
  UserModel? _userProfile;

  // Statistics
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  int _reelsCount = 0;
  int _productsCount = 0;

  // Follow status
  bool _isFollowing = false;

  // Content lists
  List<PostModel> _userReels = [];
  List<PostModel> _userProducts = [];

  bool _isLoading = true;
  bool _isLoadingContent = true;
  bool _isFollowLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load user profile
      final userProfile = await _userService.getUserProfile(widget.userId);
      if (userProfile != null) {
        _userProfile = userProfile;

        // Load statistics
        final futures = [
          _userService.getFollowersCount(widget.userId),
          _userService.getFollowingCount(widget.userId),
          _userService.getUserPostsCount(widget.userId),
          _userService.getUserReelsCount(widget.userId),
          _userService.getUserProductsCount(widget.userId),
        ];

        final results = await Future.wait(futures);

        _followersCount = results[0];
        _followingCount = results[1];
        _postsCount = results[2];
        _reelsCount = results[3];
        _productsCount = results[4];

        // Check follow status
        try {
          final me = await AuthApiService.me();
          final currentUserId = me['id'] as String?;
          if (currentUserId != null && currentUserId != widget.userId) {
            _isFollowing = await _followService.isFollowing(widget.userId);
          }
        } catch (_) {}

        setState(() {
          _isLoading = false;
        });

        // Load content for current tab
        await _loadTabContent();
      } else {
        setState(() {
          _error = 'User profile not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTabContent() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      switch (_selectedTabIndex) {
        case 0: // Reels
          _userReels = await _postService.getUserReels(widget.userId);
          break;
        case 1: // Products
          _userProducts = await _postService.getUserProducts(widget.userId);
          break;
      }
    } catch (e) {
      debugPrint('Error loading tab content: $e');
    }

    setState(() {
      _isLoadingContent = false;
    });
  }

  Future<void> _toggleFollow() async {
    String? currentUserId;
    try {
      final me = await AuthApiService.me();
      currentUserId = me['id'] as String?;
    } catch (_) {}
    if (currentUserId == null || currentUserId == widget.userId) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (_isFollowing) {
        await _followService.unfollowUser(widget.userId);
        _followersCount = (_followersCount > 0) ? _followersCount - 1 : 0;
      } else {
        await _followService.followUser(widget.userId);
        _followersCount++;
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${_isFollowing ? 'unfollow' : 'follow'} user',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isFollowLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6F00)),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6F00)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6F00)),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6F00),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final currentUserId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser?.id;
    final showFollowButton =
        currentUserId != null && currentUserId != widget.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: CustomScrollView(
          slivers: [
            // Header with back button and follow button
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFFFF6F00),
                          size: 28,
                        ),
                      ),
                      if (showFollowButton)
                        ElevatedButton(
                          onPressed: _isFollowLoading ? null : _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing
                                ? Colors.grey
                                : const Color(0xFFFF6F00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isFollowLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isFollowing ? 'Following' : 'Follow',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Profile content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Stats + Profile Image Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Following stat
                          _buildProfileStat(
                            _followingCount.toString(),
                            'Following',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowListScreen(
                                    userId: widget.userId,
                                    username: _userProfile?.username ?? 'user',
                                    initialTabIndex:
                                        1, // Start with Following tab
                                  ),
                                ),
                              );
                            },
                          ),

                          // Profile Image
                          CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                _userProfile?.profileImageUrl != null &&
                                    _userProfile!.profileImageUrl!.isNotEmpty
                                ? NetworkImage(_userProfile!.profileImageUrl!)
                                : null,
                            backgroundColor: Colors.grey[200],
                            child:
                                _userProfile?.profileImageUrl == null ||
                                    _userProfile!.profileImageUrl!.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFFFF6F00),
                                  )
                                : null,
                          ),

                          // Followers stat
                          _buildProfileStat(
                            _followersCount.toString(),
                            'Followers',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowListScreen(
                                    userId: widget.userId,
                                    username: _userProfile?.username ?? 'user',
                                    initialTabIndex:
                                        0, // Start with Followers tab
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Name & Username
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userProfile?.displayName.isNotEmpty == true
                              ? _userProfile!.displayName
                              : 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D3D67),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '@${_userProfile?.username.isNotEmpty == true ? _userProfile!.username : 'user'}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    // Posts stat
                    _buildProfileStat(_postsCount.toString(), 'Posts', () {}),

                    const SizedBox(height: 16),

                    // Bio
                    if (_userProfile?.bio != null &&
                        _userProfile!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          _userProfile!.bio!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF333333),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Share Profile Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_userProfile != null) {
                              _shareProfile(context, _userProfile!);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2F2F2),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Share Profile',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tab Icons Row with counts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Content Grid based on selected tab
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
    int count,
  ) {
    final isSelected = _selectedTabIndex == index;
    return Column(
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedTabIndex = index;
            });
            _loadTabContent();
          },
          icon: Icon(
            isSelected ? filledIcon : outlineIcon,
            color: isSelected ? const Color(0xFFFF6F00) : Colors.grey,
            size: index == 0 ? 30 : 20,
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? const Color(0xFFFF6F00) : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        // User Reels
        return _buildContentGrid(
          _userReels,
          'No reels yet',
          'This user hasn\'t posted any reels',
        );
      case 1:
        // User Products
        return _buildContentGrid(
          _userProducts,
          'No products yet',
          'This user hasn\'t added any products',
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
        return GestureDetector(
          onTap: () {
            // Navigate to post detail or handle tap
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
                      item.thumbnailUrl ?? item.videoUrl,
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
