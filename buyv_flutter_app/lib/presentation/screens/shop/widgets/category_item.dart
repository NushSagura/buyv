import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Modèle de catégorie
class ShopCategory {
  final String name;
  final String? imageUrl;
  final IconData? icon;

  const ShopCategory({
    required this.name,
    this.imageUrl,
    this.icon,
  });
}

/// Item catégorie style Kotlin
/// - Image en haut (80x85)
/// - Nom en bas sur fond gris semi-transparent
/// - Fond orange si sélectionné, gris sinon
class CategoryItem extends StatelessWidget {
  final ShopCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryItem({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 110,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6F00) : const Color(0xFF757575),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Image de la catégorie
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: SizedBox(
                width: 80,
                height: 85,
                child: _buildCategoryImage(),
              ),
            ),
            
            // Nom de la catégorie en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage() {
    if (category.imageUrl != null && category.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: category.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackIcon(),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: Colors.grey[400],
      child: Center(
        child: Icon(
          category.icon ?? _getCategoryIcon(category.name),
          size: 32,
          color: Colors.white70,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'perfumes':
        return Icons.spa;
      case 'clothing':
        return Icons.checkroom;
      case 'furniture':
        return Icons.chair;
      case 'electronics':
        return Icons.devices;
      case 'watches':
        return Icons.watch;
      case 'shoes':
        return Icons.ice_skating;
      case 'bags':
        return Icons.backpack;
      default:
        return Icons.category;
    }
  }
}

/// Liste horizontale de catégories
class CategoriesList extends StatelessWidget {
  final List<ShopCategory> categories;
  final String? selectedCategory;
  final ValueChanged<String>? onCategorySelected;

  const CategoriesList({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryItem(
            category: category,
            isSelected: category.name == selectedCategory,
            onTap: () => onCategorySelected?.call(category.name),
          );
        },
      ),
    );
  }
}

/// Placeholder de chargement pour les catégories
class CategoriesLoadingPlaceholder extends StatelessWidget {
  final int count;

  const CategoriesLoadingPlaceholder({
    super.key,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
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
