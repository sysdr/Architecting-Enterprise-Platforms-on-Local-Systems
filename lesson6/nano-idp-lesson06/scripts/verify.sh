#!/bin/bash
set -euo pipefail

echo "🔍 Verifying cgroup v2 setup..."

# Check host cgroup version
echo "1. Checking K3d node cgroup version..."
docker exec k3d-nano-idp-server-0 cat /sys/fs/cgroup/cgroup.controllers || {
    echo "❌ cgroup v2 not detected!"
    exit 1
}

# Deploy test pod
echo "2. Deploying memory stress pod..."
kubectl apply -f config/memory-stress-pod.yaml --validate=false
sleep 3

# Wait for pod
kubectl wait --for=condition=ready pod/memory-hog --timeout=30s || true

# Check pod status
echo "3. Checking pod status..."
kubectl get pod memory-hog
kubectl top pod memory-hog --use-protocol-buffers || echo "Metrics not available yet"

# Check PSI metrics
echo "4. Checking PSI metrics from monitor API..."
kubectl port-forward -n monitoring svc/cgroupv2-monitor 8000:80 &
PF_PID=$!
sleep 2

curl -s http://localhost:8000/api/health | jq .
curl -s http://localhost:8000/api/memory-stats/memory-hog | jq .

kill $PF_PID 2>/dev/null || true

echo "✅ Verification complete!"
