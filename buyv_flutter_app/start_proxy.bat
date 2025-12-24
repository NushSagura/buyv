@echo off
echo Starting CJ Dropshipping CORS Proxy Server...
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if npm is available
where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: npm is not available
    echo Please make sure Node.js is properly installed
    pause
    exit /b 1
)

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo Installing dependencies...
    npm install
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Failed to install dependencies
        pause
        exit /b 1
    )
)

REM Start the proxy server
echo Starting proxy server on http://localhost:3001...
echo Press Ctrl+C to stop the server
echo.
node cors_proxy_server.js

pause