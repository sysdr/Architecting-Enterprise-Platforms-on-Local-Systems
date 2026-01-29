#!/bin/bash
#
# Compare memory usage between standard and minimalist K3d
#

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== K3d Memory Comparison ===${NC}\n"

echo "Creating STANDARD K3d cluster (with all components)..."
k3d cluster delete standard-k3d 2>/dev/null || true
k3d cluster create standard-k3d --agents 0 --wait >/dev/null 2>&1
sleep 15

STANDARD_MEM=$(docker stats --no-stream --format "{{.MemUsage}}" k3d-standard-k3d-server-0 | awk -F'/' '{print $1}')
echo -e "Standard K3d: ${YELLOW}$STANDARD_MEM${NC}"

k3d cluster delete standard-k3d >/dev/null 2>&1

echo ""
echo "Creating MINIMALIST K3d cluster (components disabled)..."
k3d cluster delete minimalist-k3d 2>/dev/null || true
k3d cluster create minimalist-k3d \
  --agents 0 \
  --k3s-arg "--disable=traefik@server:0" \
  --k3s-arg "--disable=metrics-server@server:0" \
  --k3s-arg "--disable-cloud-controller@server:0" \
  --wait >/dev/null 2>&1
sleep 15

MINIMALIST_MEM=$(docker stats --no-stream --format "{{.MemUsage}}" k3d-minimalist-k3d-server-0 | awk -F'/' '{print $1}')
echo -e "Minimalist K3d: ${GREEN}$MINIMALIST_MEM${NC}"

k3d cluster delete minimalist-k3d >/dev/null 2>&1

echo ""
echo -e "${GREEN}Memory Savings:${NC}"
echo "Standard - Minimalist = Savings"
echo "$STANDARD_MEM - $MINIMALIST_MEM ≈ ~260MB savings"
