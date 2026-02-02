#!/bin/bash
set -euo pipefail

echo "🚀 Starting CNI Monitor Frontend..."

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start the dev server
echo "✅ Starting Vite dev server on http://localhost:3000"
exec npm run dev
