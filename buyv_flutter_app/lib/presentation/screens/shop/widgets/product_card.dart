import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Modèle de produit pour l'UI
class ShopProduct {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double? rating;
  final bool isFavorite;
  final String? originalPrice;

  const ShopProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.rating,
    this.isFavorite = false,
    this.originalPrice,
  });
}

/// Carte produit style Kotlin
/// - Bordure bleue (#176DBA)
/// - Icône cœur en haut à droite (cercle blanc)
/// - Image produit
/// - Nom, Rating (étoiles), Prix orange, icône panier bleue
class ProductCard extends StatefulWidget {
  final ShopProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddToCartTap;
  final double width;
  final double imageHeight;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoriteTap,
    this.onAddToCartTap,
    this.width = 160,
    this.imageHeight = 120,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF176DBA),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image avec icône cœur
              _buildImageSection(),
              
              const SizedBox(height: 8),
              
              // Nom du produit
              Text(
                widget.product.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Rating (étoiles)
              _buildRatingBar(),
              
              const SizedBox(height: 4),
              
              // Prix et icône panier
              _buildPriceRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image produit
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: widget.imageHeight,
            width: double.infinity,
            color: Colors.grey[200],
            child: widget.product.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
          ),
        ),
        
        // Icône cœur (wishlist)
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              widget.onFavoriteTap?.call();
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: const Color(0xFF176DBA),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar() {
    final rating = widget.product.rating ?? 0.0;
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    const totalStars = 5;
    final emptyStars = totalStars - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      children: [
        // Étoiles pleines
        ...List.generate(fullStars, (index) => const Icon(
          Icons.star,
          size: 16,
          color: Color(0xFFFFC107),
        )),
        
        // Demi-étoile si nécessaire
        if (hasHalfStar)
          const Icon(
            Icons.star_half,
            size: 16,
            color: Color(0xFFFFC107),
          ),
        
        // Étoiles vides
        ...List.generate(emptyStars, (index) => const Icon(
          Icons.star_border,
          size: 16,
          color: Color(0xFFFFC107),
        )),
        
        const SizedBox(width: 4),
        
        // Note numérique
        Text(
          rating.toString(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Prix
        Text(
          '${widget.product.price.toStringAsFixed(0)}\$',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6F00),
          ),
        ),
        
        // Icône panier
        GestureDetector(
          onTap: widget.onAddToCartTap,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.shopping_cart,
                size: 16,
                color: Color(0xFF176DBA),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section de produits avec titre et "See All"
class ProductSection extends StatelessWidget {
  final String title;
  final List<ShopProduct> products;
  final VoidCallback? onSeeAllTap;
  final Function(ShopProduct)? onProductTap;
  final Function(ShopProduct)? onFavoriteTap;
  final Function(ShopProduct)? onAddToCartTap;

  const ProductSection({
    super.key,
    required this.title,
    required this.products,
    this.onSeeAllTap,
    this.onProductTap,
    this.onFavoriteTap,
    this.onAddToCartTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header: Titre + See All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: onSeeAllTap,
                child: Row(
                  children: const [
                    Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0B74DA),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right,
                      size: 18,
                      color: Color(0xFF0B74DA),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Liste horizontale de produits
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => onProductTap?.call(product),
                onFavoriteTap: () => onFavoriteTap?.call(product),
                onAddToCartTap: () => onAddToCartTap?.call(product),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Placeholder de chargement pour les produits
class ProductsLoadingPlaceholder extends StatelessWidget {
  final int count;

  const ProductsLoadingPlaceholder({
    super.key,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
