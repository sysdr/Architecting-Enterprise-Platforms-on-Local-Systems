#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Verifying Ingress Lite Configuration"
echo "=========================================="

INGRESS_PORT=30080
TEST_HOST="test.local"
FAILED=0

# Function to test endpoint
test_endpoint() {
    local path="$1"
    local expected_status="${2:-200}"
    local description="$3"
    
    echo -n "Testing $description... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $TEST_HOST" "http://localhost:$INGRESS_PORT$path" || true)
    
    if [ "$response" = "$expected_status" ]; then
        echo "✓ PASS (HTTP $response)"
    else
        echo "✗ FAIL (Expected HTTP $expected_status, got $response)"
        FAILED=$((FAILED + 1))
    fi
}

# Check if nginx ingress controller is running
echo "Checking nginx ingress controller..."
if kubectl get pods -n kube-system -l app=nginx-ingress | grep -q Running; then
    echo "✓ Nginx ingress controller is running"
else
    echo "✗ Nginx ingress controller is not running"
    FAILED=$((FAILED + 1))
fi

# Check if test backend is running
echo "Checking test backend..."
if kubectl get pods -n default -l app=test-backend | grep -q Running; then
    echo "✓ Test backend is running"
else
    echo "✗ Test backend is not running"
    FAILED=$((FAILED + 1))
fi

# Check memory usage
echo ""
echo "Memory Usage:"
kubectl top pod -n kube-system -l app=nginx-ingress 2>/dev/null || echo "Metrics not available yet (this is normal)"
kubectl top pod -n default -l app=test-backend 2>/dev/null || echo "Metrics not available yet (this is normal)"

# Check worker processes
echo ""
echo "Nginx Worker Processes:"
CONTROLLER_POD=$(kubectl get pod -n kube-system -l app=nginx-ingress -o jsonpath='{.items[0].metadata.name}')
if [ -n "$CONTROLLER_POD" ]; then
    WORKER_COUNT=$(kubectl exec -n kube-system "$CONTROLLER_POD" -- ps aux | grep "nginx: worker process" | grep -v grep | wc -l)
    if [ "$WORKER_COUNT" -eq 1 ]; then
        echo "✓ Nginx running with 1 worker process (optimal)"
    else
        echo "✗ Nginx running with $WORKER_COUNT worker processes (expected 1)"
        FAILED=$((FAILED + 1))
    fi
fi

# Test HTTP endpoints
echo ""
echo "Testing HTTP Endpoints:"
test_endpoint "/health" 200 "Health endpoint"
test_endpoint "/" 200 "Root endpoint"
test_endpoint "/echo/test" 200 "Echo endpoint"

# Test response content
echo ""
echo "Sample Response:"
curl -s -H "Host: $TEST_HOST" "http://localhost:$INGRESS_PORT/" | jq '.' 2>/dev/null || echo "Response received (jq not available for formatting)"

# Final summary
echo ""
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo "✓ All verifications passed!"
    echo "=========================================="
    exit 0
else
    echo "✗ $FAILED verification(s) failed"
    echo "=========================================="
    exit 1
fi
