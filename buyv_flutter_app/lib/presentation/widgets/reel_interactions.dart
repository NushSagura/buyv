import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/reel_model.dart';

class ReelInteractions extends StatefulWidget {
  final ReelModel reel;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onBookmark;
  final VoidCallback onProfile;
  final VoidCallback? onCart;
  final bool isInCart;

  const ReelInteractions({
    super.key,
    required this.reel,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark,
    required this.onProfile,
    this.onCart,
    this.isInCart = false,
  });

  @override
  State<ReelInteractions> createState() => _ReelInteractionsState();
}

class _ReelInteractionsState extends State<ReelInteractions>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  late AnimationController _bookmarkAnimationController;
  late Animation<double> _bookmarkScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Like animation
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Bookmark animation
    _bookmarkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bookmarkScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _bookmarkAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _bookmarkAnimationController.dispose();
    super.dispose();
  }

  void _onLikeTap() {
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });
    widget.onLike();
  }

  void _onBookmarkTap() {
    _bookmarkAnimationController.forward().then((_) {
      _bookmarkAnimationController.reverse();
    });
    widget.onBookmark();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile picture
        GestureDetector(
          onTap: widget.onProfile,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: widget.reel.userProfileImage.isNotEmpty
                  ? NetworkImage(widget.reel.userProfileImage)
                  : null,
              backgroundColor: Colors.grey[300],
              child: widget.reel.userProfileImage.isEmpty
                  ? const Icon(Icons.person, size: 24, color: Colors.grey)
                  : null,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Cart button (Add/Remove from cart)
        Column(
          children: [
            GestureDetector(
              onTap: () {
                if (widget.onCart != null) {
                  widget.onCart!();
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black26,
                ),
                child: Icon(
                  widget.isInCart
                      ? Icons.shopping_cart_checkout
                      : Icons.add_shopping_cart,
                  color: widget.isInCart
                      ? const Color(0xFFFF6F00)
                      : Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Like button
        Column(
          children: [
            GestureDetector(
              onTap: _onLikeTap,
              child: AnimatedBuilder(
                animation: _likeScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _likeScaleAnimation.value,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black26,
                      ),
                      child: Icon(
                        widget.reel.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.reel.isLiked ? Colors.red : Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatCount(widget.reel.likesCount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Comment button
        Column(
          children: [
            GestureDetector(
              onTap: widget.onComment,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black26,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatCount(widget.reel.commentsCount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Share button
        Column(
          children: [
            GestureDetector(
              onTap: widget.onShare,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black26,
                ),
                child: const Icon(
                  Icons.share_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatCount(widget.reel.sharesCount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Bookmark button
        Column(
          children: [
            GestureDetector(
              onTap: _onBookmarkTap,
              child: AnimatedBuilder(
                animation: _bookmarkScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bookmarkScaleAnimation.value,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black26,
                      ),
                      child: Icon(
                        widget.reel.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: widget.reel.isBookmarked
                            ? Colors.yellow
                            : Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // More options button
        GestureDetector(
          onTap: () {
            _showMoreOptions(context);
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black26,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Options
            _buildOptionItem(
              icon: Icons.report_outlined,
              title: 'Report Content',
              onTap: () {
                Navigator.pop(context);
                // TODO: Report content
              },
            ),

            _buildOptionItem(
              icon: Icons.block_outlined,
              title: 'Block User',
              onTap: () {
                Navigator.pop(context);
                _blockUser();
              },
            ),

            _buildOptionItem(
              icon: Icons.copy_outlined,
              title: 'Copy Link',
              onTap: () {
                Navigator.pop(context);
                _copyVideoLink();
              },
            ),

            _buildOptionItem(
              icon: Icons.download_outlined,
              title: 'Save Video',
              onTap: () {
                Navigator.pop(context);
                _saveVideo();
              },
            ),

            _buildOptionItem(
              icon: Icons.not_interested_outlined,
              title: 'Not Interested',
              onTap: () {
                Navigator.pop(context);
                _markNotInterested();
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _blockUser() {
    // Simulate blocking user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User blocked successfully'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _copyVideoLink() {
    // Simulate copying video link to clipboard
    Clipboard.setData(
      const ClipboardData(text: 'https://example.com/video/123'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video link copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveVideo() {
    // Simulate saving video to device
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video saved to gallery'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _markNotInterested() {
    // Simulate marking video as not interested
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Marked as not interested. We\'ll show you fewer videos like this.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
