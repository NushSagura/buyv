import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../domain/models/cj_product_model.dart';
import 'security/cj_token_manager.dart';
import 'security/api_security_service.dart';

// Custom exception classes for better error handling
class CJAPIException implements Exception {
  final String message;
  final int? errorCode;
  final String? endpoint;

  CJAPIException(this.message, {this.errorCode, this.endpoint});

  @override
  String toString() =>
      'CJAPIException: $message (Code: $errorCode, Endpoint: $endpoint)';
}

class CJRateLimitException extends CJAPIException {
  CJRateLimitException()
    : super('Rate limit exceeded. Please try again later.', errorCode: 429);
}

class CJAuthenticationException extends CJAPIException {
  CJAuthenticationException(String message) : super(message, errorCode: 401);
}

class CJDropshippingService {
  static String get baseUrl => AppConstants.cjBaseUrl;

  // استخدام API key من الثوابت
  static String get apiKey => AppConstants.cjApiKey;
  static String get email => AppConstants.cjEmail;
  static String get account => AppConstants.cjAccount;

  // Enhanced rate limiting and retry logic
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(
    milliseconds: 1200,
  ); // Increased to 1.2 seconds
  static const int _maxRetries = 5; // Increased max retries
  static const Duration _baseBackoffDelay = Duration(seconds: 2);

  // Request statistics for monitoring
  static int _totalRequests = 0;
  static int _failedRequests = 0;
  static int _dailyRequestCount = 0;
  static const int _maxDailyRequests = 950; // Leave buffer for CJ's 1000 limit
  static DateTime? _dailyResetTime;

  // Token management with secure storage
  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenExpiry;

  // Secure HTTP client
  static late final Dio _secureClient;

  // Initialize secure client
  static void _initializeSecureClient() {
    _secureClient = APISecurityService.createSecureClient();
  }

  /// Enhanced authentication with secure token storage
  static Future<bool> authenticate() async {
    try {
      _initializeSecureClient();

      // Check if we have valid stored CJ tokens
      if (await CJTokenManager.isAccessTokenValid()) {
        _accessToken = await CJTokenManager.getAccessToken();
        return true;
      }

      await CJDropshippingService._enforceRateLimit();
      _totalRequests++;

      final String identifier = (email.isNotEmpty) ? email : account;
      final Map<String, dynamic> requestBody = identifier.contains('@')
          ? {'email': identifier, 'apiKey': apiKey}
          : {'account': identifier, 'apiKey': apiKey};

      // Use secure headers
      final headers = await APISecurityService.getSecureHeaders(
        body: jsonEncode(requestBody),
        method: 'POST',
        path: '/authentication/getAccessToken',
      );

      print('🔐 CJ Authentication attempt with proxy URL: $baseUrl');

      final response = await http.post(
        Uri.parse('$baseUrl/authentication/getAccessToken'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final responseData = _handleResponse(
        response,
        '/authentication/getAccessToken',
      );

      if (responseData['result'] == true && responseData['data'] != null) {
        final data = responseData['data'];
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];

        // Calculate token expiry (CJ tokens typically last 15 days)
        _tokenExpiry = DateTime.now().add(Duration(days: 15));

        // Store tokens securely
        await CJTokenManager.storeAccessToken(
          token: _accessToken!,
          refreshToken: _refreshToken!,
          expiryTime: _tokenExpiry!,
        );

        if (kDebugMode) {
          print('🔐 CJ Authentication successful - Token stored securely');
        }
        return true;
      } else {
        throw CJAuthenticationException(
          'Authentication failed: ${responseData['message']}',
        );
      }
    } catch (e) {
      _failedRequests++;
      if (kDebugMode) {
        print('❌ CJ Authentication error: $e');
      }

      if (e is CJAPIException) {
        rethrow;
      }
      throw CJAuthenticationException('Authentication network error: $e');
    }
  }

  /// Enhanced token validation with secure storage
  static Future<bool> _ensureValidToken() async {
    try {
      // Check stored token first
      if (await CJTokenManager.isAccessTokenValid()) {
        _accessToken = await CJTokenManager.getAccessToken();
        return true;
      }

      // Try to refresh token
      final refreshToken = await CJTokenManager.getRefreshToken();
      if (refreshToken != null) {
        if (await refreshAccessToken()) {
          return true;
        }
      }

      // Fall back to re-authentication
      return await authenticate();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token validation failed: $e');
      }
      return false;
    }
  }

