#!/bin/bash

# FuelBhai Email Verification Setup Script
# This script helps set up the Firebase Cloud Function for email verification

echo "🚀 FuelBhai Email Verification Setup"
echo "===================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null
then
    echo "❌ Firebase CLI not found!"
    echo "📦 Installing Firebase CLI..."
    npm install -g firebase-tools
else
    echo "✅ Firebase CLI found"
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null
then
    echo "❌ Node.js not found! Please install Node.js 18+ from https://nodejs.org"
    exit 1
else
    NODE_VERSION=$(node --version)
    echo "✅ Node.js $NODE_VERSION found"
fi

echo ""
echo "📝 Next steps:"
echo "1. Login to Firebase: firebase login"
echo "2. Install function dependencies: cd functions && npm install"
echo "3. Follow instructions in CLOUD_FUNCTION_SETUP.md"
echo ""
echo "Need help? Check CLOUD_FUNCTION_SETUP.md for detailed setup guide"
