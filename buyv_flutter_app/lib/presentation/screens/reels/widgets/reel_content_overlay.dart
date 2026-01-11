import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/reel_model.dart';
import '../../../providers/cart_provider.dart';

/// ReelContentOverlay - Contenu superposé sur la vidéo
/// Info utilisateur à gauche + boutons d'interaction à droite
class ReelContentOverlay extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onCartTap;
  final VoidCallback onShareTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onUserTap;
  final VoidCallback onProductTap;

  const ReelContentOverlay({
    super.key,
    required this.reel,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onCartTap,
    required this.onShareTap,
    required this.onBookmarkTap,
    required this.onUserTap,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // GAUCHE: UserInfo + Description + Hashtags + OfferCard
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _UserInfo(reel: reel),
                const SizedBox(height: 8),
                _ReelDescription(description: reel.caption),
                const SizedBox(height: 4),
                if (reel.hashtags.isNotEmpty)
                  _ReelHashtags(hashtags: reel.hashtags),
                const SizedBox(height: 12),
                if (reel.hasProduct && reel.product != null)
                  _OfferCard(reel: reel, onProductTap: onProductTap),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // DROITE: InteractionButtons
          _InteractionButtons(
            reel: reel,
            onLikeTap: onLikeTap,
            onCommentTap: onCommentTap,
            onCartTap: onCartTap,
            onShareTap: onShareTap,
            onBookmarkTap: onBookmarkTap,
            onUserTap: onUserTap,
          ),
        ],
      ),
    );
  }
}

/// UserInfo - Username + Follow button
class _UserInfo extends StatelessWidget {
  final ReelModel reel;

  const _UserInfo({required this.reel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          reel.username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 3)],
          ),
        ),
        if (reel.isUserVerified) ...[
          const SizedBox(width: 4),
          const Icon(Icons.verified, color: Colors.blue, size: 14),
        ],
        const SizedBox(width: 12),
        _FollowButton(),
      ],
    );
  }
}

/// Follow Button avec gradient orange-rouge
class _FollowButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFf8a714), Color(0xFFed380a)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Follow +',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Description du reel
class _ReelDescription extends StatelessWidget {
  final String description;

  const _ReelDescription({required this.description});

  @override
  Widget build(BuildContext context) {
    return Text(
      description.isNotEmpty ? description : 'Sample Post',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.4,
        shadows: [Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 3)],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Hashtags - Couleur orange
class _ReelHashtags extends StatelessWidget {
  final List<String> hashtags;

  const _ReelHashtags({required this.hashtags});

  @override
  Widget build(BuildContext context) {
    final hashtagText = hashtags.map((tag) => '#$tag').join(' ');
    return Text(
      hashtagText.isNotEmpty ? hashtagText : '#satisfying #roadmarking',
      style: const TextStyle(
        color: Color(0xFFFF6F00),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// OfferCard - Card produit en bas à gauche
class _OfferCard extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onProductTap;

  const _OfferCard({required this.reel, required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    final product = reel.product;
    if (product == null) return const SizedBox.shrink();

    return Transform.translate(
      offset: const Offset(-12, 0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xCC222222),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product image
            ClipOval(
              child: product.imageUrls.isNotEmpty
                  ? Image.network(product.imageUrls.first, width: 44, height: 44, fit: BoxFit.cover)
                  : Container(
                      width: 44, height: 44,
                      color: Colors.grey[400],
                      child: const Icon(Icons.image, color: Colors.white),
                    ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(product.category, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onProductTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFf8a714), Color(0xFFed380a)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '\$${product.finalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFFFFEB3B), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// InteractionButtons - Colonne verticale à droite
class _InteractionButtons extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onCartTap;
  final VoidCallback onShareTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onUserTap;

  const _InteractionButtons({
    required this.reel,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onCartTap,
    required this.onShareTap,
    required this.onBookmarkTap,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final isInCart = cartProvider.isProductInCart(reel.product?.id ?? '');
    final cartQty = cartProvider.getProductQuantity(reel.product?.id ?? '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        _AvatarButton(reel: reel, onTap: onUserTap),
        const SizedBox(height: 16),
        // Like
        _ActionButton(
          icon: reel.isLiked ? Icons.favorite : Icons.favorite_border,
          count: reel.likesCount.toString(),
          color: reel.isLiked ? Colors.red : Colors.white,
          onTap: onLikeTap,
        ),
        const SizedBox(height: 16),
        // Comment
        _ActionButton(
          icon: Icons.comment_outlined,
          count: reel.commentsCount.toString(),
          onTap: onCommentTap,
        ),
        const SizedBox(height: 16),
        // Cart
        _ActionButton(
          icon: Icons.shopping_cart_outlined,
          count: isInCart ? cartQty.toString() : '0',
          color: isInCart ? const Color(0xFFFFC107) : Colors.white,
          onTap: onCartTap,
        ),
        const SizedBox(height: 16),
        // Share
        _ActionButton(icon: Icons.share_outlined, count: 'Share', onTap: onShareTap),
        const SizedBox(height: 16),
        // Bookmark
        _ActionButton(
          icon: reel.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          count: '',
          color: reel.isBookmarked ? const Color(0xFFFF6F00) : Colors.white,
          onTap: onBookmarkTap,
        ),
        const SizedBox(height: 16),
        // Music
        _MusicButton(),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Avatar button
class _AvatarButton extends StatelessWidget {
  final ReelModel reel;
  final VoidCallback onTap;

  const _AvatarButton({required this.reel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundImage: reel.userProfileImage.isNotEmpty ? NetworkImage(reel.userProfileImage) : null,
          backgroundColor: Colors.grey[400],
          child: reel.userProfileImage.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
        ),
      ),
    );
  }
}

/// Action button générique
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String count;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.count,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Music button
class _MusicButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        gradient: const LinearGradient(colors: [Color(0xFF333333), Color(0xFF666666)]),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 16),
    );
  }
}
