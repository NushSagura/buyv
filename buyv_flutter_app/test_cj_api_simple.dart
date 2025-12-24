import 'dart:io';
import 'dart:convert';

void main() async {
  print('Testing CJ Dropshipping API...');
  
  // Wait 5 minutes since last test to avoid rate limit
  print('Waiting 5 minutes to avoid rate limit...');
  await Future.delayed(Duration(minutes: 5));
  
  await testCJAuthentication();
}

Future<void> testCJAuthentication() async {
  final client = HttpClient();
  
  try {
    // Authentication request
    final authRequest = await client.postUrl(
      Uri.parse('https://developers.cjdropshipping.com/api2.0/v1/authentication/getAccessToken')
    );
    
    authRequest.headers.set('Content-Type', 'application/json');
    
    final authBody = jsonEncode({
      'email': 'kerzazicherif@gmail.com',
      'password': '5e861f297d2c4cbab6c41034f0f3f2f9'
    });
    
    authRequest.add(utf8.encode(authBody));
    
    final authResponse = await authRequest.close();
    final authResponseBody = await authResponse.transform(utf8.decoder).join();
    
    print('Auth Status Code: ${authResponse.statusCode}');
    print('Auth Response: $authResponseBody');
    
    if (authResponse.statusCode == 200) {
      final authData = jsonDecode(authResponseBody);
      if (authData['result'] == true) {
        final accessToken = authData['data']['accessToken'];
        print('✅ Authentication successful!');
        print('Access Token: ${accessToken.substring(0, 20)}...');
        
        // Test product list API
        await testProductList(accessToken);
      } else {
        print('❌ Authentication failed: ${authData['message']}');
      }
    } else {
      print('❌ Authentication request failed with status: ${authResponse.statusCode}');
    }
    
  } catch (e) {
    print('❌ Error during authentication: $e');
  } finally {
    client.close();
  }
}

Future<void> testProductList(String accessToken) async {
  final client = HttpClient();
  
  try {
    // Product list request using GET
    final productRequest = await client.getUrl(
      Uri.parse('https://developers.cjdropshipping.com/api2.0/v1/product/list?pageNum=1&pageSize=10')
    );
    
    productRequest.headers.set('Content-Type', 'application/json');
    productRequest.headers.set('CJ-Access-Token', accessToken);
    
    final productResponse = await productRequest.close();
    final productResponseBody = await productResponse.transform(utf8.decoder).join();
    
    print('\nProduct List Status Code: ${productResponse.statusCode}');
    print('Product List Response: ${productResponseBody.substring(0, 500)}...');
    
    if (productResponse.statusCode == 200) {
      final productData = jsonDecode(productResponseBody);
      if (productData['result'] == true) {
        final products = productData['data']['list'] as List;
        print('✅ Product list retrieved successfully!');
        print('Number of products: ${products.length}');
        
        if (products.isNotEmpty) {
          print('First product: ${products[0]['productName']}');
        }
      } else {
        print('❌ Product list failed: ${productData['message']}');
      }
    } else {
      print('❌ Product list request failed with status: ${productResponse.statusCode}');
    }
    
  } catch (e) {
    print('❌ Error during product list request: $e');
  } finally {
    client.close();
  }
}