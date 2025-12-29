#!/bin/bash
# Quick fix deployment script

echo "=========================================="
echo "Deploying PostgreSQL Sequence Fix"
echo "=========================================="
echo ""

# Navigate to backend directory
cd buyv_backend

# Check if git is initialized
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit with sequence fix"
fi

# Add and commit the changes
echo "Adding changes..."
git add fix_sequences.py Procfile app/auth.py
git commit -m "Fix PostgreSQL sequence issue and improve error handling"

# Check if railway is installed
if ! command -v railway &> /dev/null; then
    echo ""
    echo "ERROR: Railway CLI not found!"
    echo ""
    echo "Please install Railway CLI:"
    echo "  Windows: iwr https://railway.app/install.ps1 | iex"
    echo "  Or: npm install -g @railway/cli"
    echo ""
    exit 1
fi

# Push to Railway
echo ""
echo "Deploying to Railway..."
railway up

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "The fix script will run automatically before your app starts."
echo "Check Railway logs to verify: railway logs"
echo ""
echo "After deployment completes, test user registration in your app."
