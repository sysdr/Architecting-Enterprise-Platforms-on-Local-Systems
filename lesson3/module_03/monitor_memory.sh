#!/bin/bash
#
# Real-time memory monitoring using /proc and docker stats
#

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}=== Nano-IDP Memory Monitor ===${NC}\n"

# System memory
echo -e "${CYAN}System Memory:${NC}"
awk '/MemTotal:/ {printf "  Total: %.2f GB\n", $2/1024/1024}
     /MemAvailable:/ {printf "  Available: %.2f GB\n", $2/1024/1024}
     /SwapTotal:/ {printf "  Swap Total: %.2f GB\n", $2/1024/1024}
     /SwapFree:/ {printf "  Swap Free: %.2f GB\n", $2/1024/1024}' /proc/meminfo

echo ""

# Docker container stats
echo -e "${CYAN}K3d Container Memory:${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" \
  $(docker ps --filter "name=k3d-nano" --format "{{.ID}}")

echo ""

# Kubernetes pods memory (from cgroups, if available)
if kubectl get pods -A >/dev/null 2>&1; then
  echo -e "${CYAN}Kubernetes Pods:${NC}"
  kubectl top pods -A 2>/dev/null || echo "  (kubectl top not available - metrics-server disabled)"
fi

echo ""
echo -e "${GREEN}Total Infrastructure Estimate:${NC}"
docker stats --no-stream --format "  {{.MemUsage}}" \
  $(docker ps --filter "name=k3d-nano" --format "{{.ID}}") | \
  awk -F'/' '{print $1}' | \
  awk '{sum += $1} END {printf "  ~%.0f MB\n", sum}'
