#!/bin/bash
set -euo pipefail

echo "🔍 Verifying Cilium Installation"

# Check Cilium pods
echo "📦 Cilium Pods:"
kubectl -n kube-system get pods -l k8s-app=cilium

# Check Cilium operator
echo ""
echo "⚙️  Cilium Operator:"
kubectl -n kube-system get pods -l name=cilium-operator

# Get memory usage
echo ""
echo "💾 Memory Usage:"
kubectl -n kube-system top pod -l k8s-app=cilium 2>/dev/null || echo "⚠️  Metrics Server not available"

# Get Cilium status
CILIUM_POD=$(kubectl -n kube-system get pods -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "🔬 Cilium Status:"
kubectl -n kube-system exec $CILIUM_POD -- cilium status --brief

echo ""
echo "✅ Verification complete"