  /// Enhanced refresh token with secure storage
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await CJTokenManager.getRefreshToken();
      if (refreshToken == null) {
        return await authenticate();
      }

      await CJDropshippingService._enforceRateLimit();
      _totalRequests++;

      final requestBody = {'refreshToken': refreshToken};

      final headers = await APISecurityService.getSecureHeaders(
        body: jsonEncode(requestBody),
        method: 'POST',
        path: '/authentication/refreshAccessToken',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/authentication/refreshAccessToken'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final responseData = _handleResponse(
        response,
        '/authentication/refreshAccessToken',
      );

      if (responseData['result'] == true && responseData['data'] != null) {
        final data = responseData['data'];
        _accessToken = data['accessToken'];

        // Update token expiry
        _tokenExpiry = DateTime.now().add(Duration(days: 15));

        // Update stored token
        await CJTokenManager.updateAccessToken(
          newToken: _accessToken!,
          newExpiryTime: _tokenExpiry!,
        );

        if (kDebugMode) {
          print('🔄 CJ Token refreshed successfully');
        }
        return true;
      } else {
        // Refresh failed, try re-authentication
        await CJTokenManager.clear();
        return await authenticate();
      }
    } catch (e) {
      _failedRequests++;
      if (kDebugMode) {
        print('❌ Token refresh failed: $e');
      }

      // Clear invalid tokens and re-authenticate
      await CJTokenManager.clear();
      return await authenticate();
    }
  }

  /// Enhanced rate limiting helper with daily quota tracking
  static Future<void> _enforceRateLimit() async {
    // Reset daily counter if needed
    if (_dailyResetTime == null || DateTime.now().isAfter(_dailyResetTime!)) {
      _dailyRequestCount = 0;
      _dailyResetTime = DateTime.now().add(const Duration(days: 1));
    }

    // Check daily quota (CJ allows 1000 requests per day)
    if (_dailyRequestCount >= _maxDailyRequests) {
      throw CJRateLimitException();
    }

    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        if (kDebugMode) {
          print('Rate limiting: Waiting ${waitTime.inMilliseconds}ms');
        }
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
    _dailyRequestCount++;
  }

  /// Enhanced retry logic with exponential backoff and jitter
  static Future<T?> _retryRequest<T>(
    Future<T?> Function() request, {
    int maxRetries = _maxRetries,
    String? endpoint,
  }) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await CJDropshippingService._enforceRateLimit();
        final result = await request();

        // Reset failed counter on success
        if (_failedRequests > 0) {
          _failedRequests = 0;
        }

        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        _failedRequests++;

        if (kDebugMode) {
          print(
            'CJ API Request attempt $attempt/$maxRetries failed for $endpoint: $e',
          );
        }

        // Don't retry on authentication errors or rate limits
        if (e is CJAuthenticationException || e is CJRateLimitException) {
          throw e;
        }

        if (attempt == maxRetries) {
          throw CJAPIException(
            'Max retries exceeded for $endpoint',
            endpoint: endpoint,
          );
        }

        // Enhanced exponential backoff with jitter
        final backoffDelay = Duration(
          milliseconds:
              (_baseBackoffDelay.inMilliseconds * (1 << (attempt - 1))) +
              (DateTime.now().millisecondsSinceEpoch % 1000), // Add jitter
        );

        if (kDebugMode) {
          print('Retrying in ${backoffDelay.inSeconds} seconds...');
        }

        await Future.delayed(backoffDelay);
      }
    }

    throw lastException ??
        CJAPIException('Unknown error occurred', endpoint: endpoint);
  }

  /// Enhanced HTTP response handler
  static Map<String, dynamic> _handleResponse(
    http.Response response,
    String endpoint,
  ) {
    if (response.statusCode == 429) {
      throw CJRateLimitException();
    }

    if (response.statusCode != 200) {
      throw CJAPIException(
        'HTTP ${response.statusCode}: ${response.body}',
        errorCode: response.statusCode,
        endpoint: endpoint,
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Handle CJ API specific error codes
      if (data['result'] != true) {
        final errorCode = data['code'] as int?;
        final errorMessage = data['message'] as String? ?? 'Unknown API error';

        // Map specific error codes to exceptions
        switch (errorCode) {
          case 1600002:
            throw CJAuthenticationException('Access token is empty or invalid');
          case 1600003:
            throw CJAuthenticationException('Access token has expired');
          case 1600004:
            throw CJAuthenticationException('Invalid API credentials');
          case 1600005:
            throw CJRateLimitException();
          default:
            throw CJAPIException(
              errorMessage,
              errorCode: errorCode,
              endpoint: endpoint,
            );
        }
      }

      return data;
    } catch (e) {
      if (e is CJAPIException) rethrow;
      throw CJAPIException('Failed to parse response: $e', endpoint: endpoint);
    }
  }

  /// Enhanced product retrieval with secure authentication using GET method
  static Future<List<CJProduct>> getProducts({
    String? keyword,
    String? categoryId,
    String? productSku,
    String? productName,
    String? countryCode,
    int? deliveryTime,
    double? minPrice,
    double? maxPrice,
    String? sort, // 'price_asc', 'price_desc', 'sales_desc', 'newest'
    bool? verifiedWarehouse,
    bool? hasInventory,
    int pageNum = 1,
    int pageSize = 20,
  }) async {
    return await _retryRequest<List<CJProduct>>(() async {
          if (!await CJDropshippingService._ensureValidToken()) {
            throw CJAuthenticationException('Failed to obtain valid token');
          }

          // Build query parameters for GET request
          final queryParams = <String, String>{
            'pageNum': pageNum.toString(),
            'pageSize': pageSize.toString(),
          };

          // Add search parameters
          if (keyword != null && keyword.isNotEmpty) {
            queryParams['productName'] =
                keyword; // Use productName for keyword search
          }
          if (categoryId != null && categoryId.isNotEmpty) {
            queryParams['categoryId'] = categoryId;
          }
          if (productSku != null && productSku.isNotEmpty) {
            queryParams['productSku'] = productSku;
          }
          if (productName != null && productName.isNotEmpty) {
            queryParams['productNameEn'] = productName;
          }

          // Add filtering parameters
          if (countryCode != null && countryCode.isNotEmpty) {
            queryParams['countryCode'] = countryCode;
          }
          if (deliveryTime != null) {
            queryParams['deliveryTime'] = deliveryTime.toString();
          }
          if (minPrice != null) {
            queryParams['minPrice'] = minPrice.toString();
          }
          if (maxPrice != null) {
            queryParams['maxPrice'] = maxPrice.toString();
          }
          if (sort != null && sort.isNotEmpty) {
            queryParams['sort'] = sort;
          }
          if (verifiedWarehouse != null) {
            queryParams['verifiedWarehouse'] = verifiedWarehouse ? '1' : '0';
          }

          // Build URI with query parameters
          final uri = Uri.parse(
            '${CJDropshippingService.baseUrl}/product/list',
          ).replace(queryParameters: queryParams);

          final headers = await APISecurityService.getSecureHeaders(
            method: 'GET',
            path: '/product/list',
          );
          headers['CJ-Access-Token'] = CJDropshippingService._accessToken!;

          final response = await http.get(uri, headers: headers);

          final responseData = _handleResponse(response, '/product/list');

          if (responseData['data'] != null) {
            final productData = responseData['data'];
            if (productData is Map && productData['list'] != null) {
              final List<dynamic> productList = productData['list'];

              if (kDebugMode) {
                print(
                  '🛍️ CJ Products retrieved successfully: ${productList.length} products',
                );
                if (productData['total'] != null) {
                  print('Total products available: ${productData['total']}');
                }
              }

              return productList
                  .map((json) => CJProduct.fromJson(json))
                  .toList();
            } else if (productData is List) {
              if (kDebugMode) {
                print(
                  '🛍️ CJ Products retrieved successfully: ${productData.length} products',
                );
              }
              return productData
                  .map((json) => CJProduct.fromJson(json))
                  .toList();
            }
          }

          return <CJProduct>[];
        }, endpoint: '/product/list') ??
        <CJProduct>[];
  }

  /// Get CJ Dropshipping settings
  static Future<CJSettings?> getSettings() async {
    if (!await CJDropshippingService._ensureValidToken()) return null;

    try {
      final response = await http.post(
        Uri.parse('${CJDropshippingService.baseUrl}/logistic/getAccountInfo'),
        headers: {
          'Content-Type': 'application/json',
          'CJ-Access-Token': CJDropshippingService._accessToken!,
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == true && data['data'] != null) {
          return CJSettings.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('CJ Get settings error: $e');
      }
      return null;
    }
  }

  /// Get API usage statistics
  static Map<String, dynamic> getApiStats() {
    return {
      'totalRequests': _totalRequests,
      'failedRequests': _failedRequests,
      'dailyRequestCount': _dailyRequestCount,
      'maxDailyRequests': _maxDailyRequests,
      'successRate': _totalRequests > 0
          ? ((_totalRequests - _failedRequests) / _totalRequests * 100)
                    .toStringAsFixed(2) +
                '%'
          : '0%',
      'dailyResetTime': _dailyResetTime?.toIso8601String(),
      'lastRequestTime': _lastRequestTime?.toIso8601String(),
    };
  }

  /// Clear all stored tokens and reset authentication
  static Future<void> clearAuthentication() async {
    await CJTokenManager.clear();
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;

    if (kDebugMode) {
      print('🔐 CJ Authentication cleared');
    }
  }

  // Get product details by ID
  Future<CJProduct?> getProductDetails(String productId) async {
    if (!await CJDropshippingService._ensureValidToken()) return null;

    try {
      final requestBody = {'pid': productId};

      final response = await http.post(
        Uri.parse('${CJDropshippingService.baseUrl}/product/query'),
        headers: {
          'Content-Type': 'application/json',
          'CJ-Access-Token': CJDropshippingService._accessToken!,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == true) {
          return CJProduct.fromJson(data['data']);
        }
      }
      if (kDebugMode) {
        print('CJ Get product details failed: ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('CJ Get product details error: $e');
      }
      return null;
    }
  }

  // Create product sourcing request
  Future<Map<String, dynamic>?> createSourcingRequest({
    required String productName,
    required String productUrl,
    required String targetPrice,
    required int quantity,
    String? productImage,
    String? productDescription,
    String? remark,
  }) async {
    if (!await CJDropshippingService._ensureValidToken()) return null;

    try {
      await CJDropshippingService._enforceRateLimit();

      final requestBody = <String, dynamic>{
        'productName': productName,
        'productUrl': productUrl,
        'targetPrice': targetPrice,
        'quantity': quantity,
      };

      if (productImage != null && productImage.isNotEmpty) {
        requestBody['productImage'] = productImage;
      }
      if (productDescription != null && productDescription.isNotEmpty) {
        requestBody['productDescription'] = productDescription;
      }
      if (remark != null && remark.isNotEmpty) {
        requestBody['remark'] = remark;
      }

      final response = await http.post(
        Uri.parse('${CJDropshippingService.baseUrl}/sourcing/post'),
        headers: {
          'Content-Type': 'application/json',
          'CJ-Access-Token': CJDropshippingService._accessToken!,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result'] == true && data['data'] != null) {
          if (kDebugMode) {
            print('CJ Sourcing request created successfully');
          }
          return data['data'];
        } else {
          // Handle API error response
          final errorCode = data['code'];
          final errorMessage = data['message'] ?? 'Unknown error';

          if (kDebugMode) {
            print(
              'CJ Sourcing API Error - Code: $errorCode, Message: $errorMessage',
            );
          }

          // Handle specific errors
          if (errorCode == 1600002) {
            // Access token cannot be empty
            if (await CJDropshippingService.authenticate()) {
              return await createSourcingRequest(
                productName: productName,
                productUrl: productUrl,
                targetPrice: targetPrice,
                quantity: quantity,
                productImage: productImage,
                productDescription: productDescription,
                remark: remark,
              );
            }
          } else if (errorCode == 1600003) {
            // Token expired, try to refresh
            if (await CJDropshippingService.refreshAccessToken()) {
              return await createSourcingRequest(
                productName: productName,
                productUrl: productUrl,
                targetPrice: targetPrice,
                quantity: quantity,
                productImage: productImage,
                productDescription: productDescription,
                remark: remark,
              );
            }
          }
        }
      } else {
        if (kDebugMode) {
          print(
            'CJ Create sourcing request HTTP error: ${response.statusCode} - ${response.body}',
          );
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('CJ Create sourcing request error: $e');
      }
      return null;
    }
  }

  // Query sourcing requests
  Future<List<Map<String, dynamic>>> getSourcingRequests({
    int current = 1,
    int pageSize = 20,
    String? status, // 'pending', 'processing', 'completed', 'cancelled'
  }) async {
    if (!await CJDropshippingService._ensureValidToken()) return [];

    try {
      await CJDropshippingService._enforceRateLimit();

      final requestBody = <String, dynamic>{
        'current': current,
        'pageSize': pageSize,
      };

      if (status != null && status.isNotEmpty) {
        requestBody['status'] = status;
      }

      final response = await http.post(
        Uri.parse('${CJDropshippingService.baseUrl}/sourcing/query'),
        headers: {
          'Content-Type': 'application/json',
          'CJ-Access-Token': CJDropshippingService._accessToken!,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result'] == true && data['data'] != null) {
          final sourcingData = data['data'];
          if (sourcingData is Map && sourcingData['list'] != null) {
            final List<dynamic> sourcingList = sourcingData['list'];

            if (kDebugMode) {
              print(
                'CJ Sourcing requests retrieved successfully: ${sourcingList.length} requests',
              );
              if (sourcingData['total'] != null) {
                print('Total sourcing requests: ${sourcingData['total']}');
              }
            }

            return sourcingList.cast<Map<String, dynamic>>();
          } else if (sourcingData is List) {
            if (kDebugMode) {
              print(
                'CJ Sourcing requests retrieved successfully: ${sourcingData.length} requests',
              );
            }
            return sourcingData.cast<Map<String, dynamic>>();
          }
        } else {
          // Handle API error response
          final errorCode = data['code'];
          final errorMessage = data['message'] ?? 'Unknown error';

          if (kDebugMode) {
            print(
              'CJ Sourcing Query API Error - Code: $errorCode, Message: $errorMessage',
            );
          }

          // Handle specific errors
          if (errorCode == 1600002) {
            // Access token cannot be empty
            if (await CJDropshippingService.authenticate()) {
              return await getSourcingRequests(
                current: current,
                pageSize: pageSize,
                status: status,
              );
            }
          } else if (errorCode == 1600003) {
            // Token expired, try to refresh
            if (await CJDropshippingService.refreshAccessToken()) {
              return await getSourcingRequests(
                current: current,
                pageSize: pageSize,
                status: status,
              );
            }
          }
        }
      } else {
        if (kDebugMode) {
          print(
            'CJ Get sourcing requests HTTP error: ${response.statusCode} - ${response.body}',
          );
        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('CJ Get sourcing requests error: $e');
      }
      return [];
    }
  }

  // Get product categories
  static Future<List<CJCategory>> getCategories() async {
    if (!await CJDropshippingService._ensureValidToken()) return [];

    try {
      final response = await http.post(
        Uri.parse('${CJDropshippingService.baseUrl}/product/getCategory'),
        headers: {
          'Content-Type': 'application/json',
          'CJ-Access-Token': CJDropshippingService._accessToken!,
        },
        body: jsonEncode({}), // Empty body for categories request
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // تحسين معالجة الأخطاء والاستجابة
        if (data['result'] == true && data['data'] != null) {
          final categoryData = data['data'];
          List<dynamic> categoryList;

          if (categoryData is List) {
            categoryList = categoryData;
          } else if (categoryData is Map && categoryData['list'] != null) {
            categoryList = categoryData['list'];
          } else {
            if (kDebugMode) {
              print('CJ Categories: Unexpected data format');
            }
            return [];
          }

          return categoryList.map((json) => CJCategory.fromJson(json)).toList();
        } else {
          // Handle API error response
          final errorCode = data['code'];
          final errorMessage = data['message'] ?? 'Unknown error';

          if (kDebugMode) {
            print(
              'CJ Categories API Error - Code: $errorCode, Message: $errorMessage',
            );
          }

          // Handle specific errors
          if (errorCode == 1600003) {
            // Token expired, try to refresh
            if (await CJDropshippingService.refreshAccessToken()) {
              return await getCategories();
            }
          }
        }
      }

      if (kDebugMode) {
        print('CJ Get categories failed: ${response.body}');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('CJ Get categories error: $e');
      }
      return [];
    }
  }

  // Create order (for commission tracking)
  Future<Map<String, dynamic>?> createOrder({
    required String productId,
    required String variantId,
    required int quantity,
    required Map<String, dynamic> shippingAddress,
    String? promoterId, // ID of the user who promoted this product
  }) async {
    if (!await CJDropshippingService._ensureValidToken()) return null;

    try {
      final orderData = {
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
        'shippingAddress': shippingAddress,
        'promoterId': promoterId, // For commission tracking
      };

      final response = await http.post(
        Uri.parse(
          '${CJDropshippingService.baseUrl}/shopping/order/createOrder',
        ),
        headers: {
          'Content-Type': 'application/json',
          'CJ-Access-Token': CJDropshippingService._accessToken!,
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == true) {
          return data['data'];
        }
      }
      if (kDebugMode) {
        print('CJ Create order failed: ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('CJ Create order error: $e');
      }
      return null;
    }
  }

  // Get order status
  Future<Map<String, dynamic>?> getOrderStatus(String orderId) async {
    if (!await CJDropshippingService._ensureValidToken()) return null;

    try {
      final requestBody = <String, dynamic>{'orderId': orderId};

      final response = await http.post(
        Uri.parse(
          '${CJDropshippingService.baseUrl}/shopping/order/getOrderDetail',
        ),
        headers: {
          'Content-Type': 'application/json',
          'CJ-Access-Token': CJDropshippingService._accessToken!,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == true) {
          return data['data'];
        }
      }
      if (kDebugMode) {
        print('CJ Get order status failed: ${response.body}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('CJ Get order status error: $e');
      }
      return null;
    }
  }

  // Calculate commission (1% of product price)
  double calculateCommission(double productPrice) {
    return productPrice * 0.01; // 1% commission
  }

  // Get trending products (for promotion suggestions)
  Future<List<CJProduct>> getTrendingProducts({int limit = 10}) async {
    if (!await CJDropshippingService._ensureValidToken()) return [];

    try {
      final requestBody = <String, dynamic>{
        'current': 1,
        'pageSize': limit,
        'sort': 'sellCount', // Sort by sales count
      };

      final response = await http.post(
        Uri.parse('${CJDropshippingService.baseUrl}/product/list'),
        headers: {
          'Content-Type': 'application/json',
          'CJ-Access-Token': CJDropshippingService._accessToken!,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == true && data['data']['list'] != null) {
          final List<dynamic> productList = data['data']['list'];
          return productList.map((json) => CJProduct.fromJson(json)).toList();
        }
      }
      if (kDebugMode) {
        print('CJ Get trending products failed: ${response.body}');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('CJ Get trending products error: $e');
      }
      return [];
    }
  }

  // Search products by category
  static Future<List<CJProduct>> getProductsByCategory(
    String categoryId, {
    int pageNum = 1,
    int pageSize = 20,
  }) async {
    return await CJDropshippingService.getProducts(
      categoryId: categoryId,
      pageNum: pageNum,
      pageSize: pageSize,
    );
  }

  // Logout and invalidate tokens
  Future<bool> logout() async {
    if (CJDropshippingService._accessToken == null) return true;

    try {
      final response = await http.post(
        Uri.parse('${CJDropshippingService.baseUrl}/authentication/logout'),
        headers: {
          'Content-Type': 'application/json',
          'CJ-Access-Token': CJDropshippingService._accessToken!,
        },
      );

      // Clear tokens regardless of response
      CJDropshippingService._accessToken = null;
      CJDropshippingService._refreshToken = null;
      CJDropshippingService._tokenExpiry = null;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] == true;
      }
      return true; // Consider it successful if tokens are cleared
    } catch (e) {
      if (kDebugMode) {
        print('CJ Logout error: $e');
      }
      // Clear tokens even if logout request fails
      CJDropshippingService._accessToken = null;
      CJDropshippingService._refreshToken = null;
      CJDropshippingService._tokenExpiry = null;
      return true;
    }
  }

  // Get product categories
  Future<List<CJCategory>> getCategoryList() async {
    if (!await CJDropshippingService._ensureValidToken()) return [];

    try {
      await CJDropshippingService._enforceRateLimit();

      final response = await http.get(
        Uri.parse('${CJDropshippingService.baseUrl}/product/getCategory'),
        headers: {
          'Content-Type': 'application/json',
          'CJ-Access-Token': CJDropshippingService._accessToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result'] == true && data['data'] != null) {
          final List<CJCategory> categories = [];
          final categoryData = data['data'];

          // Parse first level categories
          if (categoryData['categoryFirstList'] != null) {
            final List<dynamic> firstLevelList =
                categoryData['categoryFirstList'];
            for (var firstLevel in firstLevelList) {
              categories.add(
                CJCategory(
                  categoryId: firstLevel['categoryId'] ?? '',
                  categoryName: firstLevel['categoryName'] ?? '',
                  categoryNameEn:
                      firstLevel['categoryNameEn'] ??
                      firstLevel['categoryName'] ??
                      '',
                  parentId: '',
                  level: 1,
                  image: firstLevel['image'] ?? '',
                  productCount: firstLevel['productCount'] ?? 0,
                ),
              );

              // Parse second level categories
              if (firstLevel['categorySecondList'] != null) {
                final List<dynamic> secondLevelList =
                    firstLevel['categorySecondList'];
                for (var secondLevel in secondLevelList) {
                  categories.add(
                    CJCategory(
                      categoryId: secondLevel['categoryId'] ?? '',
                      categoryName: secondLevel['categoryName'] ?? '',
                      categoryNameEn:
                          secondLevel['categoryNameEn'] ??
                          secondLevel['categoryName'] ??
                          '',
                      parentId: firstLevel['categoryId'] ?? '',
                      level: 2,
                      image: secondLevel['image'] ?? '',
                      productCount: secondLevel['productCount'] ?? 0,
                    ),
                  );

                  // Parse third level categories
                  if (secondLevel['categoryThirdList'] != null) {
                    final List<dynamic> thirdLevelList =
                        secondLevel['categoryThirdList'];
                    for (var thirdLevel in thirdLevelList) {
                      categories.add(
                        CJCategory(
                          categoryId: thirdLevel['categoryId'] ?? '',
                          categoryName: thirdLevel['categoryName'] ?? '',
                          categoryNameEn:
                              thirdLevel['categoryNameEn'] ??
                              thirdLevel['categoryName'] ??
                              '',
                          parentId: secondLevel['categoryId'] ?? '',
                          level: 3,
                          image: thirdLevel['image'] ?? '',
                          productCount: thirdLevel['productCount'] ?? 0,
                        ),
                      );
                    }
                  }
                }
              }
            }
          }

          if (kDebugMode) {
            print(
              'CJ Categories retrieved successfully: ${categories.length} categories',
            );
          }

          return categories;
        } else {
          // Handle API error response
          final errorCode = data['code'];
          final errorMessage = data['message'] ?? 'Unknown error';

          if (kDebugMode) {
            print(
              'CJ Categories API Error - Code: $errorCode, Message: $errorMessage',
            );
          }

          // Handle specific errors
          if (errorCode == 1600002) {
            // Access token cannot be empty
            if (await CJDropshippingService.authenticate()) {
              return await getCategoryList(); // Retry once after re-authentication
            }
          } else if (errorCode == 1600003) {
            // Token expired, try to refresh
            if (await CJDropshippingService.refreshAccessToken()) {
              return await getCategoryList();
            }
          }
        }
      } else {
        if (kDebugMode) {
          print(
            'CJ Get categories HTTP error: ${response.statusCode} - ${response.body}',
          );
        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('CJ Get categories error: $e');
      }
      return [];
    }
  }
}
