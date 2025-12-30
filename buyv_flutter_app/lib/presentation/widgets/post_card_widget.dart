import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/post_model.dart';
import '../../services/post_service.dart';
import 'video_player_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCardWidget extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const PostCardWidget({super.key, required this.post, this.onTap});

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  late bool _isLiked;
  late int _likesCount;
  late bool _isBookmarked;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _isBookmarked = widget.post.isBookmarked;
  }

  Future<void> _toggleLike() async {
    final previousState = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      if (previousState) {
        await _postService.unlikePost(widget.post.id);
      } else {
        await _postService.likePost(widget.post.id);
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = previousState;
          _likesCount += _isLiked ? 1 : -1;
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    final previousState = _isBookmarked;

    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    try {
      final success = previousState
          ? await PostService.unbookmarkPost(widget.post.id)
          : await PostService.bookmarkPost(widget.post.id);

      if (!success) {
        // Revert on failure
        if (mounted) {
          setState(() {
            _isBookmarked = previousState;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la sauvegarde')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isBookmarked ? 'Ajouté aux favoris' : 'Retiré des favoris',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isBookmarked = previousState;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        widget.post.userProfileImage != null &&
                            widget.post.userProfileImage!.isNotEmpty
                        ? NetworkImage(widget.post.userProfileImage!)
                        : null,
                    radius: 20,
                    child: widget.post.userProfileImage == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.post.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.post.isUserVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          timeago.format(widget.post.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      // Show options
                    },
                  ),
                ],
              ),
            ),

            // Post Media
            if (widget.post.type == 'reel' || widget.post.type == 'video') ...[
              // Video handling
              if (widget.post.videoUrl.isNotEmpty)
                Builder(
                  builder: (context) {
                    return AspectRatio(
                      aspectRatio:
                          9 /
                          16, // Reel aspect ratio usually, but could be 1:1 or 4:5
                      child: Container(
                        color: Colors.black,
                        child: VideoPlayerWidget(
                          videoUrl: widget.post.videoUrl,
                          autoPlay: false, // ✅ Désactivé pour éviter auto-play au retour
                          looping: true,
                        ),
                      ),
                    );
                  },
                )
              else
                Builder(
                  builder: (context) {
                    return Container(
                      color: Colors.black,
                      height: 400,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_off,
                              color: Colors.white54,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No video available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ] else ...[
              // Image handling
              if (widget
                  .post
                  .videoUrl
                  .isNotEmpty) // Reusing videoUrl field for mediaUrl for now as per schema logic
                AspectRatio(
                  aspectRatio: 1, // Square for photos by default
                  child: Image.network(
                    widget.post.videoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) {
                      debugPrint(
                        '❌ Error loading image: ${widget.post.videoUrl}',
                      );
                      debugPrint('Error: $e');
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                ),
            ],

            // Action Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : null,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text('$_likesCount'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined),
                    onPressed: () {
                      context.push('/post/${widget.post.id}/comments');
                    },
                  ),
                  Text('${widget.post.commentsCount}'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      final shareText =
                          '${widget.post.username} shared a post${widget.post.caption != null ? ': ${widget.post.caption}' : ''}';
                      Share.share(shareText);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _isBookmarked ? Colors.yellow[700] : null,
                    ),
                    onPressed: _toggleBookmark,
                  ),
                ],
              ),
            ),

            // Caption
            if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: '${widget.post.username} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: widget.post.caption),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
