#!/bin/bash
# Reliable frontend server - uses port 3000 by default to avoid conflicts

PORT=${1:-3000}
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Kill any existing server on this port
fuser -k ${PORT}/tcp 2>/dev/null || true
pkill -f "http.server.*${PORT}" 2>/dev/null || true
sleep 1

cd "$DIR"

echo "=========================================="
echo "🚀 Starting Frontend Dashboard"
echo "=========================================="
echo "📍 Port: $PORT"
echo "📁 Directory: $DIR"
echo ""
echo "✅ Dashboard URL: http://localhost:$PORT"
echo ""
echo "Press Ctrl+C to stop the server"
echo "=========================================="
echo ""

# Start the server
if command -v python3 &> /dev/null; then
    exec python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    exec python -m SimpleHTTPServer $PORT
else
    echo "❌ Error: Python not found. Please install Python 3."
    exit 1
fi

