# Quick Fix Deployment Script for Windows
# Run this in PowerShell

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Deploying PostgreSQL Sequence Fix" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to backend directory
Set-Location buyv_backend

# Check if git is initialized
if (-not (Test-Path .git)) {
    Write-Host "Initializing git repository..." -ForegroundColor Yellow
    git init
    git add .
    git commit -m "Initial commit with sequence fix"
}

# Add and commit the changes
Write-Host "Adding changes..." -ForegroundColor Yellow
git add fix_sequences.py Procfile app/auth.py
git commit -m "Fix PostgreSQL sequence issue and improve error handling"

# Check if railway is installed
if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "ERROR: Railway CLI not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Railway CLI:" -ForegroundColor Yellow
    Write-Host "  Run as Administrator: iwr https://railway.app/install.ps1 | iex" -ForegroundColor White
    Write-Host "  Or: npm install -g @railway/cli" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Push to Railway
Write-Host ""
Write-Host "Deploying to Railway..." -ForegroundColor Yellow
railway up

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "The fix script will run automatically before your app starts." -ForegroundColor Cyan
Write-Host "Check Railway logs to verify: railway logs" -ForegroundColor Cyan
Write-Host ""
Write-Host "After deployment completes, test user registration in your app." -ForegroundColor Cyan
