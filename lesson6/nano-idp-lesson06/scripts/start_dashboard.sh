#!/bin/bash
set -euo pipefail

echo "🚀 Starting cgroup v2 Monitor Dashboard..."

# Set kubeconfig
export KUBECONFIG=$(k3d kubeconfig write nano-idp)

# Check if cluster is accessible
if ! kubectl get nodes &>/dev/null; then
    echo "❌ Cannot connect to cluster. Please ensure k3d cluster 'nano-idp' is running."
    exit 1
fi

# Check if monitoring pod is running
if ! kubectl get pod -l app=cgroupv2-monitor -n monitoring &>/dev/null | grep -q Running; then
    echo "⚠️  Monitoring pod is not running. Deploying..."
    cd "$(dirname "$0")/.."
    ./scripts/build_and_deploy.sh
fi

# Kill any existing port-forward on port 8000
pkill -f "kubectl port-forward.*8000" 2>/dev/null || true
sleep 1

# Start port-forward
echo "📡 Starting port-forward on port 8000..."
kubectl port-forward -n monitoring svc/cgroupv2-monitor 8000:80 > /tmp/port-forward.log 2>&1 &
PF_PID=$!

# Wait a moment for port-forward to establish
sleep 3

# Verify connection
if curl -s http://localhost:8000/api/health &>/dev/null; then
    echo ""
    echo "✅ Dashboard is now running!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 Open your browser and visit:"
    echo "   http://localhost:8000"
    echo ""
    echo "📊 Port-forward PID: $PF_PID"
    echo "📝 Logs: /tmp/port-forward.log"
    echo ""
    echo "To stop the dashboard, run:"
    echo "   pkill -f 'kubectl port-forward.*cgroupv2-monitor'"
    echo ""
else
    echo "❌ Failed to start port-forward. Check logs: /tmp/port-forward.log"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi


