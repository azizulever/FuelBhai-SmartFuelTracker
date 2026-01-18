@echo off
REM FuelBhai Email Verification Setup Script for Windows
REM This script helps set up the Firebase Cloud Function for email verification

echo.
echo 🚀 FuelBhai Email Verification Setup
echo ====================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Firebase CLI not found!
    echo 📦 Installing Firebase CLI...
    npm install -g firebase-tools
) else (
    echo ✅ Firebase CLI found
)

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Node.js not found! Please install Node.js 18+ from https://nodejs.org
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo ✅ Node.js %NODE_VERSION% found
)

echo.
echo 📝 Next steps:
echo 1. Login to Firebase: firebase login
echo 2. Install function dependencies: cd functions && npm install
echo 3. Follow instructions in CLOUD_FUNCTION_SETUP.md
echo.
echo Need help? Check CLOUD_FUNCTION_SETUP.md for detailed setup guide
echo.
pause
