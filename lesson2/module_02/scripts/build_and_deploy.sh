#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Building backend image..."
docker build -t localhost:5000/memory-monitor-backend:latest ./backend
docker push localhost:5000/memory-monitor-backend:latest

echo "Building frontend image..."
cd frontend
docker build -t localhost:5000/memory-monitor-frontend:latest .
docker push localhost:5000/memory-monitor-frontend:latest
cd ..

echo "Deploying to K3d..."
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/backend-deployment.yaml
kubectl apply -f manifests/frontend-deployment.yaml

echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=memory-monitor-backend -n nano-system --timeout=120s
kubectl wait --for=condition=ready pod -l app=memory-monitor-frontend -n nano-system --timeout=120s

echo ""
echo "✅ Deployment complete!"
echo "📊 Access the dashboard at: http://localhost:30080"
echo "🔍 Check pod status: kubectl get pods -n nano-system"
