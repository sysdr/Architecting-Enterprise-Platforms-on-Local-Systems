#!/bin/bash
set -euo pipefail

echo "=== Memory Monitor API Tests ==="
echo ""

BASE_URL="http://localhost:8000"
FAILED=0

test_endpoint() {
    local endpoint=$1
    local expected_status=${2:-200}
    local description=$3
    
    echo -n "Testing $description... "
    response=$(curl -s -w "\n%{http_code}" "${BASE_URL}${endpoint}")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq "$expected_status" ]; then
        echo "✅ PASS (HTTP $http_code)"
        if [ -n "$body" ] && [ "$body" != "null" ]; then
            echo "$body" | python3 -m json.tool > /dev/null 2>&1 && echo "   Valid JSON response"
        fi
        return 0
    else
        echo "❌ FAIL (HTTP $http_code, expected $expected_status)"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

test_json_field() {
    local endpoint=$1
    local field=$2
    local description=$3
    
    echo -n "Testing $description... "
    response=$(curl -s "${BASE_URL}${endpoint}")
    
    if echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if '$field' in data else 1)" 2>/dev/null; then
        value=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['$field'])" 2>/dev/null)
        echo "✅ PASS (field '$field' = $value)"
        return 0
    else
        echo "❌ FAIL (field '$field' not found)"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Test health endpoint
test_endpoint "/health" 200 "Health check endpoint"

# Test memory stats endpoint
test_endpoint "/api/memory/stats" 200 "Memory stats endpoint"

# Test recommendations endpoint
test_endpoint "/api/memory/recommendations" 200 "Recommendations endpoint"

# Test JSON structure of memory stats
test_json_field "/api/memory/stats" "total_mb" "Memory stats has total_mb field"
test_json_field "/api/memory/stats" "available_mb" "Memory stats has available_mb field"
test_json_field "/api/memory/stats" "used_mb" "Memory stats has used_mb field"
test_json_field "/api/memory/stats" "pressure_level" "Memory stats has pressure_level field"
test_json_field "/api/memory/stats" "swappiness" "Memory stats has swappiness field"

# Test recommendations structure
test_json_field "/api/memory/recommendations" "recommendations" "Recommendations has recommendations array"
test_json_field "/api/memory/recommendations" "current_stats" "Recommendations has current_stats object"

echo ""
if [ $FAILED -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ $FAILED test(s) failed"
    exit 1
fi

