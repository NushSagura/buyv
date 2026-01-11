import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../../services/post_service.dart';
import '../../../data/models/post_model.dart';

/// Profile Screen - Design Kotlin
/// Structure:
/// - Header avec notifications et menu (hamburger)
/// - Stats (Following | Avatar | Followers)
/// - Nom + badge vérifié + @username
/// - Likes count
/// - Boutons Edit Profile / Share Profile
/// - Bouton Add New Post (orange)
/// - Tabs (Reels, Products, Saved, Liked)
/// - Grid de posts
class ProfileScreenKotlin extends StatefulWidget {
  final String? userId;  // Optional: if provided, show other user's profile

  const ProfileScreenKotlin({super.key, this.userId});

  @override
  State<ProfileScreenKotlin> createState() => _ProfileScreenKotlinState();
}

class _ProfileScreenKotlinState extends State<ProfileScreenKotlin> {
  int _selectedTab = 0; // 0: Reels, 1: Products, 2: Saved, 3: Liked
  final PostService _postService = PostService();
  
  List<PostModel> _userReels = [];
  List<PostModel> _userProducts = [];
  List<PostModel> _userSaved = [];
  List<PostModel> _userLiked = [];
  
  bool _isLoading = true;
  int _followingCount = 0;
  int _followersCount = 0;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Charger les posts utilisateur
      final posts = await _postService.getUserPosts(userId, limit: 50, offset: 0);
      
      // Séparer par type
      final reels = posts.where((p) => p.type == 'reel' || p.videoUrl.contains('.mp4')).toList();
      final products = posts.where((p) => p.type == 'product').toList();
      
      // Charger les posts bookmarkés
      final savedPosts = await _postService.getUserBookmarkedPosts(userId, limit: 50, offset: 0);
      
      // Charger les stats
      // TODO: Implémenter API pour followers/following/likes
      
