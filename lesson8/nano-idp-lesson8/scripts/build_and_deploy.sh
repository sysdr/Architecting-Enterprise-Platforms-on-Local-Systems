#!/bin/bash
set -e

echo "🔨 Building Backend..."
cd backend
docker build -t localhost:5000/storage-monitor-backend:latest .
docker push localhost:5000/storage-monitor-backend:latest

echo "✅ Backend built and pushed to local registry"
echo ""
echo "📦 Apply K8s manifests with:"
echo "  kubectl apply -f k8s/"
