import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing CORS Proxy Server...');
  
  // Test the proxy server
  try {
    final response = await http.post(
      Uri.parse('http://localhost:3001/api/cj/authentication/getAccessToken'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': 'test@example.com',
        'password': 'testpassword'
      }),
    );
    
    print('✅ Proxy server is working!');
    print('Status Code: ${response.statusCode}');
    print('Response: ${response.body}');
    
  } catch (e) {
    print('❌ Error testing proxy: $e');
  }
}