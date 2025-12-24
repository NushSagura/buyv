import 'dart:convert';
import 'dart:io';

void main() async {
  print('Testing CJ Dropshipping API Authentication...');
  
  try {
    await testCJAuthentication();
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> testCJAuthentication() async {
  // Create HTTP client
  final client = HttpClient();
  
  try {
    // Test authentication
    print('--- Testing Authentication ---');
    
    final request = await client.postUrl(
      Uri.parse('https://developers.cjdropshipping.com/api2.0/v1/authentication/getAccessToken')
    );
    
    request.headers.set('Content-Type', 'application/json');
    
    final requestBody = jsonEncode({
      'email': 'kerzazicherif@gmail.com',
      'apiKey': '5e861f297d2c4cbab6c41034f0f3f2f9',
    });
    
    request.write(requestBody);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Authentication Status Code: ${response.statusCode}');
    print('Authentication Response: $responseBody');

    if (response.statusCode == 200) {
      final authData = jsonDecode(responseBody);
      
      if (authData['result'] == true && authData['data'] != null) {
        final accessToken = authData['data']['accessToken'];
        final refreshToken = authData['data']['refreshToken'];
        
        print('✅ Authentication successful!');
        print('Access Token: ${accessToken.substring(0, 20)}...');
        print('Refresh Token: ${refreshToken.substring(0, 20)}...');
        
        // Test API call with token using GET method
        await testApiCallWithToken(client, accessToken);
      } else {
        print('❌ Authentication failed: ${authData['message']}');
        print('Error code: ${authData['code']}');
      }
    } else {
      print('❌ Authentication request failed with status: ${response.statusCode}');
      print('Response body: $responseBody');
    }
  } finally {
    client.close();
  }
}

Future<void> testApiCallWithToken(HttpClient client, String accessToken) async {
  try {
    // Test API call with token using GET method (as per CJ documentation)
    print('\n--- Testing Product List API (GET method) ---');
    
    final request = await client.getUrl(
      Uri.parse('https://developers.cjdropshipping.com/api2.0/v1/product/list?pageNum=1&pageSize=5')
    );
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('CJ-Access-Token', accessToken);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('Product List Status Code: ${response.statusCode}');
    print('Product List Response: $responseBody');

    if (response.statusCode == 200) {
      final productData = jsonDecode(responseBody);
      
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
      print('❌ Product list request failed with status: ${response.statusCode}');
      print('Response body: $responseBody');
    }
    
    // Test category list API as well
    print('\n--- Testing Category List API ---');
    
    final categoryRequest = await client.getUrl(
      Uri.parse('https://developers.cjdropshipping.com/api2.0/v1/product/getCategory')
    );
    
    categoryRequest.headers.set('Content-Type', 'application/json');
    categoryRequest.headers.set('CJ-Access-Token', accessToken);
    
    final categoryResponse = await categoryRequest.close();
    final categoryResponseBody = await categoryResponse.transform(utf8.decoder).join();

    print('Category List Status Code: ${categoryResponse.statusCode}');
    
    if (categoryResponse.statusCode == 200) {
      final categoryData = jsonDecode(categoryResponseBody);
      
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
      print('Response body: $categoryResponseBody');
    }
  } catch (e) {
    print('Error during API calls: $e');
  }
}