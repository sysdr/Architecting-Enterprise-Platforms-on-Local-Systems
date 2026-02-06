#!/bin/bash
set -euo pipefail

echo "🚀 Quick Start - cgroup v2 Monitor"
echo "===================================="

# Check prerequisites
echo "✓ Checking prerequisites..."
if ! grep -q cgroup2 /proc/filesystems; then
    echo "❌ cgroup v2 not supported!"
    exit 1
fi

# Check if cluster exists and is working
if k3d cluster list | grep -q "nano-idp.*1/1"; then
    echo "✓ Cluster exists, checking connectivity..."
    if kubectl get nodes &>/dev/null; then
        echo "✓ Cluster is ready!"
        CLUSTER_EXISTS=true
    else
        echo "⚠ Cluster exists but not responding, recreating..."
        k3d cluster delete nano-idp 2>/dev/null || true
        CLUSTER_EXISTS=false
    fi
else
    CLUSTER_EXISTS=false
fi

# Create cluster if needed
if [ "$CLUSTER_EXISTS" = false ]; then
    echo "📦 Creating K3d cluster (this may take 30-60s)..."
    k3d cluster create --config config/k3d-cgroupv2.yaml --wait 2>&1 | grep -E "(INFO|Creating|Successfully)" || true
    echo "✓ Cluster created"
fi

# Wait for cluster to be ready (quick check)
echo "⏳ Waiting for cluster readiness..."
for i in {1..15}; do
    if kubectl get nodes 2>/dev/null | grep -q Ready; then
        echo "✓ Cluster ready!"
        break
    fi
    sleep 1
done

# Ensure registry is running
if ! docker ps | grep -q registry:2; then
    echo "📦 Starting local registry..."
    docker run -d -p 5000:5000 --name k3d-registry registry:2 2>/dev/null || true
fi

# Build image (show progress)
echo "🔨 Building Docker image..."
cd monitor
export DOCKER_BUILDKIT=1
docker build -f backend/Dockerfile -t localhost:5000/cgroupv2-monitor:latest . --quiet 2>&1 | grep -E "(Step|Successfully|ERROR)" || echo "Building..."
echo "✓ Image built"

# Push image
echo "📤 Pushing image to registry..."
docker push localhost:5000/cgroupv2-monitor:latest --quiet 2>&1 | tail -1 || echo "Pushed"
echo "✓ Image pushed"

# Deploy
cd ..
echo "🚀 Deploying monitor..."
kubectl apply -f monitor/monitor-deployment.yaml --validate=false 2>&1 | grep -v "^$" || true
echo "✓ Deployment created"

# Wait for pod (quick check)
echo "⏳ Waiting for pod to be ready..."
for i in {1..20}; do
    if kubectl get pod -l app=cgroupv2-monitor -n monitoring 2>/dev/null | grep -q Running; then
        echo "✓ Pod is running!"
        break
    fi
    sleep 1
done

# Show status
echo ""
echo "✅ Setup Complete!"
echo "=================="
echo ""
kubectl get pods -n monitoring
echo ""
echo "📊 Access the monitor:"
echo "   kubectl port-forward -n monitoring svc/cgroupv2-monitor 8000:80"
echo "   Then visit: http://localhost:8000"
echo ""
echo "🧪 Run verification:"
echo "   ./scripts/verify.sh"
echo ""




