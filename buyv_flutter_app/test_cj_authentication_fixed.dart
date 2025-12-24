import 'dart:convert';
import 'package:http/http.dart' as http;

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
    Uri.parse(
      'https://developers.cjdropshipping.com/api2.0/v1/authentication/getAccessToken',
    ),
    headers: {'Content-Type': 'application/json'},
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
    }
  } else {
    print(
      '❌ Authentication request failed with status: ${authResponse.statusCode}',
    );
  }
}

Future<void> testApiCallWithToken(String accessToken) async {
  // Test API call with token using GET method (as per documentation)
  print('\n--- Testing API call with token (GET method) ---');
  final productResponse = await http.get(
    Uri.parse(
      'https://developers.cjdropshipping.com/api2.0/v1/product/list?pageNum=1&pageSize=5',
    ),
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
      print(
        'Products in this page: ${productData['data']['list']?.length ?? 0}',
      );
    } else {
      print('❌ Product list API call failed: ${productData['message']}');
      print('Error code: ${productData['code']}');
    }
  } else {
    print(
      '❌ Product list request failed with status: ${productResponse.statusCode}',
    );
  }

  // Test category list API as well
  print('\n--- Testing Category List API ---');
  final categoryResponse = await http.get(
    Uri.parse(
      'https://developers.cjdropshipping.com/api2.0/v1/product/getCategory',
    ),
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
    } else {
      print('❌ Category list API call failed: ${categoryData['message']}');
    }
  } else {
    print(
      '❌ Category list request failed with status: ${categoryResponse.statusCode}',
    );
  }
}
