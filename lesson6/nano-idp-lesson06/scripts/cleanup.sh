#!/bin/bash
set -euo pipefail

echo "🧹 Cleaning up..."

kubectl delete pod memory-hog --ignore-not-found=true
kubectl delete namespace monitoring --ignore-not-found=true
k3d cluster delete nano-idp || true

echo "✅ Cleanup complete!"
