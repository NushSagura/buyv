#!/usr/bin/env python3
"""
CJ Dropshipping CORS Proxy Server
Solves CORS issues when accessing CJ API from Flutter web app
"""

import json
import logging
from urllib.parse import urljoin, urlparse, parse_qs
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class CORSProxyHandler(BaseHTTPRequestHandler):
    """HTTP request handler with CORS support for CJ Dropshipping API"""
    
    # CJ Dropshipping API base URL
    CJ_API_BASE = 'https://developers.cjdropshipping.com/api2.0'
    
    def _set_cors_headers(self):
        """Set CORS headers for all responses"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, CJ-Access-Token')
        self.send_header('Access-Control-Max-Age', '86400')
    
    def _get_target_url(self):
        """Convert proxy path to actual CJ API URL"""
        # Remove /api/cj prefix and construct full URL
        path = self.path
        if path.startswith('/api/cj'):
            path = path[7:]  # Remove '/api/cj'
        
        target_url = urljoin(self.CJ_API_BASE, path.lstrip('/'))
        logger.info(f"Proxying {self.command} {self.path} -> {target_url}")
        return target_url
    
    def _proxy_request(self, method='GET', data=None):
        """Proxy the request to CJ API"""
        try:
            target_url = self._get_target_url()
            
            # Create request
            req = Request(target_url, method=method)
            
            # Copy headers from original request
            for header_name, header_value in self.headers.items():
                if header_name.lower() not in ['host', 'connection']:
                    req.add_header(header_name, header_value)
            
            # Add data for POST requests
            if data:
                req.data = data
                req.add_header('Content-Type', 'application/json')
                req.add_header('Content-Length', str(len(data)))
            
            # Make the request
            try:
                with urlopen(req, timeout=30) as response:
                    response_data = response.read()
                    
                    # Send response
                    self.send_response(response.status)
                    self._set_cors_headers()
                    
                    # Copy response headers
                    for header_name, header_value in response.headers.items():
                        if header_name.lower() not in ['access-control-allow-origin', 
                                                     'access-control-allow-methods',
                                                     'access-control-allow-headers']:
                            self.send_header(header_name, header_value)
                    
                    self.end_headers()
                    self.wfile.write(response_data)
                    
                    logger.info(f"✅ Success: {method} {self.path} -> {response.status}")
                    
            except HTTPError as e:
                # Handle HTTP errors from CJ API
                error_data = e.read() if hasattr(e, 'read') else b'{"error": "HTTP Error"}'
                
                self.send_response(e.code)
                self._set_cors_headers()
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(error_data)
                
                logger.warning(f"⚠️  HTTP Error: {method} {self.path} -> {e.code}")
                
        except URLError as e:
            # Handle network errors
            self.send_response(500)
            self._set_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            error_response = json.dumps({
                'error': 'Network Error',
                'message': str(e.reason)
            }).encode('utf-8')
            
            self.wfile.write(error_response)
            logger.error(f"❌ Network Error: {method} {self.path} -> {str(e)}")
            
        except Exception as e:
            # Handle other errors
            self.send_response(500)
            self._set_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            
            error_response = json.dumps({
                'error': 'Proxy Error',
                'message': str(e)
            }).encode('utf-8')
            
            self.wfile.write(error_response)
            logger.error(f"❌ Proxy Error: {method} {self.path} -> {str(e)}")
    
    def do_OPTIONS(self):
        """Handle preflight requests"""
        self.send_response(200)
        self._set_cors_headers()
        self.end_headers()
        logger.info(f"✅ Preflight: OPTIONS {self.path}")
    
    def do_GET(self):
        """Handle GET requests"""
        if self.path == '/health':
            self._handle_health_check()
        else:
            self._proxy_request('GET')
    
    def do_POST(self):
        """Handle POST requests"""
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length) if content_length > 0 else None
        self._proxy_request('POST', post_data)
    
    def do_PUT(self):
        """Handle PUT requests"""
        content_length = int(self.headers.get('Content-Length', 0))
        put_data = self.rfile.read(content_length) if content_length > 0 else None
        self._proxy_request('PUT', put_data)
    
    def do_DELETE(self):
        """Handle DELETE requests"""
        self._proxy_request('DELETE')
    
    def _handle_health_check(self):
        """Handle health check endpoint"""
        self.send_response(200)
        self._set_cors_headers()
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        
        health_data = json.dumps({
            'status': 'OK',
            'message': 'CJ Dropshipping CORS Proxy Server is running',
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
            'target_api': self.CJ_API_BASE
        }).encode('utf-8')
        
        self.wfile.write(health_data)
        logger.info("✅ Health check requested")
    
    def log_message(self, format, *args):
        """Override to use our logger"""
        pass  # We handle logging in _proxy_request methods

def run_server(port=3001):
    """Run the CORS proxy server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, CORSProxyHandler)
    
    print(f"🚀 CJ Dropshipping CORS Proxy Server running on http://localhost:{port}")
    print(f"📡 Proxying requests to: {CORSProxyHandler.CJ_API_BASE}")
    print(f"🔗 Use this base URL in your Flutter app: http://localhost:{port}/api/cj")
    print(f"💡 Health check: http://localhost:{port}/health")
    print("🛑 Press Ctrl+C to stop the server")
    print("-" * 60)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 CORS Proxy Server shutting down...")
        httpd.shutdown()
        httpd.server_close()

if __name__ == '__main__':
    run_server()