# CJ Dropshipping CORS Proxy Server

This proxy server solves CORS (Cross-Origin Resource Sharing) issues when accessing the CJ Dropshipping API from a Flutter web application.

## Problem
The CJ Dropshipping API doesn't include the necessary CORS headers, which prevents web browsers from making direct requests to their API endpoints. This results in errors like:
```
Access to fetch at 'https://developers.cjdropshipping.com/api2.0/v1/authentication/getAccessToken' from origin 'http://localhost:xxxx' has been blocked by CORS policy
```

## Solution
This Node.js proxy server acts as an intermediary between your Flutter web app and the CJ Dropshipping API, adding the necessary CORS headers and forwarding requests.

## Setup Instructions

### Prerequisites
- Node.js (version 14 or higher)
- npm (comes with Node.js)

### Installation & Usage

#### Option 1: Using the Batch File (Windows)
1. Double-click `start_proxy.bat`
2. The script will automatically install dependencies and start the server
3. The proxy server will run on `http://localhost:3001`

#### Option 2: Manual Setup
1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the proxy server:
   ```bash
   npm start
   ```

3. The server will be available at `http://localhost:3001`

## How It Works

### API Endpoint Mapping
- **Original CJ API**: `https://developers.cjdropshipping.com/api2.0/v1/...`
- **Proxy URL**: `http://localhost:3001/api/cj/v1/...`

### Example Usage
Instead of calling:
```
https://developers.cjdropshipping.com/api2.0/v1/authentication/getAccessToken
```

Your Flutter app now calls:
```
http://localhost:3001/api/cj/v1/authentication/getAccessToken
```

### Features
- ✅ Adds CORS headers to all responses
- ✅ Forwards all HTTP methods (GET, POST, PUT, DELETE)
- ✅ Preserves request headers (including CJ-Access-Token)
- ✅ Handles JSON request/response bodies
- ✅ Error handling and logging
- ✅ Health check endpoint at `/health`

## Configuration

The proxy server is configured to:
- Run on port `3001`
- Allow requests from Flutter dev servers (localhost:52000, localhost:3000, localhost:8080)
- Forward requests to `https://developers.cjdropshipping.com`
- Add necessary CORS headers

## Troubleshooting

### Port Already in Use
If port 3001 is already in use, you can modify the `PORT` variable in `cors_proxy_server.js`:
```javascript
const PORT = 3002; // Change to any available port
```

Don't forget to update the `cjBaseUrl` in your Flutter app's `app_constants.dart`:
```dart
static const String cjBaseUrl = 'http://localhost:3002/api/cj';
```

### Node.js Not Found
Make sure Node.js is installed and added to your system PATH:
1. Download from https://nodejs.org/
2. Install with default settings
3. Restart your terminal/command prompt

## Development

### Running in Development Mode
```bash
npm run dev
```
This uses nodemon for automatic restarts when files change.

### Health Check
Visit `http://localhost:3001/health` to verify the server is running.

## Important Notes

1. **Development Only**: This proxy is intended for development purposes. For production, implement proper CORS handling on your backend.

2. **Keep Running**: The proxy server must be running whenever you're testing the Flutter web app with CJ Dropshipping API calls.

3. **Flutter App Configuration**: Make sure your Flutter app's `app_constants.dart` is updated to use the proxy URL.

## Files Created
- `cors_proxy_server.js` - Main proxy server
- `package.json` - Node.js dependencies
- `start_proxy.bat` - Windows batch file for easy startup
- `README_CORS_PROXY.md` - This documentation