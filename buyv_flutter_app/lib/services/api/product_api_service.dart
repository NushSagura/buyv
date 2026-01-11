import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';
import '../auth_api_service.dart';
import '../security/secure_token_manager.dart';

class ProductApiService {
  static Uri _url(String path) =>
      Uri.parse('${AppConstants.fastApiBaseUrl}$path');

  static Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // Get all products with filters
  static Future<List<dynamic>> getProducts({
    String? category,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();

    final uri = _url('/products').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['products'] ?? data;
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Get product by ID
  static Future<Map<String, dynamic>> getProductById(String productId) async {
    final response = await http.get(
      _url('/products/$productId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Product not found');
    }
  }

  // Search products
  static Future<List<dynamic>> searchProducts(String query) async {
    final response = await http.get(
      _url('/products/search?q=$query'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      return [];
    }
  }

  // Get user's favorite products
  static Future<List<dynamic>> getFavorites(String userId) async {
    final token = await SecureTokenManager.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      _url('/users/$userId/favorites'),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      return [];
    }
  }

  // Add product to favorites
  static Future<void> addToFavorites(String userId, String productId) async {
    final token = await SecureTokenManager.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      _url('/users/$userId/favorites/$productId'),
      headers: _headers(token: token),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add to favorites');
    }
  }

  // Remove product from favorites
  static Future<void> removeFromFavorites(String userId, String productId) async {
    final token = await SecureTokenManager.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      _url('/users/$userId/favorites/$productId'),
      headers: _headers(token: token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove from favorites');
    }
  }

  // Check if product is in favorites
  static Future<bool> isFavorite(String userId, String productId) async {
    try {
      final token = await SecureTokenManager.getAccessToken();
      if (token == null) return false;

      final response = await http.get(
        _url('/users/$userId/favorites/$productId'),
        headers: _headers(token: token),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get recently viewed products
  static Future<List<dynamic>> getRecentlyViewedProducts(String userId) async {
    final token = await SecureTokenManager.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      _url('/users/$userId/recently-viewed'),
      headers: _headers(token: token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      return [];
    }
  }

  // Add product to recently viewed
  static Future<void> addToRecentlyViewed(String userId, String productId) async {
    final token = await SecureTokenManager.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      _url('/users/$userId/recently-viewed/$productId'),
      headers: _headers(token: token),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add to recently viewed');
    }
  }

  // Get product reviews
  static Future<List<dynamic>> getProductReviews(String productId) async {
    final response = await http.get(
      _url('/products/$productId/reviews'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      return [];
    }
  }

  // Add product review
  static Future<Map<String, dynamic>> addProductReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    final token = await SecureTokenManager.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      _url('/products/$productId/reviews'),
      headers: _headers(token: token),
      body: json.encode({
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add review');
    }
  }

  // Create product (for sellers)
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    List<String>? imageUrls,
    String? videoUrl,
    int? stockQuantity,
    Map<String, dynamic>? specifications,
    List<String>? tags,
  }) async {
    final token = await SecureTokenManager.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      _url('/products'),
      headers: _headers(token: token),
      body: json.encode({
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrls': imageUrls ?? [],
        'videoUrl': videoUrl,
        'stockQuantity': stockQuantity ?? 0,
        'specifications': specifications,
        'tags': tags,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create product');
    }
  }

  // Update product (for sellers)
  static Future<Map<String, dynamic>> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    String? category,
    List<String>? imageUrls,
    String? videoUrl,
    int? stockQuantity,
    bool? isAvailable,
    Map<String, dynamic>? specifications,
    List<String>? tags,
  }) async {
    final token = await SecureTokenManager.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (category != null) updates['category'] = category;
    if (imageUrls != null) updates['imageUrls'] = imageUrls;
    if (videoUrl != null) updates['videoUrl'] = videoUrl;
    if (stockQuantity != null) updates['stockQuantity'] = stockQuantity;
    if (isAvailable != null) updates['isAvailable'] = isAvailable;
    if (specifications != null) updates['specifications'] = specifications;
    if (tags != null) updates['tags'] = tags;

    final response = await http.put(
      _url('/products/$productId'),
      headers: _headers(token: token),
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update product');
    }
  }

  // Delete product (for sellers)
  static Future<bool> deleteProduct(String productId) async {
    final token = await SecureTokenManager.getAccessToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      _url('/products/$productId'),
      headers: _headers(token: token),
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }
}
