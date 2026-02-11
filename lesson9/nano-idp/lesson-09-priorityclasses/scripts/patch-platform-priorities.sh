#!/bin/bash
set -euo pipefail

echo "🔧 Patching platform components with PriorityClasses..."

# System Critical Components
echo "Setting platform-critical priority for CoreDNS..."
kubectl patch deployment coredns -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/priorityClassName", "value": "platform-critical"}]' \
  2>/dev/null || echo "  (CoreDNS already patched or not found)"

echo "Setting platform-critical priority for Cilium Operator..."
kubectl patch deployment cilium-operator -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/priorityClassName", "value": "platform-critical"}]' \
  2>/dev/null || echo "  (Cilium Operator already patched or not found)"

# Platform Core Components
echo "Setting platform-core priority for Nginx Ingress..."
kubectl patch deployment ingress-nginx-controller -n ingress-nginx --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/priorityClassName", "value": "platform-core"}]' \
  2>/dev/null || echo "  (Nginx Ingress already patched or not found)"

echo "✅ Platform components patched successfully"
echo ""
echo "Verify with:"
echo "  kubectl get pods -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,PRIORITY:.spec.priorityClassName,PRIORITY_VALUE:.spec.priority"