      if (mounted) {
        setState(() {
          _userReels = reels;
          _userProducts = products;
          _userSaved = savedPosts;
          _followingCount = authProvider.currentUser?.followingCount ?? 0;
          _followersCount = authProvider.currentUser?.followersCount ?? 0;
          _likesCount = 0; // TODO: Calculer total likes
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        if (user == null) {
          return _buildLoginPrompt();
        }

        if (_isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6F00)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshProfile,
              color: const Color(0xFFFF6F00),
              child: CustomScrollView(
                slivers: [
                  // Header avec notifications et menu
                  SliverToBoxAdapter(child: _buildHeader()),
                  
                  // Profile Info (Following | Avatar | Followers)
                  SliverToBoxAdapter(child: _buildProfileStats(user)),
                  
                  // Nom et username
                  SliverToBoxAdapter(child: _buildNameSection(user)),
                  
                  // Likes count
                  SliverToBoxAdapter(child: _buildLikesSection()),
                  
                  // Action buttons (Edit / Share)
                  SliverToBoxAdapter(child: _buildActionButtons()),
                  
                  // Add New Post button
                  SliverToBoxAdapter(child: _buildAddPostButton()),
                  
                  // Tabs
                  SliverToBoxAdapter(child: _buildTabs()),
                  
                  // Divider
                  const SliverToBoxAdapter(child: Divider(height: 1, color: Colors.grey)),
                  
                  // Posts Grid
                  SliverToBoxAdapter(child: _buildPostsGrid()),
                  
                  // Bottom spacing pour la nav bar
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Login Prompt - Style Kotlin avec gradient orange
  Widget _buildLoginPrompt() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône profil
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Titre
                  const Text(
                    'Join Our Community!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Sous-titre
                  Text(
                    'Sign in to view your profile, track orders, and connect with others.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Boutons Login / Sign up
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go('/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFFF6F00),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/signup'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: const BorderSide(color: Colors.white, width: 2),
                          ),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header avec notifications et menu hamburger (style Shop)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Notification bell avec badge - même style que Kotlin
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Image.asset(
                  'assets/icons/notification_icon.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.notifications_outlined,
                      size: 28,
                      color: Color(0xFFFFC107),
                    );
                  },
                ),
              ),
              // Badge rouge avec nombre
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3D00),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          
          // Menu hamburger
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(
              Icons.menu,
              color: Color(0xFFFF6F00),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  /// Stats: Following | Avatar | Followers
  Widget _buildProfileStats(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Following
          _buildStatColumn(
            value: _formatNumber(_followingCount),
            label: 'Following',
            onTap: () => _navigateToFollowList(1),
          ),
          
          const SizedBox(width: 32),
          
          // Avatar avec bordure
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0066CC),
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[200],
              backgroundImage: user.profileImageUrl != null && user.profileImageUrl.isNotEmpty
                  ? NetworkImage(user.profileImageUrl)
                  : null,
              child: user.profileImageUrl == null || user.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 48, color: Colors.grey)
                  : null,
            ),
          ),
          
          const SizedBox(width: 32),
          
          // Followers
          _buildStatColumn(
            value: _formatNumber(_followersCount),
            label: 'Followers',
            onTap: () => _navigateToFollowList(0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D3D67),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Nom + badge vérifié + @username
  Widget _buildNameSection(dynamic user) {
    final displayName = user.displayName ?? user.email?.split('@').first ?? 'User';
    final username = user.username ?? user.email?.split('@').first ?? 'user';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Nom (badge vérifié temporairement caché comme dans Kotlin)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D3D67),
                ),
              ),
              // Badge vérifié temporarily hidden - keeping code for future use
              /*
              const SizedBox(width: 4),
              if (user.isVerified == true)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0066CC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              */
            ],
          ),
          const SizedBox(height: 2),
          // @username
          Text(
            '@$username',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Likes count
  Widget _buildLikesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            _formatNumber(_likesCount),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D3D67),
            ),
          ),
          const Text(
            'Likes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Boutons Edit Profile / Share Profile
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
      child: Row(
        children: [
          // Edit Profile - Bleu
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.push('/edit-profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF176DBA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Share Profile - Gris clair
          Expanded(
            child: ElevatedButton(
              onPressed: _shareProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2F2F2),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Share Profile',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton Add New Post - Orange avec shadow
  Widget _buildAddPostButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6F00).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => context.push('/add-post'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6F00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            '+ Add New Post',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Tabs: Reels, Products, Saved, Liked
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabIcon(0, Icons.video_library, Icons.video_library_outlined, size: 30),
          _buildTabIcon(1, Icons.grid_view, Icons.grid_view_outlined, size: 24),
          _buildTabIcon(2, Icons.bookmark, Icons.bookmark_border, size: 24),
          _buildTabIcon(3, Icons.favorite, Icons.favorite_border, size: 24),
        ],
      ),
    );
  }

  Widget _buildTabIcon(int index, IconData selectedIcon, IconData unselectedIcon, {double size = 24}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Icon(
        isSelected ? selectedIcon : unselectedIcon,
        color: isSelected ? const Color(0xFFFF6F00) : Colors.grey,
        size: size,
      ),
    );
  }

  /// Grid de posts selon l'onglet sélectionné
  Widget _buildPostsGrid() {
    List<PostModel> posts;
    String emptyMessage;
    
    switch (_selectedTab) {
      case 0:
        posts = _userReels;
        emptyMessage = 'No reels yet';
        break;
      case 1:
        posts = _userProducts;
        emptyMessage = 'No products yet';
        break;
      case 2:
        posts = _userSaved;
        emptyMessage = 'No saved posts';
        break;
      case 3:
        posts = _userLiked;
        emptyMessage = 'No liked posts';
        break;
      default:
        posts = [];
        emptyMessage = 'No content';
    }

    if (posts.isEmpty) {
      // Messages spécifiques par tab comme dans Kotlin
      final emptyData = _getEmptyStateData();
      
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyData['icon'] as IconData,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              emptyData['title'] as String,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0066CC),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              emptyData['subtitle'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostThumbnail(post);
      },
    );
  }

  Widget _buildPostThumbnail(PostModel post) {
    // Générer la thumbnail URL
    String? thumbnailUrl = post.thumbnailUrl;
    
    // Si pas de thumbnail mais on a une vidéo, générer une thumbnail depuis Cloudinary
    if ((thumbnailUrl == null || thumbnailUrl.isEmpty) && post.videoUrl.isNotEmpty) {
      thumbnailUrl = _generateVideoThumbnail(post.videoUrl);
    }
    
    final bool isVideo = post.type == 'reel' || post.videoUrl.contains('.mp4');
    
    return GestureDetector(
      onTap: () {
        // Naviguer vers le post/reel
        if (post.type == 'reel') {
          context.push('/reels', extra: {'startPostId': post.id});
        } else {
          // Product detail
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail Image
          if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFFFF6F00),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(isVideo);
              },
            )
          else
            _buildPlaceholder(isVideo),
          
          // Overlay sombre pour les vidéos
          if (isVideo)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          
          // Icône play pour les vidéos (centrée)
          if (isVideo)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          
          // Views count en bas à gauche
          if (isVideo)
            Positioned(
              left: 6,
              bottom: 6,
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 14,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatNumber(post.viewsCount ?? 0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Génère une URL de thumbnail pour une vidéo Cloudinary
  String _generateVideoThumbnail(String videoUrl) {
    // Si c'est une URL Cloudinary, on peut générer une thumbnail
    if (videoUrl.contains('cloudinary.com')) {
      // Remplacer /video/upload/ par /video/upload/so_7,w_400,h_500,c_fill,f_jpg/
      // so_7 = start offset 7 secondes (frame à 7s de la vidéo)
      // w_400,h_500 = dimensions
      // c_fill = crop fill
      // f_jpg = format jpg
      final transformed = videoUrl.replaceFirst(
        '/video/upload/',
        '/video/upload/so_7,w_400,h_500,c_fill,f_jpg/',
      );
      // Remplacer l'extension .mp4 par .jpg
      return transformed.replaceAll('.mp4', '.jpg').replaceAll('.webm', '.jpg');
    }
    
    // Pour les autres URLs, retourner l'URL originale (le player affichera la première frame)
    return videoUrl;
  }

  /// Placeholder quand pas d'image disponible
  Widget _buildPlaceholder(bool isVideo) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam : Icons.image,
          color: Colors.grey[500],
          size: 32,
        ),
      ),
    );
  }

  void _navigateToFollowList(int tabIndex) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';
    final username = authProvider.currentUser?.username ?? 'user';
    context.push('/follow-list?userId=$userId&username=$username&tab=$tabIndex');
  }

  void _shareProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = authProvider.currentUser?.username ?? 'user';
    Share.share('Check out my profile on BuyV! @$username');
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  /// Retourne les donn\u00e9es pour empty state selon le tab s\u00e9lectionn\u00e9
  Map<String, dynamic> _getEmptyStateData() {
    switch (_selectedTab) {
      case 0: // Reels
        return {
          'icon': Icons.video_library_outlined,
          'title': 'No reels yet',
          'subtitle': 'Start creating reels to see them here',
        };
      case 1: // Products
        return {
          'icon': Icons.shopping_bag_outlined,
          'title': 'No products yet',
          'subtitle': 'Share products with your followers',
        };
      case 2: // Saved
        return {
          'icon': Icons.bookmark_border,
          'title': 'No saved posts',
          'subtitle': 'Save posts to view them later',
        };
      case 3: // Liked
        return {
          'icon': Icons.favorite_border,
          'title': 'No liked posts',
          'subtitle': 'Like posts to see them here',
        };
      default:
        return {
          'icon': Icons.inbox_outlined,
          'title': 'No content',
          'subtitle': 'Start sharing with the community',
        };
    }
  }
}
