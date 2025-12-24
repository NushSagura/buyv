import 'package:flutter/foundation.dart';
import '../../domain/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch products from data source
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement actual data fetching from Firebase or API
      // For now, we'll create some sample products
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      _products = [
        ProductModel(
          id: '1',
          name: 'Sample Product 1',
          description: 'This is a sample product description',
          price: 29.99,
          category: 'Electronics',
          imageUrls: ['assets/images/perfume1.png'],
          stockQuantity: 10,
          sellerId: 'seller1',
          sellerName: 'Sample Seller',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ProductModel(
          id: '2',
          name: 'Sample Product 2',
          description: 'Another sample product description',
          price: 49.99,
          category: 'Clothing',
          imageUrls: ['assets/images/perfume2.png'],
          stockQuantity: 5,
          sellerId: 'seller2',
          sellerName: 'Another Seller',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get products by category
  List<ProductModel> getProductsByCategory(String category) {
    if (category == 'All') {
      return _products;
    }
    return _products.where((product) => product.category == category).toList();
  }

  // Get product by ID
  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search products
  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    return _products.where((product) =>
      product.name.toLowerCase().contains(query.toLowerCase()) ||
      product.description.toLowerCase().contains(query.toLowerCase()) ||
      product.category.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Clear products
  void clearProducts() {
    _products = [];
    notifyListeners();
  }

  // Add product (for future use)
  void addProduct(ProductModel product) {
    _products.add(product);
    notifyListeners();
  }

  // Update product (for future use)
  void updateProduct(ProductModel updatedProduct) {
    final index = _products.indexWhere((product) => product.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  // Remove product (for future use)
  void removeProduct(String productId) {
    _products.removeWhere((product) => product.id == productId);
    notifyListeners();
  }
}