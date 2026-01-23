#!/bin/bash
set -euo pipefail

echo "Verifying Nano-IDP Setup..."
echo ""

# Check Docker
echo "[1/4] Checking Docker configuration..."
if docker info | grep -q "Total Memory"; then
  echo "  ✓ Docker is running"
  docker info | grep "Total Memory"
else
  echo "  ✗ Docker check failed"
  exit 1
fi

# Check K3d cluster
echo ""
echo "[2/4] Checking K3d cluster..."
if kubectl cluster-info >/dev/null 2>&1; then
  echo "  ✓ Cluster is accessible"
  kubectl get nodes
else
  echo "  ✗ Cluster not found or not accessible"
  exit 1
fi

# Check pod status
echo ""
echo "[3/4] Checking system pods..."
not_ready=$(kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded -o json | jq '.items | length')
if [ "$not_ready" -eq 0 ]; then
  echo "  ✓ All pods are ready"
else
  echo "  ⚠ $not_ready pods are not ready"
  kubectl get pods -A --field-selector=status.phase!=Running
fi

# Memory check
echo ""
echo "[4/4] Memory allocation check..."
used_memory=$(free -m | awk 'NR==2 {print $3}')
total_memory=$(free -m | awk 'NR==2 {print $2}')
percent_used=$((used_memory * 100 / total_memory))

echo "  System: ${used_memory}MB / ${total_memory}MB (${percent_used}%)"

if [ "$percent_used" -lt 75 ]; then
  echo "  ✓ Memory usage within safe limits"
else
  echo "  ⚠ Memory usage is elevated (>${percent_used}%)"
fi

echo ""
echo "Verification complete!"
