import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/post_model.dart';
import '../../../domain/models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../services/follow_service.dart';
import '../../../services/post_service.dart';
import '../../providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Other User Profile Screen - Vue du profil d''un autre utilisateur
/// 
/// Structure conforme au design Kotlin :
/// - Top Bar : Bouton retour orange + Bouton Follow/Following
/// - Stats avec avatar central (Following | Avatar | Followers)
/// - Display Name + Username
/// - Posts count
/// - Share Profile button
/// - Bio (optionnel)
/// - Tabs : Reels | Products
/// - Grille de contenu (3 colonnes)
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

  // Follow status
  bool _isFollowing = false;

  // Content lists
  List<PostModel> _userReels = [];
  List<PostModel> _userProducts = [];

  bool _isLoading = true;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Load user profile
      final user = await _userService.getUserById(widget.userId);
      
      // Load statistics
      final stats = await _userService.getUserStats(widget.userId);
      
      // Check follow status
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      bool following = false;
      if (currentUserId != null) {
        following = await _followService.isFollowing(currentUserId, widget.userId);
      }
      
      // Load user content
      final reels = await _postService.getUserReels(widget.userId);
      final products = await _postService.getUserProducts(widget.userId);

      setState(() {
        _userProfile = user;
        _followersCount = stats[''followers''] ?? 0;
        _followingCount = stats[''following''] ?? 0;
        _postsCount = stats[''posts''] ?? 0;
        _isFollowing = following;
        _userReels = reels;
        _userProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(''Failed to load profile: $e''),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (currentUserId == null) return;

    setState(() => _isFollowLoading = true);

    try {
      if (_isFollowing) {
        await _followService.unfollowUser(currentUserId, widget.userId);
        setState(() {
          _isFollowing = false;
          _followersCount = _followersCount > 0 ? _followersCount - 1 : 0;
        });
      } else {
        await _followService.followUser(currentUserId, widget.userId);
        setState(() {
          _isFollowing = true;
          _followersCount = _followersCount + 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(''Failed to update follow status: $e''),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isFollowLoading = false);
    }
  }

  void _shareProfile() {
    final username = _userProfile?.username ?? widget.username ?? ''user'';
    Share.share(''Check out @$username''s profile on BuyV!'');
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).currentUser?.id;
    final isOwnProfile = currentUserId == widget.userId;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6F00)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Color(0xFFFF6F00), size: 28),
                      onPressed: () => context.pop(),
                    ),
                    if (!isOwnProfile)
                      ElevatedButton(
                        onPressed: _isFollowLoading ? null : _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey : Color(0xFFFF6F00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        ),
                        child: _isFollowLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isFollowing ? ''Following'' : ''Follow'',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Stats + Profile Image
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStat(_followingCount.toString(), ''Following'', () {
                      // Navigate to following list
                    }),
                    
                    const SizedBox(width: 32),
                    
                    // Profile Image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF0F0F0),
                      ),
                      child: ClipOval(
                        child: _userProfile?.avatarUrl != null && _userProfile!.avatarUrl.isNotEmpty
                            ? Image.network(
                                _userProfile!.avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    ''assets/images/default_avatar.png'',
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.asset(
                                ''assets/images/default_avatar.png'',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    
                    const SizedBox(width: 32),
                    
                    _buildStat(_followersCount.toString(), ''Followers'', () {
                      // Navigate to followers list
                    }),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Name & Username
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _userProfile?.displayName ?? ''User'',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D3D67),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    ''@${_userProfile?.username ?? widget.username ?? "user"}'',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Posts Count
            SliverToBoxAdapter(
              child: _buildStat(_postsCount.toString(), ''Posts''),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Share Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: ElevatedButton(
                  onPressed: _shareProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF2F2F2),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 42),
                  ),
                  child: Text(
                    ''Share Profile'',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Bio (if exists)
            if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _userProfile!.bio!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Tabs
            SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _selectedTabIndex = 0),
                    icon: Icon(
                      Icons.play_circle_outline,
                      size: 30,
                      color: _selectedTabIndex == 0 ? Color(0xFFFF6F00) : Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedTabIndex = 1),
                    icon: Icon(
                      Icons.shopping_bag_outlined,
                      size: 20,
                      color: _selectedTabIndex == 1 ? Color(0xFFFF6F00) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Content Grid
            _selectedTabIndex == 0 ? _buildReelsGrid() : _buildProductsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String number, String label, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D3D67),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelsGrid() {
    if (_userReels.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(''No reels yet'', ''This user hasn''t posted any reels''),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final reel = _userReels[index];
            return GestureDetector(
              onTap: () {
                // Navigate to reel detail
                context.push(''/reels/${reel.id}'');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                ),
                child: reel.mediaUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            reel.thumbnailUrl ?? reel.mediaUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.video_library, size: 40, color: Colors.grey);
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(Icons.play_circle_outline, color: Colors.white, size: 24),
                          ),
                        ],
                      )
                    : Icon(Icons.video_library, size: 40, color: Colors.grey),
              ),
            );
          },
          childCount: _userReels.length,
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_userProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(''No products yet'', ''This user hasn''t posted any products''),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _userProducts[index];
            return GestureDetector(
              onTap: () {
                // Navigate to product detail
                context.push(''/products/${product.id}'');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                ),
                child: product.mediaUrl != null
                    ? Image.network(
                        product.mediaUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.shopping_bag, size: 40, color: Colors.grey);
                        },
                      )
                    : Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
              ),
            );
          },
          childCount: _userProducts.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
