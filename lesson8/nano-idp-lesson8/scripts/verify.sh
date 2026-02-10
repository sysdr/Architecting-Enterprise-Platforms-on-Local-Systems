#!/bin/bash
set -e

NAMESPACE="storage-demo"

echo "🔍 Verification Script for Lesson 8"
echo "===================================="

echo ""
echo "1. Checking StorageClass..."
kubectl get storageclass local-ssd -o wide

echo ""
echo "2. Checking PersistentVolumes..."
kubectl get pv

echo ""
echo "3. Checking PersistentVolumeClaims..."
kubectl get pvc -n ${NAMESPACE}

echo ""
echo "4. Checking Postgres StatefulSet..."
kubectl get statefulset -n ${NAMESPACE}
kubectl get pods -n ${NAMESPACE} -l app=postgres

echo ""
echo "5. Testing Postgres Connection..."
kubectl exec -n ${NAMESPACE} postgres-test-0 -- psql -U postgres -c "\l" 2>/dev/null && echo "✅ Postgres is accessible" || echo "❌ Postgres connection failed"

echo ""
echo "6. Checking Storage Monitor..."
kubectl get deployment -n ${NAMESPACE} storage-monitor
kubectl get pods -n ${NAMESPACE} -l app=storage-monitor

echo ""
echo "7. Testing Storage Monitor API..."
kubectl port-forward -n ${NAMESPACE} svc/storage-monitor 8080:80 &
PF_PID=$!
sleep 3

curl -s http://localhost:8080/api/health | grep -q "healthy" && echo "✅ API is healthy" || echo "❌ API health check failed"

kill $PF_PID 2>/dev/null

echo ""
echo "8. Memory Usage Check..."
kubectl top pod -n ${NAMESPACE} --no-headers | awk '{print $1 ": " $3}'

echo ""
echo "✅ Verification complete!"
echo ""
echo "To access Storage Monitor UI:"
echo "  kubectl port-forward -n ${NAMESPACE} svc/storage-monitor 8080:80"
echo "  Open http://localhost:8080"
