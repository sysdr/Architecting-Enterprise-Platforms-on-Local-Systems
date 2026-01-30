#!/bin/bash
set -euo pipefail

echo "=== Cleaning Up Kernel Monitor ==="

kubectl delete -f k8s/deployment.yaml --ignore-not-found=true

echo "Waiting for cleanup..."
kubectl wait --for=delete pod -l app=kernel-monitor -n kube-system --timeout=30s || true

echo "=== Cleanup Complete ==="
