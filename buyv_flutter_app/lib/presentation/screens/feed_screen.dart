import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../services/post_service.dart';
import '../widgets/post_card_widget.dart';
import 'package:provider/provider.dart';
import '../../data/providers/user_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostService _postService = PostService();
  final ScrollController _scrollController = ScrollController();

  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime? _lastPostUpdate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    if (_lastPostUpdate != null &&
        userProvider.lastPostUpdate != _lastPostUpdate) {
      _lastPostUpdate = userProvider.lastPostUpdate;
      _loadPosts();
    }
    _lastPostUpdate ??= userProvider.lastPostUpdate;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return; // Guard
    setState(() {
      _isLoading = true;
      _offset = 0;
      _posts = [];
      _hasMore = true;
    });

    try {
      final newPosts = await _postService.getFeedPosts(
        limit: _limit,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          _posts = newPosts;
          _offset += newPosts.length;
          _hasMore = newPosts.length == _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading feed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newPosts = await _postService.getFeedPosts(
        limit: _limit,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          if (newPosts.isEmpty) {
            _hasMore = false;
          } else {
            _posts.addAll(newPosts);
            _offset += newPosts.length;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('BuyV Feed'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _posts.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _posts.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return PostCardWidget(
              post: _posts[index],
              onTap: () {
                // Navigate to details if needed
              },
            );
          },
        ),
      ),
    );
  }
}
