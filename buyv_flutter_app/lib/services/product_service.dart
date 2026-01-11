import 'package:flutter/foundation.dart';
import '../domain/models/product_model.dart';
import 'auth_api_service.dart';
import 'api/product_api_service.dart';

class ProductService {
  // Get user ID from current session
  Future<String?> get currentUserId async {
    try {
      final me = await AuthApiService.me();
      return me['id'] as String?;
    } catch (e) {
      debugPrint('ProductService.currentUserId error: $e');
      return null;
    }
  }

  // Get user's favorite products
  Future<List<ProductModel>> getFavorites(String userId) async {
    try {
      final favorites = await ProductApiService.getFavorites(userId);
      
      return favorites.map((json) {
        return ProductModel.fromJson(json as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('ProductService.getFavorites error: $e');
      return [];
    }
  }

  // Add product to favorites
  Future<bool> addToFavorites(String userId, String productId) async {
    try {
      await ProductApiService.addToFavorites(userId, productId);
      return true;
    } catch (e) {
      debugPrint('ProductService.addToFavorites error: $e');
      return false;
    }
  }

  // Remove product from favorites
  Future<bool> removeFromFavorites(String userId, String productId) async {
    try {
      await ProductApiService.removeFromFavorites(userId, productId);
      return true;
    } catch (e) {
      debugPrint('ProductService.removeFromFavorites error: $e');
      return false;
    }
  }

  // Check if product is in favorites
  Future<bool> isFavorite(String userId, String productId) async {
    try {
      return await ProductApiService.isFavorite(userId, productId);
    } catch (e) {
      debugPrint('ProductService.isFavorite error: $e');
      return false;
    }
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final json = await ProductApiService.getProductById(productId);
      return ProductModel.fromJson(json);
    } catch (e) {
      debugPrint('ProductService.getProductById error: $e');
      return null;
    }
  }

  // Get all products with filters
  Future<List<ProductModel>> getProducts({
    String? category,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final products = await ProductApiService.getProducts(
        category: category,
        sortBy: sortBy,
        minPrice: minPrice,
        maxPrice: maxPrice,
        page: page,
        limit: limit,
      );
      
      return products.map((json) {
        return ProductModel.fromJson(json as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('ProductService.getProducts error: $e');
      return [];
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final products = await ProductApiService.searchProducts(query);
      
      return products.map((json) {
        return ProductModel.fromJson(json as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('ProductService.searchProducts error: $e');
      return [];
    }
  }

  // Get recently viewed products
  Future<List<ProductModel>> getRecentlyViewedProducts() async {
    try {
      final userId = await currentUserId;
      if (userId == null) return [];
      
      final products = await ProductApiService.getRecentlyViewedProducts(userId);
      
      return products.map((json) {
        return ProductModel.fromJson(json as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('ProductService.getRecentlyViewedProducts error: $e');
      return [];
    }
  }

  // Add product to recently viewed
  Future<bool> addToRecentlyViewed(String productId) async {
    try {
      final userId = await currentUserId;
      if (userId == null) return false;
      
      await ProductApiService.addToRecentlyViewed(userId, productId);
      return true;
    } catch (e) {
      debugPrint('ProductService.addToRecentlyViewed error: $e');
      return false;
    }
  }
}
