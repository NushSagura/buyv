import 'dart:io';
import 'dart:convert';

/// CORS Proxy Server for CJ Dropshipping API
/// This server acts as a proxy to bypass CORS restrictions when calling CJ API from Flutter web
class CORSProxyServer {
  static const int port = 3001;
  static const String cjBaseUrl = 'https://developers.cjdropshipping.com/api2.0/v1';
  
  static HttpServer? _server;
  static final HttpClient _httpClient = HttpClient();

  /// Start the CORS proxy server
  static Future<void> start() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('🚀 CORS Proxy Server started on http://localhost:$port');
      print('📡 Proxying requests to: $cjBaseUrl');
      print('🔄 Ready to handle CJ Dropshipping API requests...\n');

      await for (HttpRequest request in _server!) {
        await _handleRequest(request);
      }
    } catch (e) {
      print('❌ Failed to start CORS proxy server: $e');
    }
  }

  /// Handle incoming HTTP requests
  static Future<void> _handleRequest(HttpRequest request) async {
    try {
      // Add CORS headers to all responses
      _addCORSHeaders(request.response);

      // Handle preflight OPTIONS requests
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      // Extract the CJ API path from the request
      String path = request.uri.path;
      if (path.startsWith('/api/cj')) {
        path = path.substring('/api/cj'.length);
      }

      // Build the target URL
      final targetUrl = '$cjBaseUrl$path';
      final queryString = request.uri.query.isNotEmpty ? '?${request.uri.query}' : '';
      final fullUrl = '$targetUrl$queryString';

      print('🔄 Proxying ${request.method} request to: $fullUrl');

      // Create the proxy request
      final proxyRequest = await _httpClient.openUrl(request.method, Uri.parse(fullUrl));

      // Copy headers from original request (except host and origin)
      request.headers.forEach((name, values) {
        if (!_shouldSkipHeader(name)) {
          for (String value in values) {
            proxyRequest.headers.add(name, value);
          }
        }
      });

      // Set proper host header for CJ API
      proxyRequest.headers.set('host', 'developers.cjdropshipping.com');
      proxyRequest.headers.set('origin', 'https://developers.cjdropshipping.com');
      proxyRequest.headers.set('referer', 'https://developers.cjdropshipping.com/');

      // Copy request body if present
      HttpClientResponse proxyResponse;
      if (request.contentLength > 0) {
        // Read request body and write to proxy request
        final requestBody = await request.toList();
        for (var chunk in requestBody) {
          proxyRequest.add(chunk);
        }
        proxyResponse = await proxyRequest.close();
      } else {
        proxyResponse = await proxyRequest.close();
      }

      // Copy response status and headers
      request.response.statusCode = proxyResponse.statusCode;
      
      proxyResponse.headers.forEach((name, values) {
        if (!_shouldSkipResponseHeader(name)) {
          for (String value in values) {
            request.response.headers.add(name, value);
          }
        }
      });

      // Ensure CORS headers are present
      _addCORSHeaders(request.response);

      // Copy response body
      await proxyResponse.pipe(request.response);

      print('✅ Request completed with status: ${proxyResponse.statusCode}');

    } catch (e) {
      print('❌ Error handling request: $e');
      
      // Send error response
      request.response.statusCode = HttpStatus.internalServerError;
      _addCORSHeaders(request.response);
      
      final errorResponse = {
        'error': 'Proxy server error',
        'message': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(errorResponse));
      await request.response.close();
    }
  }

  /// Add CORS headers to the response
  static void _addCORSHeaders(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 
        'Origin, X-Requested-With, Content-Type, Accept, Authorization, CJ-Access-Token');
    response.headers.set('Access-Control-Max-Age', '86400');
    response.headers.set('Access-Control-Allow-Credentials', 'false');
  }

  /// Check if a request header should be skipped when proxying
  static bool _shouldSkipHeader(String headerName) {
    final skipHeaders = {
      'host',
      'origin',
      'referer',
      'connection',
      'upgrade-insecure-requests',
      'sec-fetch-site',
      'sec-fetch-mode',
      'sec-fetch-dest',
      'sec-ch-ua',
      'sec-ch-ua-mobile',
      'sec-ch-ua-platform',
    };
    return skipHeaders.contains(headerName.toLowerCase());
  }

  /// Check if a response header should be skipped when returning to client
  static bool _shouldSkipResponseHeader(String headerName) {
    final skipHeaders = {
      'access-control-allow-origin',
      'access-control-allow-methods',
      'access-control-allow-headers',
      'access-control-max-age',
      'access-control-allow-credentials',
    };
    return skipHeaders.contains(headerName.toLowerCase());
  }

  /// Stop the proxy server
  static Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      print('🛑 CORS Proxy Server stopped');
    }
    _httpClient.close();
  }

  /// Get server status
  static bool get isRunning => _server != null;
  
  /// Get server URL
  static String get serverUrl => 'http://localhost:$port';
}

/// Main function to run the CORS proxy server
void main() async {
  print('🌐 Starting CORS Proxy Server for CJ Dropshipping API...');
  print('📋 This server will help bypass CORS restrictions for Flutter web app');
  print('🔧 Server configuration:');
  print('   - Local port: ${CORSProxyServer.port}');
  print('   - Target API: ${CORSProxyServer.cjBaseUrl}');
  print('   - CORS enabled for all origins');
  print('');

  // Handle Ctrl+C gracefully
  ProcessSignal.sigint.watch().listen((signal) async {
    print('\n🛑 Received interrupt signal, shutting down...');
    await CORSProxyServer.stop();
    exit(0);
  });

  try {
    await CORSProxyServer.start();
  } catch (e) {
    print('❌ Failed to start server: $e');
    exit(1);
  }
}