#!/bin/bash
set -euo pipefail

echo "🔍 Verifying Lesson 9 Installation..."
echo ""

# Check PriorityClasses
echo "1. Checking PriorityClasses..."
PRIORITY_CLASSES=$(kubectl get priorityclasses -o name | wc -l)
if [ "$PRIORITY_CLASSES" -ge 3 ]; then
    echo "  ✅ Found $PRIORITY_CLASSES PriorityClasses"
    kubectl get priorityclasses
else
    echo "  ❌ Expected at least 3 PriorityClasses, found $PRIORITY_CLASSES"
    exit 1
fi

echo ""
echo "2. Checking platform component priorities..."
COREDNS_PRIORITY=$(kubectl get pod -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[0].spec.priorityClassName}' 2>/dev/null || echo "none")
echo "  CoreDNS priority: $COREDNS_PRIORITY"

CILIUM_PRIORITY=$(kubectl get pod -n kube-system -l app.kubernetes.io/name=cilium-operator -o jsonpath='{.items[0].spec.priorityClassName}' 2>/dev/null || echo "none")
echo "  Cilium priority: $CILIUM_PRIORITY"

INGRESS_PRIORITY=$(kubectl get pod -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].spec.priorityClassName}' 2>/dev/null || echo "none")
echo "  Ingress priority: $INGRESS_PRIORITY"

echo ""
echo "3. Checking Priority Monitor deployment..."
BACKEND_STATUS=$(kubectl get deployment priority-monitor-backend -n priority-monitor -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
FRONTEND_STATUS=$(kubectl get deployment priority-monitor-frontend -n priority-monitor -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")

# Handle empty values
BACKEND_STATUS=${BACKEND_STATUS:-0}
FRONTEND_STATUS=${FRONTEND_STATUS:-0}

if [ "$BACKEND_STATUS" -eq 1 ] && [ "$FRONTEND_STATUS" -eq 1 ]; then
    echo "  ✅ Backend: $BACKEND_STATUS/1 replicas ready"
    echo "  ✅ Frontend: $FRONTEND_STATUS/1 replicas ready"
else
    echo "  ❌ Backend: $BACKEND_STATUS/1 replicas ready"
    echo "  ❌ Frontend: $FRONTEND_STATUS/1 replicas ready"
    echo "  ℹ️  Note: Pods may be waiting for Docker images to be built"
fi

echo ""
echo "4. Testing API endpoints..."
BACKEND_POD=$(kubectl get pod -n priority-monitor -l app=priority-monitor-backend -o jsonpath='{.items[0].metadata.name}')

echo "  Testing /health..."
kubectl exec -n priority-monitor "$BACKEND_POD" -- curl -s http://localhost:8080/health | grep -q "healthy" && echo "    ✅ Health check passed" || echo "    ❌ Health check failed"

echo "  Testing /api/priorityclasses..."
kubectl exec -n priority-monitor "$BACKEND_POD" -- curl -s http://localhost:8080/api/priorityclasses | grep -q "platform-critical" && echo "    ✅ PriorityClasses endpoint working" || echo "    ❌ PriorityClasses endpoint failed"

echo ""
echo "5. Resource usage:"
kubectl top pods -n priority-monitor 2>/dev/null || echo "  (metrics-server not available)"

echo ""
echo "✅ Verification complete!"
echo ""
echo "📚 Next steps:"
echo "  - Add priority.nano-idp.local to /etc/hosts"
echo "  - Open http://priority.nano-idp.local in browser"
echo "  - Run ./scripts/deploy-test-workloads.sh to test OOM behavior"
