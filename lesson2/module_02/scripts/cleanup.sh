#!/bin/bash
set -euo pipefail

echo "Cleaning up Nano-IDP Lesson 2 resources..."

kubectl delete -f manifests/frontend-deployment.yaml --ignore-not-found=true
kubectl delete -f manifests/backend-deployment.yaml --ignore-not-found=true
kubectl delete -f test/memory-pressure-pod.yaml --ignore-not-found=true
kubectl delete namespace nano-system --ignore-not-found=true

echo "✅ Cleanup complete"
