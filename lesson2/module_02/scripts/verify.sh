#!/bin/bash
set -euo pipefail

echo "=== Memory Monitor Verification ==="
echo ""

echo "1. Checking pod status..."
kubectl get pods -n nano-system

echo ""
echo "2. Checking resource usage..."
kubectl top pods -n nano-system 2>/dev/null || echo "Metrics server not available"

echo ""
echo "3. Testing backend API..."
BACKEND_POD=$(kubectl get pod -n nano-system -l app=memory-monitor-backend -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n nano-system pod/${BACKEND_POD} 8000:8000 &
PF_PID=$!
sleep 3

curl -s http://localhost:8000/health | jq '.' || echo "API not responding"
curl -s http://localhost:8000/api/memory/stats | jq '.' || echo "Memory stats not available"

kill $PF_PID 2>/dev/null || true

echo ""
echo "4. Frontend accessible at:"
echo "   http://localhost:30080"

echo ""
echo "5. To test memory pressure:"
echo "   kubectl apply -f test/memory-pressure-pod.yaml"
