import 'package:flutter/material.dart';
import '../../../services/auth_api_service.dart';
import '../../../domain/models/user_model.dart';
import '../../../services/follow_api_service.dart';
import '../../../services/post_api_service.dart';
import '../../../data/models/post_model.dart';
import 'post_detail_screen.dart';

/// Screen to display user profile (for deep linking)
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _user;
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user data and posts in parallel
      final results = await Future.wait([
        AuthApiService.getUser(widget.userId),
        PostApiService.getUserPosts(widget.userId, limit: 20),
        FollowApiService.isFollowing(widget.userId),
      ]);

      final userData = results[0] as Map<String, dynamic>;
      final postsData = results[1] as List<Map<String, dynamic>>;
      final isFollowing = results[2] as bool;

      setState(() {
        _user = UserModel.fromJson(userData);
        _posts = postsData.map((p) => PostModel.fromJson(p)).toList();
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load user profile: $e';
      });
    }
  }

  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        await FollowApiService.unfollowUser(widget.userId);
        setState(() => _isFollowing = false);
      } else {
        await FollowApiService.followUser(widget.userId);
        setState(() => _isFollowing = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _user?.username ?? 'Profile',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              final shareUrl = 'buyv://user/${widget.userId}';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share URL: $shareUrl')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _user == null
                  ? const Center(
                      child: Text(
                        'User not found',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUserProfile,
                      child: CustomScrollView(
                        slivers: [
                          // Profile Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  // Profile Image
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundImage: _user!.profileImageUrl != null
                                        ? NetworkImage(_user!.profileImageUrl!)
                                        : null,
                                    child: _user!.profileImageUrl == null
                                        ? Text(
                                            _user!.username[0].toUpperCase(),
                                            style: const TextStyle(fontSize: 32),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Display Name
                                  Text(
                                    _user!.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Username
                                  Text(
                                    '@${_user!.username}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Stats Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatColumn(
                                        _user!.reelsCount.toString(),
                                        'Posts',
                                      ),
                                      _buildStatColumn(
                                        _user!.followersCount.toString(),
                                        'Followers',
                                      ),
                                      _buildStatColumn(
                                        _user!.followingCount.toString(),
                                        'Following',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Follow Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _toggleFollow,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isFollowing
                                            ? Colors.grey[800]
                                            : const Color(0xFFE94057),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(
                                        _isFollowing ? 'Following' : 'Follow',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Bio
                                  if (_user!.bio != null) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      _user!.bio!,
                                      style: const TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Tab Bar
                          SliverToBoxAdapter(
                            child: TabBar(
                              controller: _tabController,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: const Color(0xFFE94057),
                              tabs: const [
                                Tab(icon: Icon(Icons.grid_on)),
                                Tab(icon: Icon(Icons.video_library)),
                                Tab(icon: Icon(Icons.shopping_bag)),
                              ],
                            ),
                          ),

                          // Posts Grid
                          SliverPadding(
                            padding: const EdgeInsets.all(8.0),
                            sliver: _posts.isEmpty
                                ? SliverToBoxAdapter(
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(32.0),
                                        child: Text(
                                          'No posts yet',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 4,
                                      mainAxisSpacing: 4,
                                      childAspectRatio: 1,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final post = _posts[index];
                                        return GestureDetector(
                                          onTap: () {
                                            // Navigate to post detail
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PostDetailScreen(
                                                  postId: post.id,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[900],
                                              image: post.videoUrl.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        post.videoUrl,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: post.videoUrl.isEmpty
                                                ? const Center(
                                                    child: Icon(
                                                      Icons.image,
                                                      color: Colors.grey,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        );
                                      },
                                      childCount: _posts.length,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
