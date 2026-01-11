import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/cj_dropshipping_service.dart';
import '../../../domain/models/cj_product_model.dart';
import '../../providers/cart_provider.dart';
import 'cj_cart_helper.dart';

// Widgets modulaires
import 'widgets/shop_top_bar.dart';
import 'widgets/shop_search_bar.dart';
import 'widgets/sales_card.dart';
import 'widgets/category_item.dart';
import 'widgets/product_card.dart';

/// ShopScreen style Kotlin
/// - TopBar avec Logo centré + Notifications
/// - SearchBar avec bordure bleue
/// - SalesCard (bannière bleue avec bouton orange)
/// - Catégories horizontales avec images
/// - Sections produits: Featured Products + Best Sellers
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // Catégories avec images (simulées pour l'instant)
  final List<ShopCategory> _categories = [
    const ShopCategory(name: 'Perfumes', imageUrl: 'https://images.unsplash.com/photo-1541643600914-78b084683601?w=200'),
    const ShopCategory(name: 'Clothing', imageUrl: 'https://images.unsplash.com/photo-1558171813-4c088753af8f?w=200'),
    const ShopCategory(name: 'Furniture', imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=200'),
    const ShopCategory(name: 'Electronics', imageUrl: 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=200'),
    const ShopCategory(name: 'Watches', imageUrl: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=200'),
  ];

  List<CJProduct> _cjProducts = [];
  bool _isLoading = false;
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final products = await CJDropshippingService.getProducts();
      setState(() {
        _cjProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ShopProduct> get _shopProducts {
    return _cjProducts.map((p) => ShopProduct(
      id: p.pid ?? '',
      name: p.productName,
      imageUrl: p.productImage ?? '',
      price: p.sellPrice ?? 0.0,
      rating: 4.5, // Default rating
    )).toList();
  }

  List<ShopProduct> get _filteredProducts {
    var products = _shopProducts;
    
    if (_searchQuery.isNotEmpty) {
      products = products.where((p) => 
        p.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    if (_selectedCategory != null) {
      products = products.where((p) => 
        p.name.toLowerCase().contains(_selectedCategory!.toLowerCase())
      ).toList();
    }
    
    return products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // TopBar avec Logo + Notifications
            SliverToBoxAdapter(
              child: ShopTopBar(
                onNotificationTap: () {
                  // Navigate to notifications
                  context.push('/notifications');
                },
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            
            // SearchBar (cliquable, redirige vers SearchScreen)
            SliverToBoxAdapter(
              child: ShopSearchBar(
                searchQuery: _searchQuery,
                onTap: () => context.push('/search-products'),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            
            // Bannière Sales
            SliverToBoxAdapter(
              child: SalesCard(
                onShopNowTap: () {
                  // Scroll to products ou navigate
                },
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            
            // Catégories horizontales
            SliverToBoxAdapter(
              child: _isLoading
                  ? const CategoriesLoadingPlaceholder()
                  : CategoriesList(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = _selectedCategory == category ? null : category;
                        });
                      },
                    ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Section Featured Products
            if (_isLoading)
              const SliverToBoxAdapter(
                child: ProductsLoadingPlaceholder(),
              )
            else if (_selectedCategory == null) ...[
              // Afficher Featured Products et Best Sellers
              SliverToBoxAdapter(
                child: ProductSection(
                  title: 'Featured Products',
                  products: _filteredProducts.take(10).toList(),
                  onSeeAllTap: () => context.push('/all-products/Featured Products'),
                  onProductTap: (product) => _navigateToProductDetail(product),
                  onAddToCartTap: (product) => _addToCart(product),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              
              SliverToBoxAdapter(
                child: ProductSection(
                  title: 'Best Sellers',
                  products: _filteredProducts.skip(5).take(10).toList(),
                  onSeeAllTap: () => context.push('/all-products/Best Sellers'),
                  onProductTap: (product) => _navigateToProductDetail(product),
                  onAddToCartTap: (product) => _addToCart(product),
                ),
              ),
            ] else
              // Afficher les produits de la catégorie sélectionnée
              SliverToBoxAdapter(
                child: ProductSection(
                  title: 'Category: $_selectedCategory',
                  products: _filteredProducts,
                  onSeeAllTap: () => context.push('/all-products/$_selectedCategory'),
                  onProductTap: (product) => _navigateToProductDetail(product),
                  onAddToCartTap: (product) => _addToCart(product),
                ),
              ),
            
            // Espace en bas pour le bottom nav
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  void _navigateToProductDetail(ShopProduct product) {
    // Trouver le CJProduct correspondant
    final cjProduct = _cjProducts.firstWhere(
      (p) => p.pid == product.id,
      orElse: () => _cjProducts.first,
    );
    
    // Extraire les tailles/variantes du produit
    final List<String> sizes = cjProduct.variants.isNotEmpty
        ? cjProduct.variants.map((v) => v.variantName.isNotEmpty ? v.variantName : v.variantNameEn).toList()
        : [];
    
    context.push(
      '/product/${product.id}',
      extra: {
        'productName': product.name,
        'productImage': product.imageUrl,
        'price': product.price,
        'category': cjProduct.categoryName.isNotEmpty ? cjProduct.categoryName : (_selectedCategory ?? 'All'),
        'description': cjProduct.description.isNotEmpty ? cjProduct.description : cjProduct.descriptionEn,
        'rating': cjProduct.rating,
        'sizes': sizes,
        'productImages': cjProduct.productImages,
        'variants': cjProduct.variants.map((v) => v.toJson()).toList(),
      },
    );
  }

  void _addToCart(ShopProduct product) {
    // Trouver le CJProduct correspondant
    final cjProduct = _cjProducts.firstWhere(
      (p) => p.pid == product.id,
      orElse: () => _cjProducts.first,
    );
    
    // Utiliser le helper pour convertir et ajouter au panier
    addCJProductToCart(context, cjProduct);
  }
}
