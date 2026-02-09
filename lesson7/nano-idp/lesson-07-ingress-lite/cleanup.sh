#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Cleaning up Ingress Lite"
echo "=========================================="

LESSON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$LESSON_DIR/k8s"

# Delete test ingress
echo "Deleting test ingress..."
kubectl delete -f "$K8S_DIR/test-ingress.yaml" --ignore-not-found=true

# Delete test backend
echo "Deleting test backend..."
kubectl delete -f "$K8S_DIR/test-backend.yaml" --ignore-not-found=true

# Delete nginx ingress controller
echo "Deleting nginx ingress controller..."
kubectl delete -f "$K8S_DIR/nginx-ingressclass.yaml" --ignore-not-found=true
kubectl delete -f "$K8S_DIR/nginx-ingress-controller.yaml" --ignore-not-found=true

# Remove Docker image
echo "Removing Docker image..."
docker rmi localhost:5000/test-backend:latest || true

echo ""
echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
echo ""
echo "Verify cleanup with:"
echo "  kubectl get pods -n kube-system -l app=nginx-ingress"
echo "  kubectl get pods -n default -l app=test-backend"
