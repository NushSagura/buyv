const express = require('express');
const cors = require('cors');
const https = require('https');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = 3001;

// Allowed origins including local previews
const allowedOrigins = [
  'http://localhost:5500',
  'http://127.0.0.1:5500',
  'http://localhost:52000',
  'http://localhost:3000',
  'http://localhost:8080'
];

const corsOptions = {
  origin: function (origin, callback) {
    // allow non-browser requests (no origin) and whitelisted origins
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'CJ-Access-Token'],
  credentials: false // do not use wildcard with credentials=true
};

// Enable CORS globally
app.use(cors(corsOptions));

// Parse JSON bodies
app.use(express.json());

// Preflight handler for CJ routes (must be BEFORE proxy)
app.options('/api/cj/*', (req, res) => {
  const origin = req.headers.origin;
  if (!origin || allowedOrigins.includes(origin)) {
    res.header('Access-Control-Allow-Origin', origin || '*');
    res.header('Vary', 'Origin');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, CJ-Access-Token');
    res.header('Access-Control-Max-Age', '86400');
    return res.sendStatus(200);
  }
  return res.sendStatus(403);
});

// Proxy middleware for CJ Dropshipping API
const cjProxy = createProxyMiddleware({
  target: 'https://developers.cjdropshipping.com',
  changeOrigin: true,
  secure: true,
  xfwd: true,
  timeout: 30000,
  proxyTimeout: 30000,
  agent: new https.Agent({ keepAlive: true }),
  headers: {
    // mimic a real browser user agent to avoid upstream filtering issues
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36'
  },
  pathRewrite: {
    '^/api/cj': '/api2.0/v1'
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying ${req.method} ${req.url} to CJ API`);
    // Forward CJ-Access-Token if present
    // Forward CJ-Access-Token if present
    if (req.headers['cj-access-token']) {
      proxyReq.setHeader('CJ-Access-Token', req.headers['cj-access-token']);
    }
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`Response from CJ API: ${proxyRes.statusCode}`);
    const origin = req.headers.origin;
    // Add CORS headers to response
    proxyRes.headers['Access-Control-Allow-Origin'] = origin || '*';
    proxyRes.headers['Vary'] = 'Origin';
    proxyRes.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
    proxyRes.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, CJ-Access-Token';
    proxyRes.headers['Access-Control-Expose-Headers'] = 'Content-Type, Authorization, CJ-Access-Token';
  },
  onError: (err, req, res) => {
    console.error('Proxy error:', err);
    res.status(500).json({
      error: 'Proxy error',
      message: err.message
    });
  }
});

// Use the proxy for all /api/cj routes
app.use('/api/cj', cjProxy);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'CJ Dropshipping CORS Proxy Server is running',
    timestamp: new Date().toISOString()
  });
});

// Handle preflight requests
app.options('*', (req, res) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, CJ-Access-Token');
  res.sendStatus(200);
});

app.listen(PORT, () => {
  console.log(`🚀 CJ Dropshipping CORS Proxy Server running on http://localhost:${PORT}`);
  console.log(`📡 Proxying requests to: https://developers.cjdropshipping.com`);
  console.log(`🔗 Use this base URL in your Flutter app: http://localhost:${PORT}/api/cj`);
  console.log(`💡 Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 CORS Proxy Server shutting down...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 CORS Proxy Server shutting down...');
  process.exit(0);
});