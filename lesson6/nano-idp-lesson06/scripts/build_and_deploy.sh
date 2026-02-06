#!/bin/bash
set -euo pipefail

echo "🔨 Building cgroup v2 monitor..."

# Start local registry if not running
if ! docker ps | grep -q registry:2; then
    docker run -d -p 5000:5000 --name k3d-registry registry:2
fi

# Build and push (build from monitor directory to include frontend)
# Use buildkit for faster builds
export DOCKER_BUILDKIT=1
cd monitor
docker build -f backend/Dockerfile -t localhost:5000/cgroupv2-monitor:latest . --progress=plain 2>&1 | grep -E "(Step|Successfully|ERROR)" || true
docker push localhost:5000/cgroupv2-monitor:latest 2>&1 | tail -5

# Deploy to cluster (skip validation for speed)
cd ..
kubectl apply -f monitor/monitor-deployment.yaml --validate=false

echo "✅ Monitor deployed. Waiting for pod..."
for i in {1..20}; do
    if kubectl get pod -l app=cgroupv2-monitor -n monitoring 2>/dev/null | grep -q Running; then
        echo "✅ Pod is running!"
        break
    fi
    sleep 2
done
kubectl wait --for=condition=ready pod -l app=cgroupv2-monitor -n monitoring --timeout=30s || true

echo "🎉 Monitor available at: kubectl port-forward -n monitoring svc/cgroupv2-monitor 8000:80"
