import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/user_model.dart';
import '../../../services/follow_service.dart';
import '../../../services/user_service.dart';
import 'other_user_profile_screen.dart';
import '../../providers/auth_provider.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String username;
  final int initialTabIndex;
  final bool showSuggestedTab;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialTabIndex = 0,
    this.showSuggestedTab = false,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FollowService _followService = FollowService();
  final UserService _userService = UserService();

  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  List<UserModel> _suggested = [];

  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;
  bool _isLoadingSuggested = true;

  @override
  void initState() {
    super.initState();
    final tabCount = widget.showSuggestedTab ? 3 : 2;
    _tabController = TabController(
      length: tabCount,
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
      if (widget.showSuggestedTab) _loadSuggested(),
    ]);
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoadingFollowers = true);
    try {
      final followerIds = await _followService.getFollowers(widget.userId);
      _followers = [];
      for (final followerId in followerIds) {
        final user = await _userService.getUserProfile(followerId);
        if (user != null) {
          _followers.add(user);
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
      _following = [];
      for (final followingId in followingIds) {
        final user = await _userService.getUserProfile(followingId);
        if (user != null) {
          _following.add(user);
        }
      }
    } catch (e) {
      debugPrint('Error loading following: $e');
    }
    setState(() => _isLoadingFollowing = false);
  }

  Future<void> _loadSuggested() async {
    setState(() => _isLoadingSuggested = true);
    try {
      final suggestedIds = await _followService.getSuggestedUsers();
      _suggested = [];
      for (final suggestedId in suggestedIds) {
        final user = await _userService.getUserProfile(suggestedId);
        if (user != null) {
          _suggested.add(user);
        }
      }
    } catch (e) {
      debugPrint('Error loading suggested users: $e');
    }
    setState(() => _isLoadingSuggested = false);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      Tab(text: 'Followers (${_followers.length})'),
      Tab(text: 'Following (${_following.length})'),
      if (widget.showSuggestedTab) Tab(text: 'Suggested (${_suggested.length})'),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFFF6F00),
          ),
        ),
        title: Text(
          '@${widget.username}',
          style: const TextStyle(
            color: Color(0xFF0D3D67),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6F00),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF6F00),
          tabs: tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowersTab(),
          _buildFollowingTab(),
          if (widget.showSuggestedTab) _buildSuggestedTab(),
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

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.builder(
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final user = _followers[index];
          return _buildUserListItem(user);
        },
      ),
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

    return RefreshIndicator(
      onRefresh: _loadFollowing,
      child: ListView.builder(
        itemCount: _following.length,
        itemBuilder: (context, index) {
          final user = _following[index];
          return _buildUserListItem(user);
        },
      ),
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

    return RefreshIndicator(
      onRefresh: _loadSuggested,
      child: ListView.builder(
        itemCount: _suggested.length,
        itemBuilder: (context, index) {
          final user = _suggested[index];
          return _buildUserListItem(user, showFollowButton: true);
        },
      ),
    );
  }

  Widget _buildUserListItem(UserModel user, {bool showFollowButton = false}) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    final isCurrentUser = currentUserId == user.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
            ? NetworkImage(user.profileImageUrl!)
            : null,
        backgroundColor: Colors.grey[200],
        child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
            ? const Icon(
                Icons.person,
                size: 25,
                color: Color(0xFFFF6F00),
              )
            : null,
      ),
      title: Text(
        user.displayName.isNotEmpty ? user.displayName : 'User',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        '@${user.username.isNotEmpty ? user.username : 'user'}',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
      trailing: showFollowButton && !isCurrentUser
          ? _buildFollowButton(user)
          : const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
      onTap: () {
        if (!isCurrentUser) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(
                userId: user.id,
                username: user.username,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildFollowButton(UserModel user) {
    return FutureBuilder<bool>(
      future: _followService.isFollowing(user.id),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SizedBox(
          width: 80,
          height: 32,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (currentUserId == null) return;

                    try {
                      if (isFollowing) {
                        await _followService.unfollowUser(user.id);
                      } else {
                        await _followService.followUser(user.id);
                      }
                      setState(() {}); // Refresh the UI
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to ${isFollowing ? 'unfollow' : 'follow'} user'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey : const Color(0xFFFF6F00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.zero,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }
}