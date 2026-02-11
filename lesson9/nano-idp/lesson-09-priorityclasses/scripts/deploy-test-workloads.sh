#!/bin/bash
set -euo pipefail

echo "🚀 Deploying test workloads (memory bombs)..."

kubectl apply -f ../k8s/test-workloads.yaml

echo "⏳ Waiting for pods to start..."
sleep 5

echo ""
echo "📊 Pod status:"
kubectl get pods -l app=memory-test -o wide

echo ""
echo "💾 Memory usage (if metrics-server available):"
kubectl top pods -l app=memory-test 2>/dev/null || echo "  (metrics-server not available)"

echo ""
echo "To create more memory pressure:"
echo "  for i in {3..5}; do"
echo "    kubectl run memory-bomb-\$i --image=polinux/stress \\"
echo "      --requests='memory=512Mi' --limits='memory=512Mi' \\"
echo "      -- stress --vm 1 --vm-bytes 500M --vm-hang 0"
echo "  done"
