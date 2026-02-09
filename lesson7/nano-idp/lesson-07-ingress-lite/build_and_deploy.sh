#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Building and Deploying Ingress Lite"
echo "=========================================="

LESSON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$LESSON_DIR/backend"
K8S_DIR="$LESSON_DIR/k8s"

# Ensure K3d local registry exists
if ! curl -s http://localhost:5000/v2/ > /dev/null 2>&1; then
    echo "ERROR: K3d local registry not accessible on localhost:5000. Please run Lesson 1 setup first."
    exit 1
fi

# Build test backend image
echo "Building test backend Docker image..."
cd "$BACKEND_DIR"
docker build -t localhost:5000/test-backend:latest .

echo "Pushing image to K3d registry..."
docker push localhost:5000/test-backend:latest

# Deploy nginx ingress controller
echo "Deploying nginx ingress controller..."
kubectl apply -f "$K8S_DIR/nginx-ingress-controller.yaml"
kubectl apply -f "$K8S_DIR/nginx-ingressclass.yaml"

# Wait for controller to be ready
echo "Waiting for nginx ingress controller to be ready..."
kubectl wait --namespace kube-system \
  --for=condition=ready pod \
  --selector=app=nginx-ingress \
  --timeout=120s

# Deploy test backend
echo "Deploying test backend..."
kubectl apply -f "$K8S_DIR/test-backend.yaml"

# Wait for backend to be ready
echo "Waiting for test backend to be ready..."
kubectl wait --namespace default \
  --for=condition=ready pod \
  --selector=app=test-backend \
  --timeout=60s

# Deploy test ingress
echo "Deploying test ingress..."
kubectl apply -f "$K8S_DIR/test-ingress.yaml"

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Nginx Ingress Controller Status:"
kubectl get pods -n kube-system -l app=nginx-ingress
echo ""
echo "Test Backend Status:"
kubectl get pods -n default -l app=test-backend
echo ""
echo "Ingress Resources:"
kubectl get ingress -A
echo ""
echo "Access the service via:"
echo "  curl -H 'Host: test.local' http://localhost:30080/"
echo ""
echo "Run ./verify.sh to test the ingress configuration."
