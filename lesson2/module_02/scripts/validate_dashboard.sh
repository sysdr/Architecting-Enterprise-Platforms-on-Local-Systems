#!/bin/bash
set -euo pipefail

echo "=== Dashboard Validation ==="
echo ""

BACKEND_URL="http://localhost:8000"
FRONTEND_URL="http://localhost:5173"
FAILED=0

check_service() {
    local url=$1
    local name=$2
    
    echo -n "Checking $name... "
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo "✅ Running"
        return 0
    else
        echo "❌ Not accessible"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

check_metrics_update() {
    echo ""
    echo "Testing metrics update (3 requests over 6 seconds)..."
    
    local prev_used=""
    local changes=0
    
    for i in {1..3}; do
        sleep 2
        response=$(curl -s "${BACKEND_URL}/api/memory/stats")
        used=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['used_mb'])" 2>/dev/null)
        available=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['available_mb'])" 2>/dev/null)
        pressure=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin)['pressure_level'])" 2>/dev/null)
        
        echo "  Request $i: Used=${used}MB, Available=${available}MB, Pressure=${pressure}"
        
        if [ -n "$prev_used" ] && [ "$used" != "$prev_used" ]; then
            changes=$((changes + 1))
        fi
        prev_used=$used
    done
    
    if [ $changes -gt 0 ]; then
        echo "✅ Metrics are updating (detected $changes changes)"
    else
        echo "⚠️  Metrics appear static (may be normal if system is idle)"
    fi
}

check_api_endpoints() {
    echo ""
    echo "Testing API endpoints..."
    
    endpoints=(
        "/health:Health check"
        "/api/memory/stats:Memory stats"
        "/api/memory/recommendations:Recommendations"
    )
    
    for endpoint_info in "${endpoints[@]}"; do
        IFS=':' read -r endpoint name <<< "$endpoint_info"
        echo -n "  $name... "
        if curl -s -f "${BACKEND_URL}${endpoint}" > /dev/null 2>&1; then
            echo "✅"
        else
            echo "❌"
            FAILED=$((FAILED + 1))
        fi
    done
}

check_frontend_structure() {
    echo ""
    echo "Checking frontend structure..."
    
    html=$(curl -s "$FRONTEND_URL")
    
    checks=(
        "title:Nano-IDP Memory Monitor"
        "script:main.tsx"
        "div:root"
    )
    
    for check_info in "${checks[@]}"; do
        IFS=':' read -r type pattern <<< "$check_info"
        echo -n "  $type contains '$pattern'... "
        if echo "$html" | grep -q "$pattern"; then
            echo "✅"
        else
            echo "❌"
            FAILED=$((FAILED + 1))
        fi
    done
}

check_duplicate_services() {
    echo ""
    echo "Checking for duplicate services..."
    
    backend_count=$(pgrep -f "uvicorn.*main:app" | wc -l)
    frontend_count=$(pgrep -f "vite" | wc -l)
    
    echo "  Backend processes: $backend_count"
    echo "  Frontend processes: $frontend_count"
    
    if [ "$backend_count" -gt 1 ]; then
        echo "  ⚠️  Multiple backend processes detected!"
        FAILED=$((FAILED + 1))
    else
        echo "  ✅ Single backend process"
    fi
    
    if [ "$frontend_count" -gt 3 ]; then
        echo "  ⚠️  Too many frontend processes detected!"
        FAILED=$((FAILED + 1))
    else
        echo "  ✅ Frontend processes (normal: 1-3 for vite)"
    fi
}

# Run all checks
check_service "$BACKEND_URL/health" "Backend service"
check_service "$FRONTEND_URL" "Frontend service"
check_api_endpoints
check_metrics_update
check_frontend_structure
check_duplicate_services

echo ""
echo "============================================"
if [ $FAILED -eq 0 ]; then
    echo "✅ All validations passed!"
    echo ""
    echo "Dashboard URLs:"
    echo "  Frontend: $FRONTEND_URL"
    echo "  Backend API: $BACKEND_URL"
    echo "  API Docs: $BACKEND_URL/docs"
    exit 0
else
    echo "❌ $FAILED validation(s) failed"
    exit 1
fi

