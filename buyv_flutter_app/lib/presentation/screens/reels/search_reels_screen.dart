import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_service.dart';
import '../../../services/post_service.dart';
import '../../../domain/models/user_model.dart';
import '../../../data/models/post_model.dart';

/// Search Reels Screen - Recherche Vidéo & Sociale
/// 
/// Structure conforme aux screenshots :
/// - AppBar avec TextField actif et bordure orange
/// - TabBar avec 2 onglets : Reels | Users
/// - Onglet Reels : Grille 3 colonnes avec thumbnails + views count
/// - Onglet Users : Liste avec avatar, nom, @username et bouton Follow
class SearchReelsScreen extends StatefulWidget {
  const SearchReelsScreen({super.key});

  @override
  State<SearchReelsScreen> createState() => _SearchReelsScreenState();
}

class _SearchReelsScreenState extends State<SearchReelsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  
  late TabController _tabController;
  
  List<PostModel> _reelsResults = [];
  List<UserModel> _usersResults = [];
  bool _isSearching = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _reelsResults.clear();
        _usersResults.clear();
        _currentQuery = '';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query.trim();
    });

    try {
      // TODO: Implement proper search methods in PostService and UserService
      // For now, just clear the results
      setState(() {
        _reelsResults.clear();
        _usersResults.clear();
        _isSearching = false;
      });
      
      // Uncomment when searchReels and searchUsers are implemented:
      /*
      final reelsFuture = _postService.searchReels(_currentQuery);
      final usersFuture = _userService.searchUsers(_currentQuery);
      
      final results = await Future.wait([reelsFuture, usersFuture]);
      
      setState(() {
        _reelsResults = results[0] as List<PostModel>;
        _usersResults = results[1] as List<UserModel>;
        _isSearching = false;
      });
      */
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            _buildSearchHeader(),
            
            // TabBar
            _buildTabBar(),
            
            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReelsTab(),
                  _buildUsersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF0066CC)),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Color(0xFFFF6F00), width: 2),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  // Debouncing - search after 500ms of inactivity
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _performSearch(value);
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search reels or users...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.search, color: Color(0xFFFF6F00), size: 28),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Color(0xFFFF6F00),
        indicatorWeight: 3,
        labelColor: Color(0xFFFF6F00),
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelColor: Colors.grey,
        unselectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        tabs: [
          Tab(text: 'Reels'),
          Tab(text: 'Users'),
        ],
      ),
    );
  }

  Widget _buildReelsTab() {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator(color: Color(0xFFFF6F00)));
    }

    if (_currentQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'Search for reels',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_reelsResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'No reels found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(2),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.7,
      ),
      itemCount: _reelsResults.length,
      itemBuilder: (context, index) {
        final reel = _reelsResults[index];
        return _buildReelThumbnail(reel);
      },
    );
  }

  Widget _buildReelThumbnail(PostModel reel) {
    return GestureDetector(
      onTap: () {
        // Navigate to reel detail
        context.push('/reels/${reel.id}');
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          Container(
            color: Colors.grey[300],
            child: reel.thumbnailUrl != null && reel.thumbnailUrl!.isNotEmpty
                ? Image.network(
                    reel.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.video_library, size: 40, color: Colors.grey);
                    },
                  )
                : Icon(Icons.video_library, size: 40, color: Colors.grey),
          ),
          
          // Bottom overlay with avatar and views
          Positioned(
            left: 8,
            bottom: 8,
            child: Row(
              children: [
                // User avatar (small)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: reel.userProfileImage != null && reel.userProfileImage!.isNotEmpty
                        ? Image.network(
                            reel.userProfileImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person, size: 20, color: Colors.grey);
                            },
                          )
                        : Icon(Icons.person, size: 20, color: Colors.grey),
                  ),
                ),
                SizedBox(width: 8),
                // Views count
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_formatViews(reel.viewsCount ?? 0)} views',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator(color: Color(0xFFFF6F00)));
    }

    if (_currentQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'Search for users',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_usersResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _usersResults.length,
      itemBuilder: (context, index) {
        final user = _usersResults[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey[300],
        child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  user.profileImageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.person, size: 30, color: Colors.grey);
                  },
                ),
              )
            : Icon(Icons.person, size: 30, color: Colors.grey),
      ),
      title: Text(
        user.displayName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        '@${user.username}',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      trailing: ElevatedButton(
        onPressed: () {
          // Navigate to user profile
          context.push('/profile/${user.id}');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0066CC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        ),
        child: Text('Follow', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      onTap: () => context.push('/profile/${user.id}'),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }
}
