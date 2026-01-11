import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../shop/widgets/product_card.dart';

/// ProductDetailScreen style Kotlin
/// - Header: Back button + "Details" title (bleu)
/// - Image produit avec indicateurs de page + icône cœur
/// - Nom + Rating (étoile jaune)
/// - Description
/// - Select Size: chips (vert si sélectionné, gris sinon)
/// - Prix orange + compteur quantité (bordure bleue)
/// - Section Recommended avec "See All"
/// - Bouton "Add To Cart" orange en bas
class ProductDetailScreenNew extends StatefulWidget {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final String category;
  final String? description;
  final double? rating;
  final List<String>? sizes;
  final List<String>? productImages;

  const ProductDetailScreenNew({
    super.key,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.category,
    this.description,
    this.rating,
    this.sizes,
    this.productImages,
  });

  @override
  State<ProductDetailScreenNew> createState() => _ProductDetailScreenNewState();
}

class _ProductDetailScreenNewState extends State<ProductDetailScreenNew> {
  int _quantity = 1;
  bool _isFavorite = false;
  String? _selectedSize;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  // Tailles - utilisent les données réelles du produit
  late List<String> _availableSizes;

  // Images du produit - utilisent les vraies images
  late List<String> _productImages;

  @override
  void initState() {
    super.initState();
    // Utiliser les tailles réelles passées, ou liste vide si aucune variante
    _availableSizes = widget.sizes ?? [];
    _selectedSize = _availableSizes.isNotEmpty ? _availableSizes.first : null;
    
    // Utiliser les vraies images du produit, ou l'image principale
    if (widget.productImages != null && widget.productImages!.isNotEmpty) {
      _productImages = widget.productImages!;
    } else if (widget.productImage.isNotEmpty) {
      _productImages = [widget.productImage];
    } else {
      _productImages = [];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Back + Title
                    _buildHeader(),
                    
                    const SizedBox(height: 12),
                    
                    // Image produit avec PageView
                    _buildProductImage(),
                    
                    const SizedBox(height: 12),
                    
                    // Nom + Rating
                    _buildNameAndRating(),
                    
                    const SizedBox(height: 8),
                    
                    // Description
                    _buildDescription(),
                    
                    const SizedBox(height: 12),
                    
                    // Select Size
                    _buildSizeSelector(),
                    
                    const SizedBox(height: 12),
                    
                    // Prix + Compteur quantité
                    _buildPriceAndQuantity(),
                    
                    const SizedBox(height: 16),
                    
                    // Section Recommended
                    _buildRecommendedSection(),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Bouton Add To Cart fixe en bas
            _buildAddToCartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Bouton retour
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/icons/ic_back.png',
                  width: 24,
                  height: 24,
                  color: const Color(0xFF0066CC),
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF0066CC),
                      size: 22,
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Titre centré (dans l'espace restant)
          const Expanded(
            child: Center(
              child: Text(
                'Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066CC),
                ),
              ),
            ),
          ),
          
          // Espace équivalent pour équilibrer le header
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // Image principale avec PageView
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _productImages.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return _productImages[index].isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _productImages[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image, size: 60, color: Colors.grey),
                          ),
                        );
                },
              ),
            ),
          ),
          
          // Icône cœur (favoris)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() => _isFavorite = !_isFavorite);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isFavorite 
                        ? 'Added to favorites' 
                        : 'Removed from favorites'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: _isFavorite ? Colors.red : const Color(0xFF176DBA),
                  ),
                ),
              ),
            ),
          ),
          
          // Indicateurs de page
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_productImages.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? const Color(0xFF176DBA)
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameAndRating() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nom du produit
          Expanded(
            child: Text(
              widget.productName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Rating
          Row(
            children: [
              const Icon(
                Icons.star,
                size: 20,
                color: Color(0xFFFFC107),
              ),
              const SizedBox(width: 4),
              Text(
                (widget.rating ?? 4.8).toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        widget.description ?? 
            "With a nocturnal influence, ${widget.productName} explores Mademoiselle's ...",
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
          height: 1.4,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSizeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Size :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _availableSizes.map((size) {
              final isSelected = size == _selectedSize;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSize = size),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF22C55E)  // Vert si sélectionné
                          : const Color(0xFF7F7F7F), // Gris sinon
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      size,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
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

  Widget _buildPriceAndQuantity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Prix en orange
          Text(
            '${widget.price.toStringAsFixed(0)}\$',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF5722),
            ),
          ),
          
          // Compteur quantité avec bordure bleue
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF176DBA)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Bouton -
                IconButton(
                  onPressed: _quantity > 0 ? () => setState(() => _quantity--) : null,
                  icon: const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                
                // Quantité
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B74DA),
                    ),
                  ),
                ),
                
                // Bouton +
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Text(
                    '+',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection() {
    // Section Recommended simplifiée - basée sur la catégorie
    // Pour une implémentation complète, charger des produits similaires via API
    return Column(
      children: [
        // Header: Recommended + See All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to see all recommended (catégorie du produit actuel)
                  context.push('/all-products/${widget.category}');
                },
                child: const Row(
                  children: [
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
        
        // Message invitant à voir plus de produits
        Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 40,
                  color: Color(0xFF176DBA),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore more in ${widget.category}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.push('/all-products/${widget.category}'),
                  child: const Text(
                    'Browse Products',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF176DBA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    final cartProvider = Provider.of<CartProvider>(context);
    // Vérifier si le produit est déjà dans le panier
    final isInCart = cartProvider.items.any((item) => item.product.id == widget.productId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (isInCart) {
              // Aller au panier
              context.push('/cart');
            } else {
              // Créer le ProductModel et ajouter au panier
              final productModel = ProductModel(
                id: widget.productId,
                name: widget.productName,
                description: widget.description ?? '',
                price: widget.price,
                discountPrice: null,
                category: widget.category,
                imageUrls: _productImages,
                videoUrl: null,
                stockQuantity: 100,
                isAvailable: true,
                rating: widget.rating ?? 0.0,
                reviewsCount: 0,
                sellerId: 'cj_dropshipping',
                sellerName: 'CJ Dropshipping',
                tags: [],
                specifications: {},
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                viewsCount: 0,
                likesCount: 0,
                isFeatured: false,
              );
              
              cartProvider.addToCart(
                productModel,
                quantity: _quantity > 0 ? _quantity : 1,
                selectedSize: _selectedSize,
              );
              
              // Afficher confirmation
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.productName} added to cart!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6F00),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_cart,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                isInCart ? 'Go to Cart' : 'Add To Cart',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
