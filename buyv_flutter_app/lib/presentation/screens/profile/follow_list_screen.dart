import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/models/user_model.dart';
import '../../../services/follow_service.dart';
import '../../../services/user_service.dart';
import '../../providers/auth_provider.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String username;
  final int initialTabIndex;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialTabIndex = 0,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FollowService _followService = FollowService();
  final UserService _userService = UserService();

  List<UserFollowModel> _followers = [];
  List<UserFollowModel> _following = [];
  List<UserFollowModel> _friends = [];
  List<UserFollowModel> _suggested = [];

  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;
  bool _isLoadingFriends = true;
  bool _isLoadingSuggested = true;

  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, // Followers, Following, Friends, Suggested
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadFollowers(),
      _loadFollowing(),
      _loadFriends(),
      _loadSuggested(),
    ]);
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoadingFollowers = true);
    try {
      final followerIds = await _followService.getFollowers(widget.userId);
      _followersCount = followerIds.length;
      
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      _followers = [];
      
      for (final followerId in followerIds) {
        final user = await _userService.getUserProfile(followerId);
        if (user != null && currentUserId != null) {
          // Follower is following me by definition (they're in my followers list)
          final isFollowingMe = true;
          // Check if I follow them back
          final isIFollow = await _followService.isFollowing(followerId);
          
          _followers.add(UserFollowModel(
            id: user.id,
            username: user.username,
            displayName: user.displayName,
            profileImageUrl: user.profileImageUrl,
            isFollowingMe: isFollowingMe,
            isIFollow: isIFollow,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading followers: $e');
    }
    setState(() => _isLoadingFollowers = false);
  }

  Future<void> _loadFollowing() async {
    setState(() => _isLoadingFollowing = true);
    try {
      final followingIds = await _followService.getFollowing(widget.userId);
      _followingCount = followingIds.length;
      
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      _following = [];
      
      for (final followingId in followingIds) {
        final user = await _userService.getUserProfile(followingId);
        if (user != null && currentUserId != null) {
          // Check if this user follows me back (get their following list)
          final theirFollowing = await _followService.getFollowing(followingId);
          final isFollowingMe = theirFollowing.contains(currentUserId);
          final isIFollow = true; // We're in the following list
          
          _following.add(UserFollowModel(
            id: user.id,
            username: user.username,
            displayName: user.displayName,
            profileImageUrl: user.profileImageUrl,
            isFollowingMe: isFollowingMe,
            isIFollow: isIFollow,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading following: $e');
    }
    setState(() => _isLoadingFollowing = false);
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoadingFriends = true);
    try {
      // Friends are users who follow each other (mutual followers)
      final followerIds = await _followService.getFollowers(widget.userId);
      final followingIds = await _followService.getFollowing(widget.userId);
      
      final friendIds = followerIds.toSet().intersection(followingIds.toSet()).toList();
      
      _friends = [];
      for (final friendId in friendIds) {
        final user = await _userService.getUserProfile(friendId);
        if (user != null) {
          _friends.add(UserFollowModel(
            id: user.id,
            username: user.username,
            displayName: user.displayName,
            profileImageUrl: user.profileImageUrl,
            isFollowingMe: true,
            isIFollow: true,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading friends: $e');
    }
    setState(() => _isLoadingFriends = false);
  }

  Future<void> _loadSuggested() async {
    setState(() => _isLoadingSuggested = true);
    try {
      final suggestedIds = await _followService.getSuggestedUsers();
      _suggested = [];
      
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      for (final suggestedId in suggestedIds) {
        final user = await _userService.getUserProfile(suggestedId);
        if (user != null && currentUserId != null) {
          // Check if suggested user follows me
          final theirFollowing = await _followService.getFollowing(suggestedId);
          final isFollowingMe = theirFollowing.contains(currentUserId);
          final isIFollow = await _followService.isFollowing(suggestedId);
          
          _suggested.add(UserFollowModel(
            id: user.id,
            username: user.username,
            displayName: user.displayName,
            profileImageUrl: user.profileImageUrl,
            isFollowingMe: isFollowingMe,
            isIFollow: isIFollow,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading suggested users: $e');
    }
    setState(() => _isLoadingSuggested = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF0066CC),
          ),
        ),
        title: Text(
          widget.username,
          style: const TextStyle(
            color: Color(0xFF0066CC),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF114B7F),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF0066CC),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'Followers ($_followersCount)'),
            Tab(text: 'Following ($_followingCount)'),
            Tab(text: 'Friends'),
            Tab(text: 'Suggested'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowersTab(),
          _buildFollowingTab(),
          _buildFriendsTab(),
          _buildSuggestedTab(),
        ],
      ),
    );
  }

  Widget _buildFollowersTab() {
    if (_isLoadingFollowers) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6F00),
        ),
      );
    }

    if (_followers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No followers yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        final user = _followers[index];
        return _UserFollowItem(
          user: user,
          onFollowClick: () => _toggleFollow(user),
          onUserClick: () => _navigateToProfile(user.id),
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    if (_isLoadingFollowing) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6F00),
        ),
      );
    }

    if (_following.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Not following anyone yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _following.length,
      itemBuilder: (context, index) {
        final user = _following[index];
        return _UserFollowItem(
          user: user,
          onFollowClick: () => _toggleFollow(user),
          onUserClick: () => _navigateToProfile(user.id),
        );
      },
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoadingFriends) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6F00),
        ),
      );
    }

    if (_friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No friends yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final user = _friends[index];
        return _UserFollowItem(
          user: user,
          onFollowClick: () => _toggleFollow(user),
          onUserClick: () => _navigateToProfile(user.id),
        );
      },
    );
  }

  Widget _buildSuggestedTab() {
    if (_isLoadingSuggested) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6F00),
        ),
      );
    }

    if (_suggested.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No suggestions available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _suggested.length,
      itemBuilder: (context, index) {
        final user = _suggested[index];
        return _UserFollowItem(
          user: user,
          onFollowClick: () => _toggleFollow(user),
          onUserClick: () => _navigateToProfile(user.id),
        );
      },
    );
  }

  Future<void> _toggleFollow(UserFollowModel user) async {
    // Show confirmation dialog for unfollow
    if (user.isIFollow) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Unfollow ${user.displayName}?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF114B7F),
            ),
          ),
          content: Text(
            'Are you sure you want to unfollow ${user.displayName}?',
            style: const TextStyle(color: Color(0xFF114B7F)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF0066CC)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Unfollow',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      if (user.isIFollow) {
        await _followService.unfollowUser(user.id);
      } else {
        await _followService.followUser(user.id);
      }
      
      // Reload data
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${user.isIFollow ? 'unfollow' : 'follow'} user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToProfile(String userId) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    
    if (userId == currentUserId) {
      context.go('/profile');
    } else {
      context.push('/other-profile/$userId');
    }
  }
}

