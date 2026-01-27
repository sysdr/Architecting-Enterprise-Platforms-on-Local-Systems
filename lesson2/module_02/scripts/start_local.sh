#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LESSON_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Starting Memory Monitor services locally..."

# Check if services are already running
if pgrep -f "uvicorn.*main:app" > /dev/null; then
    echo "⚠️  Backend service already running. Stopping..."
    pkill -f "uvicorn.*main:app" || true
    sleep 2
fi

if pgrep -f "vite" > /dev/null; then
    echo "⚠️  Frontend service already running. Stopping..."
    pkill -f "vite" || true
    sleep 2
fi

# Start backend
echo "Starting backend on port 8000..."
cd "${LESSON_DIR}/backend"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install -q -r requirements.txt
else
    source venv/bin/activate
fi

# Start backend in background
nohup python -m uvicorn main:app --host 0.0.0.0 --port 8000 > /tmp/memory-monitor-backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend started (PID: $BACKEND_PID)"

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ Backend is ready"
        break
    fi
    sleep 1
done

# Start frontend
echo "Starting frontend on port 5173..."
cd "${LESSON_DIR}/frontend"
if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install --silent
fi

# Set API URL for frontend
export VITE_API_URL=http://localhost:8000

# Start frontend in background
nohup npm run dev > /tmp/memory-monitor-frontend.log 2>&1 &
FRONTEND_PID=$!
echo "Frontend started (PID: $FRONTEND_PID)"

# Wait for frontend to be ready
echo "Waiting for frontend to be ready..."
sleep 5

echo ""
echo "============================================"
echo "✅ Services started successfully!"
echo "============================================"
echo "Backend:  http://localhost:8000"
echo "Frontend: http://localhost:5173"
echo ""
echo "Backend logs:  tail -f /tmp/memory-monitor-backend.log"
echo "Frontend logs: tail -f /tmp/memory-monitor-frontend.log"
echo ""
echo "To stop services:"
echo "  pkill -f 'uvicorn.*main:app'"
echo "  pkill -f 'vite'"
echo ""

