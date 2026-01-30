#!/bin/bash
set -euo pipefail

echo "=== Verifying Kernel Monitor ==="

# Port forward in background
kubectl port-forward -n kube-system svc/kernel-monitor 8080:8080 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

# Cleanup on exit
trap "kill $PF_PID 2>/dev/null || true" EXIT

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s http://localhost:8080/health | jq .

echo ""
echo "2. Testing metrics endpoint..."
curl -s http://localhost:8080/metrics/maps | jq .

echo ""
echo "3. Testing sysctl status..."
curl -s http://localhost:8080/sysctl/apply | jq .

echo ""
echo "4. Testing Prometheus metrics..."
curl -s http://localhost:8080/metrics | head -20

echo ""
echo "5. Checking pod resource usage..."
kubectl top pod -n kube-system -l app=kernel-monitor

echo ""
echo "=== Verification Complete ==="
