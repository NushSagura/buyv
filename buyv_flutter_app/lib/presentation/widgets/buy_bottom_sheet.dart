import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/product_model.dart';

/// BuyBottomSheet - Modal d'achat avec sélection taille/couleur/quantité
/// Migré depuis Kotlin ModernBottomSheetContent (ReelsView.kt)
///
/// Structure (comme screenshot #2):
/// - Close button (X) en haut à droite
/// - Product name + Rating (★ 4.8)
/// - Description
/// - Select Size (chips: XS, S, L, M, XL)
/// - Select Color (cercles de couleurs)
/// - Prix ($29.99) + Quantity selector (- 0 +)
/// - Buy button circulaire orange
class BuyBottomSheet extends StatefulWidget {
  final ProductModel product;
  final void Function(int quantity, String? promoterId) onAddToCart;
  final void Function(int quantity, String? promoterId) onBuyNow;
  final bool disableImages;
  final String? promoterId;

  const BuyBottomSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onBuyNow,
    this.disableImages = false,
    this.promoterId,
  });

  @override
  State<BuyBottomSheet> createState() => _BuyBottomSheetState();
}

class _BuyBottomSheetState extends State<BuyBottomSheet> {
  int _quantity = 1;
  String? _selectedSize;
  int _selectedColorIndex = 0;

  // Tailles disponibles - comme le screenshot
  final List<String> _sizes = ['XS', 'S', 'L', 'M', 'XL'];

  // Couleurs disponibles - comme le screenshot
  final List<Color> _colors = [
    const Color(0xFFFF9800), // Orange
    const Color(0xFF2196F3), // Blue
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFF9E9E9E), // Grey
    const Color(0xFF9C27B0), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _selectedSize = 'S'; // 'S' sélectionné par défaut comme screenshot
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec handle bar + close button
            _buildHeader(),
            // Product Info (Name + Rating)
            _buildProductInfo(product),
            // Description
            _buildDescription(product),
            // Select Size
            _buildSizeSelector(),
            // Select Color
            _buildColorSelector(),
            // Price + Quantity
            _buildPriceAndQuantity(product),
            // Buy button circulaire
            _buildBuyButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Header avec handle bar et bouton close (X)
  Widget _buildHeader() {
    return Stack(
      children: [
        // Handle bar centrée
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Close button (X) en haut à droite
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
              shape: const CircleBorder(),
            ),
          ),
        ),
      ],
    );
  }

  /// Product info (name + rating ★ 4.8)
  Widget _buildProductInfo(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          // Rating comme le screenshot
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFF9800), size: 18),
              const SizedBox(width: 4),
              Text(
                product.rating?.toStringAsFixed(1) ?? '4.8',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Description du produit
  Widget _buildDescription(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        product.description.isNotEmpty
            ? product.description
            : 'Sample Product - High quality product with great features.',
        style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Sélecteur de taille avec chips (XS, S, L, M, XL)
  Widget _buildSizeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Size:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _sizes.map((size) {
              final isSelected = _selectedSize == size;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSize = size),
                  child: Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4CAF50) // Vert quand sélectionné
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        size,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Sélecteur de couleur avec cercles
  Widget _buildColorSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Color:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_colors.length, (index) {
              final isSelected = _selectedColorIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _colors[index],
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Prix + Sélecteur de quantité (- 0 +) avec border bleu
  Widget _buildPriceAndQuantity(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Prix orange
          Text(
            '\$${product.finalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF9800),
            ),
          ),
          // Quantity selector avec border bleu
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF176DBA), width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _quantity > 0
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove, size: 20),
                  color: const Color(0xFF176DBA),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF176DBA),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add, size: 20),
                  color: const Color(0xFF176DBA),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Buy button circulaire orange
  Widget _buildBuyButton() {
    return Center(
      child: GestureDetector(
        onTap: () => widget.onBuyNow(_quantity, widget.promoterId),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
            border: Border.all(color: Colors.white, width: 6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Buy',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}