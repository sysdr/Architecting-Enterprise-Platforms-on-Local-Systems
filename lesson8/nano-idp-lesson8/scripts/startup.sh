#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
NAMESPACE="storage-demo"

echo "🚀 Starting Storage Monitor Dashboard..."
echo "========================================"

# Check for duplicate services
echo ""
echo "🔍 Checking for duplicate services..."

# Check for local backend processes
BACKEND_COUNT=$(pgrep -f "uvicorn.*main:app" | wc -l)
if [ "$BACKEND_COUNT" -gt 0 ]; then
    echo "⚠️  Found $BACKEND_COUNT existing backend process(es). Stopping..."
    pkill -f "uvicorn.*main:app" || true
    sleep 2
fi

# Check for local frontend processes
FRONTEND_COUNT=$(pgrep -f "vite" | wc -l)
if [ "$FRONTEND_COUNT" -gt 0 ]; then
    echo "⚠️  Found $FRONTEND_COUNT existing frontend process(es). Stopping..."
    pkill -f "vite" || true
    sleep 2
fi

# Check for kubectl port-forward
PF_COUNT=$(pgrep -f "kubectl port-forward.*storage-monitor" | wc -l)
if [ "$PF_COUNT" -gt 0 ]; then
    echo "⚠️  Found $PF_COUNT existing port-forward process(es). Stopping..."
    pkill -f "kubectl port-forward.*storage-monitor" || true
    sleep 2
fi

# Check if running in k8s mode or local mode
USE_K8S=false
if kubectl get namespace ${NAMESPACE} &>/dev/null && \
   kubectl get deployment storage-monitor -n ${NAMESPACE} &>/dev/null; then
    USE_K8S=true
    echo ""
    echo "📦 Kubernetes mode detected. Using k8s services..."
    
    # Set kubeconfig
    if command -v k3d &>/dev/null; then
        export KUBECONFIG=$(k3d kubeconfig write nano-k8s 2>/dev/null || echo "")
    fi
    
    # Check if cluster is accessible
    if ! kubectl get nodes &>/dev/null; then
        echo "❌ Cannot connect to cluster. Falling back to local mode..."
        USE_K8S=false
    else
        # Check if storage-monitor pod is running
        if ! kubectl get pod -l app=storage-monitor -n ${NAMESPACE} 2>/dev/null | grep -q Running; then
            echo "⚠️  Storage monitor pod is not running. Deploying..."
            cd "${PROJECT_DIR}"
            if [ -f "scripts/build_and_deploy.sh" ]; then
                ./scripts/build_and_deploy.sh
            fi
            kubectl apply -f k8s/ 2>/dev/null || true
            echo "⏳ Waiting for pod to be ready..."
            kubectl wait --for=condition=ready pod -l app=storage-monitor -n ${NAMESPACE} --timeout=120s || true
        fi
        
        # Start port-forward for backend
        echo "📡 Starting port-forward for backend on port 8000..."
        kubectl port-forward -n ${NAMESPACE} svc/storage-monitor 8000:80 > /tmp/storage-monitor-backend.log 2>&1 &
        PF_PID=$!
        sleep 3
        
        # Verify backend connection
        if curl -s http://localhost:8000/api/health &>/dev/null; then
            echo "✅ Backend is accessible via port-forward"
        else
            echo "❌ Backend port-forward failed. Check logs: /tmp/storage-monitor-backend.log"
            USE_K8S=false
        fi
    fi
fi

# Local mode fallback
if [ "$USE_K8S" = false ]; then
    echo ""
    echo "💻 Local development mode..."
    
    # Start backend locally
    echo "Starting backend on port 8000..."
    cd "${PROJECT_DIR}/backend"
    
    if [ ! -d "venv" ]; then
        echo "Creating Python virtual environment..."
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    if ! pip list | grep -q fastapi; then
        echo "Installing backend dependencies..."
        pip install -q -r requirements.txt
    fi
    
    # Start backend in background
    nohup python -m uvicorn main:app --host 0.0.0.0 --port 8000 > /tmp/storage-monitor-backend.log 2>&1 &
    BACKEND_PID=$!
    echo "Backend started (PID: $BACKEND_PID)"
    
    # Wait for backend to be ready
    echo "Waiting for backend to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:8000/api/health > /dev/null 2>&1; then
            echo "✅ Backend is ready"
            break
        fi
        sleep 1
    done
fi

# Start frontend
echo ""
echo "Starting frontend on port 5173..."
cd "${PROJECT_DIR}/frontend"

if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install --silent
fi

# Start frontend in background
nohup npm run dev > /tmp/storage-monitor-frontend.log 2>&1 &
FRONTEND_PID=$!
echo "Frontend started (PID: $FRONTEND_PID)"

# Wait for frontend to be ready
echo "Waiting for frontend to be ready..."
sleep 5

echo ""
echo "============================================"
echo "✅ Storage Monitor Dashboard is running!"
echo "============================================"
echo "Backend:  http://localhost:8000"
echo "Frontend: http://localhost:5173"
echo ""
if [ "$USE_K8S" = true ]; then
    echo "Backend mode: Kubernetes (port-forward PID: $PF_PID)"
else
    echo "Backend mode: Local (PID: $BACKEND_PID)"
fi
echo "Frontend mode: Local (PID: $FRONTEND_PID)"
echo ""
echo "Logs:"
echo "  Backend:  tail -f /tmp/storage-monitor-backend.log"
echo "  Frontend: tail -f /tmp/storage-monitor-frontend.log"
echo ""
echo "To stop services:"
if [ "$USE_K8S" = true ]; then
    echo "  pkill -f 'kubectl port-forward.*storage-monitor'"
else
    echo "  pkill -f 'uvicorn.*main:app'"
fi
echo "  pkill -f 'vite'"
echo ""