// UserFollowModel to hold follow relationship data
class UserFollowModel {
  final String id;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final bool isFollowingMe;
  final bool isIFollow;

  UserFollowModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.profileImageUrl,
    required this.isFollowingMe,
    required this.isIFollow,
  });
}

// User Follow Item Widget
class _UserFollowItem extends StatelessWidget {
  final UserFollowModel user;
  final VoidCallback onFollowClick;
  final VoidCallback onUserClick;

  const _UserFollowItem({
    required this.user,
    required this.onFollowClick,
    required this.onUserClick,
  });

  String get buttonText {
    if (user.isFollowingMe && user.isIFollow) {
      return 'Friends';
    } else if (user.isIFollow) {
      return 'Following';
    } else if (user.isFollowingMe) {
      return 'Follow back';
    } else {
      return 'Follow';
    }
  }

  Color get buttonColor {
    if (user.isIFollow || (user.isFollowingMe && user.isIFollow)) {
      return const Color(0xFFF2F2F2); // Light gray for Following/Friends
    } else {
      return const Color(0xFFFF6600); // Orange for Follow/Follow back
    }
  }

  Color get buttonTextColor {
    if (user.isIFollow || (user.isFollowingMe && user.isIFollow)) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onUserClick,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Profile Image
            CircleAvatar(
              radius: 25,
              backgroundImage: user.profileImageUrl != null && 
                              user.profileImageUrl!.isNotEmpty
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              backgroundColor: Colors.grey[200],
              child: user.profileImageUrl == null || 
                     user.profileImageUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 25,
                      color: Color(0xFFFF6F00),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isNotEmpty 
                        ? user.displayName 
                        : user.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF114B7F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Follow Button
            SizedBox(
              width: 110,
              height: 36,
              child: ElevatedButton(
                onPressed: onFollowClick,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: buttonTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}