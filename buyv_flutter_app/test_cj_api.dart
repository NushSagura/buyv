import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

void main() async {
  print('Testing CJ Dropshipping API Authentication...');
  
  try {
    await testCJAuthentication();
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> testCJAuthentication() async {
  // Test authentication
  print('--- Testing Authentication ---');
  final authResponse = await http.post(
    Uri.parse('https://developers.cjdropshipping.com/api2.0/v1/authentication/getAccessToken'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': 'kerzazicherif@gmail.com',
      'apiKey': '5e861f297d2c4cbab6c41034f0f3f2f9',
    }),
  );

  print('Authentication Status Code: ${authResponse.statusCode}');
  print('Authentication Response: ${authResponse.body}');

  if (authResponse.statusCode == 200) {
    final authData = jsonDecode(authResponse.body);
    
    if (authData['result'] == true && authData['data'] != null) {
      final accessToken = authData['data']['accessToken'];
      final refreshToken = authData['data']['refreshToken'];
      
      print('✅ Authentication successful!');
      print('Access Token: ${accessToken.substring(0, 20)}...');
      print('Refresh Token: ${refreshToken.substring(0, 20)}...');
      
      // Test API call with token using GET method (correct method)
      await testApiCallWithToken(accessToken);
    } else {
      print('❌ Authentication failed: ${authData['message']}');
      print('Error code: ${authData['code']}');
    }
  } else {
    print('❌ Authentication request failed with status: ${authResponse.statusCode}');
    print('Response body: ${authResponse.body}');
  }
}

Future<void> testApiCallWithToken(String accessToken) async {
  // Test API call with token using GET method (as per CJ documentation)
  print('\n--- Testing Product List API (GET method) ---');
  final productResponse = await http.get(
    Uri.parse('https://developers.cjdropshipping.com/api2.0/v1/product/list?pageNum=1&pageSize=5'),
    headers: {
      'Content-Type': 'application/json',
      'CJ-Access-Token': accessToken,
    },
  );

  print('Product List Status Code: ${productResponse.statusCode}');
  print('Product List Response: ${productResponse.body}');

  if (productResponse.statusCode == 200) {
    final productData = jsonDecode(productResponse.body);
    
    if (productData['result'] == true) {
      print('✅ Product list API call successful!');
      print('Total products: ${productData['data']['total']}');
      print('Products in this page: ${productData['data']['list']?.length ?? 0}');
      
      // Show first product details if available
      if (productData['data']['list'] != null && productData['data']['list'].isNotEmpty) {
        final firstProduct = productData['data']['list'][0];
        print('First product: ${firstProduct['productName']} (ID: ${firstProduct['pid']})');
      }
    } else {
      print('❌ Product list API call failed: ${productData['message']}');
      print('Error code: ${productData['code']}');
    }
  } else {
    print('❌ Product list request failed with status: ${productResponse.statusCode}');
    print('Response body: ${productResponse.body}');
  }
  
  // Test category list API as well
  print('\n--- Testing Category List API ---');
  final categoryResponse = await http.get(
    Uri.parse('https://developers.cjdropshipping.com/api2.0/v1/product/getCategory'),
    headers: {
      'Content-Type': 'application/json',
      'CJ-Access-Token': accessToken,
    },
  );

  print('Category List Status Code: ${categoryResponse.statusCode}');
  
  if (categoryResponse.statusCode == 200) {
    final categoryData = jsonDecode(categoryResponse.body);
    
    if (categoryData['result'] == true) {
      print('✅ Category list API call successful!');
      print('Categories available: ${categoryData['data']?.length ?? 0}');
      
      // Show first few categories
      if (categoryData['data'] != null && categoryData['data'].isNotEmpty) {
        print('Sample categories:');
        for (int i = 0; i < (categoryData['data'].length > 3 ? 3 : categoryData['data'].length); i++) {
          final category = categoryData['data'][i];
          print('  - ${category['categoryFirstName']} (ID: ${category['categoryId']})');
        }
      }
    } else {
      print('❌ Category list API call failed: ${categoryData['message']}');
      print('Error code: ${categoryData['code']}');
    }
  } else {
    print('❌ Category list request failed with status: ${categoryResponse.statusCode}');
    print('Response body: ${categoryResponse.body}');
  }
}