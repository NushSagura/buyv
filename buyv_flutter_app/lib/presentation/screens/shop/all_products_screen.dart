import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/cj_dropshipping_service.dart';
import '../../../domain/models/cj_product_model.dart';
import 'widgets/product_card.dart';
import 'cj_cart_helper.dart';

/// AllProductsScreen style Kotlin
/// - Header: Back + Titre centré (bleu) + Search + Notifications
/// - Grille de produits 2 colonnes
class AllProductsScreen extends StatefulWidget {
  final String title;

  const AllProductsScreen({
    super.key,
    required this.title,
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  List<CJProduct> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await CJDropshippingService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  List<ShopProduct> get _shopProducts {
    return _products.map((p) => ShopProduct(
      id: p.pid ?? '',
      name: p.productName,
      imageUrl: p.productImage ?? '',
      price: p.sellPrice ?? 0.0,
      rating: 4.5,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Grille de produits
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProductsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          // Bouton retour
          IconButton(
            onPressed: () => context.pop(),
            icon: Image.asset(
              'assets/icons/ic_back.png',
              width: 24,
              height: 24,
              color: const Color(0xFF0066CC),
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF0066CC),
                );
              },
            ),
          ),
          
          // Titre centré
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0066CC),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Icônes à droite
          Row(
            children: [
              // Search
              IconButton(
                onPressed: () => context.push('/search-products'),
                icon: const Icon(
                  Icons.search,
                  size: 28,
                  color: Colors.black,
                ),
              ),
              
              // Notifications - même style que Shop
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Image.asset(
                  'assets/icons/notification_icon.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.notifications_outlined,
                      size: 28,
                      color: Color(0xFFFFC107),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_shopProducts.isEmpty) {
      return const Center(
        child: Text(
          'No products found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemCount: _shopProducts.length,
      itemBuilder: (context, index) {
        final product = _shopProducts[index];
        return _buildProductGridCard(product);
      },
    );
  }

  Widget _buildProductGridCard(ShopProduct product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF176DBA),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec icône panier
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 40),
                          ),
                  ),
                ),
                
                // Icône panier en bas à droite
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _addToCart(product),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        size: 18,
                        color: Color(0xFF176DBA),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Informations produit
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '4000+ added to cart',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)}\$',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(product.price * 1.2).toStringAsFixed(0)}\$',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0B0B0),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProductDetail(ShopProduct product) {
    context.push(
      '/product/${product.id}',
      extra: {
        'productName': product.name,
        'productImage': product.imageUrl,
        'price': product.price,
        'category': widget.title,
      },
    );
  }

  void _addToCart(ShopProduct product) {
    final cjProduct = _products.firstWhere(
      (p) => p.pid == product.id,
      orElse: () => _products.first,
    );
    
    // Utiliser le helper pour convertir et ajouter au panier
    addCJProductToCart(context, cjProduct);
  }
}
