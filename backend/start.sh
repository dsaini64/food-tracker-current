#!/bin/bash

# Food Tracker Backend Start Script
# This script ensures proper startup for Railway deployment

echo "🍎 Starting Food Tracker Backend..."

# Check if node_modules exists, if not install dependencies
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Set production environment
export NODE_ENV=production

# Start the application
echo "🚀 Starting Node.js server..."
exec npm start
