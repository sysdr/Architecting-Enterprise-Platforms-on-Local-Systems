#!/bin/bash
set -euo pipefail

echo "🚀 Starting CNI Monitor Backend..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt

# Start the server
echo "✅ Starting FastAPI server on http://0.0.0.0:8000"
exec python main.py
