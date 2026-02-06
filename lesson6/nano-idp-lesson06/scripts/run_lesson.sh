#!/bin/bash
set -euo pipefail

echo "📚 Lesson 6: cgroup v2 Runtime Setup"
echo "===================================="

# Check prerequisites
echo "Checking prerequisites..."
if ! grep -q cgroup2 /proc/filesystems; then
    echo "❌ cgroup v2 not supported by kernel!"
    echo "Please enable with: systemd.unified_cgroup_hierarchy=1"
    exit 1
fi

# Create cluster
echo "Creating K3d cluster with cgroup v2..."
k3d cluster create --config config/k3d-cgroupv2.yaml

# Wait for cluster (reduced timeout, check readiness faster)
echo "Waiting for cluster to be ready..."
for i in {1..30}; do
    if kubectl get nodes 2>/dev/null | grep -q Ready; then
        echo "✅ Cluster ready!"
        break
    fi
    sleep 2
done
kubectl wait --for=condition=ready node --all --timeout=30s || true

# Build and deploy monitor
echo "Building monitor..."
./scripts/build_and_deploy.sh

echo "
✅ Setup complete!

Next steps:
1. Deploy test pod: kubectl apply -f config/memory-stress-pod.yaml
2. Run verification: ./scripts/verify.sh
3. View monitor: kubectl port-forward -n monitoring svc/cgroupv2-monitor 8000:80
   Then visit: http://localhost:8000 (Dashboard) or http://localhost:8000/docs (API)

Cleanup: ./scripts/cleanup.sh
"
