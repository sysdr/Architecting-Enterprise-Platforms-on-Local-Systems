#!/bin/bash

# monitor.sh - Real-time memory monitoring for Nano-IDP

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_header() {
  clear
  echo -e "${BOLD}================================================${NC}"
  echo -e "${BOLD}   Nano-IDP Memory Monitor - 8GB Budget${NC}"
  echo -e "${BOLD}================================================${NC}"
  echo ""
}

get_memory_mb() {
  local kb=$1
  echo "scale=0; $kb / 1024" | bc
}

while true; do
  print_header
  
  # System Memory
  read -r total used free shared buff_cache available < <(free -k | awk 'NR==2 {print $2, $3, $4, $5, $6, $7}')
  
  total_mb=$(get_memory_mb "$total")
  used_mb=$(get_memory_mb "$used")
  free_mb=$(get_memory_mb "$free")
  available_mb=$(get_memory_mb "$available")
  
  used_percent=$(echo "scale=1; ($used * 100) / $total" | bc)
  
  echo -e "${BOLD}System Memory:${NC}"
  echo -e "  Total:     ${total_mb} MB"
  echo -e "  Used:      ${used_mb} MB (${used_percent}%)"
  echo -e "  Available: ${available_mb} MB"
  echo ""
  
  # Docker Memory Limit
  if docker info >/dev/null 2>&1; then
    docker_mem=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3}')
    echo -e "${BOLD}Docker:${NC}"
    echo -e "  Memory Limit: ${docker_mem}"
    echo ""
  fi
  
  # K8s Node
  if kubectl get nodes >/dev/null 2>&1; then
    echo -e "${BOLD}Kubernetes Node:${NC}"
    kubectl top nodes 2>/dev/null || echo "  (metrics not available yet)"
    echo ""
    
    echo -e "${BOLD}Top Memory Consumers (kube-system):${NC}"
    kubectl top pods -n kube-system --sort-by=memory 2>/dev/null | head -n 6 || echo "  (metrics not available yet)"
    echo ""
  fi
  
  # Budget Assessment
  if [ "$(echo "$used_percent < 50" | bc)" -eq 1 ]; then
    status_color=$GREEN
    status="HEALTHY"
  elif [ "$(echo "$used_percent < 75" | bc)" -eq 1 ]; then
    status_color=$YELLOW
    status="ELEVATED"
  else
    status_color=$RED
    status="CRITICAL"
  fi
  
  echo -e "${BOLD}Budget Status:${NC} ${status_color}${status}${NC}"
  echo ""
  echo "Press Ctrl+C to exit. Refreshing in 5 seconds..."
  
  sleep 5
done
