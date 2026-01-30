#!/bin/bash
set -euo pipefail

echo "=== Building Kernel Monitor ==="

# Ensure local registry exists
if ! docker ps | grep -q k3d-nano-cluster-registry; then
    echo "Error: K3d registry not running. Start cluster first."
    exit 1
fi

# Build image
docker build -t localhost:5000/kernel-monitor:latest .

# Push to local registry
docker push localhost:5000/kernel-monitor:latest

# Tag for k3d cluster
docker tag localhost:5000/kernel-monitor:latest docker.io/library/kernel-monitor:latest

# Import both image tags into k3d cluster
echo "Importing images into k3d cluster..."
k3d image import localhost:5000/kernel-monitor:latest -c nano-substrate
k3d image import docker.io/library/kernel-monitor:latest -c nano-substrate

# Deploy to cluster
kubectl apply -f k8s/deployment.yaml

echo "Waiting for deployment..."
kubectl wait --for=condition=available --timeout=60s \
    deployment/kernel-monitor -n kube-system

echo ""
echo "=== Deployment Complete ==="
kubectl get pods -n kube-system -l app=kernel-monitor
