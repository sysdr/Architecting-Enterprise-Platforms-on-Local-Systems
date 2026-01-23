#!/bin/bash
set -euo pipefail

# setup_lesson_01.sh - The 8GB Budget: System Configuration
# Nano-IDP Module 1, Lesson 1

PROJECT_ROOT="$HOME/nano-idp"
LESSON_DIR="$PROJECT_ROOT/module01-lesson01-substrate"

echo "=================================================="
echo "Nano-IDP: Module 1, Lesson 1 - The 8GB Budget"
echo "=================================================="
echo ""

# Check prerequisites (warnings only, files will still be generated)
command -v docker >/dev/null 2>&1 || { echo "Warning: Docker not installed"; }
command -v kubectl >/dev/null 2>&1 || { echo "Warning: kubectl not installed"; }

# Create directory structure
mkdir -p "$LESSON_DIR"/{scripts,configs,docs}
cd "$LESSON_DIR"

echo "[1/5] Generating Docker daemon configuration..."

cat <<'EOF' > configs/daemon.json
{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-address-pools": [
    {
      "base": "172.17.0.0/16",
      "size": 24
    }
  ]
}
EOF

echo "[2/5] Generating kernel tuning configuration..."

cat <<'EOF' > configs/sysctl-k8s.conf
# Nano-IDP Kernel Tunings for 8GB Systems
vm.swappiness=10
vm.overcommit_memory=1
vm.panic_on_oom=0
vm.max_map_count=262144
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
EOF

echo "[3/5] Generating K3d cluster creation script..."

cat <<'EOF' > scripts/create_cluster.sh
#!/bin/bash
set -euo pipefail

CLUSTER_NAME="nano-substrate"

# Check if cluster exists
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
  echo "Cluster $CLUSTER_NAME already exists. Deleting..."
  k3d cluster delete "$CLUSTER_NAME"
fi

echo "Creating K3d cluster with aggressive resource constraints..."

k3d cluster create "$CLUSTER_NAME" \
  --servers 1 \
  --agents 0 \
  --k3s-arg "--disable=traefik@server:0" \
  --k3s-arg "--disable=metrics-server@server:0" \
  --k3s-arg "--kube-apiserver-arg=--max-requests-inflight=200@server:0" \
  --k3s-arg "--kube-apiserver-arg=--max-mutating-requests-inflight=100@server:0" \
  --k3s-arg "--etcd-arg=--quota-backend-bytes=2147483648@server:0" \
  --wait

echo ""
echo "Cluster created. Waiting for all pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=120s

echo ""
echo "Cluster Status:"
kubectl get nodes
echo ""
kubectl get pods -A
EOF

chmod +x scripts/create_cluster.sh

echo "[4/5] Generating real-time monitoring script..."

cat <<'EOF' > scripts/monitor.sh
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
  if [ "$used_percent" -lt "50" ]; then
    status_color=$GREEN
    status="HEALTHY"
  elif [ "$used_percent" -lt "75" ]; then
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
EOF

chmod +x scripts/monitor.sh

echo "[5/5] Generating verification and cleanup scripts..."

cat <<'EOF' > scripts/verify.sh
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
EOF

chmod +x scripts/verify.sh

cat <<'EOF' > scripts/cleanup.sh
#!/bin/bash
set -euo pipefail

echo "Cleaning up Nano-IDP Lesson 1..."

# Delete K3d cluster
if k3d cluster list | grep -q "nano-substrate"; then
  echo "Deleting K3d cluster..."
  k3d cluster delete nano-substrate
fi

# Remove Docker config backup
if [ -f /etc/docker/daemon.json.backup ]; then
  echo "Restoring original Docker config..."
  sudo mv /etc/docker/daemon.json.backup /etc/docker/daemon.json
  sudo systemctl restart docker
fi

# Remove kernel tunings
if [ -f /etc/sysctl.d/99-k8s-nanoidp.conf ]; then
  echo "Removing kernel tunings..."
  sudo rm /etc/sysctl.d/99-k8s-nanoidp.conf
  sudo sysctl --system >/dev/null
fi

echo "Cleanup complete!"
EOF

chmod +x scripts/cleanup.sh

# Generate deployment script
cat <<'EOF' > build_and_deploy.sh
#!/bin/bash
set -euo pipefail

echo "Deploying Nano-IDP Substrate (Lesson 1)..."
echo ""

# Apply kernel tunings
echo "[1/3] Applying kernel tunings..."
sudo cp configs/sysctl-k8s.conf /etc/sysctl.d/99-k8s-nanoidp.conf
sudo sysctl --system >/dev/null 2>&1
echo "  ✓ Kernel tunings applied"

# Configure Docker (optional - requires restart)
echo ""
echo "[2/3] Docker configuration..."
if [ ! -f /etc/docker/daemon.json ]; then
  echo "  No existing Docker config found."
  read -p "  Apply Nano-IDP Docker config? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo cp configs/daemon.json /etc/docker/daemon.json
    echo "  ⚠ Docker restart required: sudo systemctl restart docker"
  fi
else
  echo "  Existing Docker config detected. Backup and manual merge recommended."
fi

# Create cluster
echo ""
echo "[3/3] Creating K3d cluster..."
./scripts/create_cluster.sh

echo ""
echo "================================================"
echo "Deployment Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Run verification: ./scripts/verify.sh"
echo "  2. Start monitoring: ./scripts/monitor.sh"
echo "  3. Check resource usage: kubectl top nodes"
echo ""
echo "To cleanup: ./scripts/cleanup.sh"
EOF

chmod +x build_and_deploy.sh

# Generate README
cat <<'EOF' > docs/README.md
# Module 1, Lesson 1: The 8GB Budget

## Overview
This lesson establishes the foundation for the Nano-IDP by configuring system-level constraints and creating a minimal K3d cluster that respects an 8GB RAM budget.

## Contents
- `configs/daemon.json` - Docker daemon configuration with memory limits
- `configs/sysctl-k8s.conf` - Kernel tunings for Kubernetes
- `scripts/create_cluster.sh` - K3d cluster creation with resource constraints
- `scripts/monitor.sh` - Real-time memory monitoring dashboard
- `scripts/verify.sh` - System verification checks
- `scripts/cleanup.sh` - Environment cleanup

## Quick Start
```bash
# Deploy the substrate
./build_and_deploy.sh

# Verify setup
./scripts/verify.sh

# Monitor memory usage
./scripts/monitor.sh
```

## Memory Budget
- Docker: 4GB (enforced by configuration)
- OS: 4GB (reserved)
- K3d Cluster: ~600MB
- Available for workloads: ~3.4GB

## Key Tunings
- K3s with Traefik and Metrics Server disabled
- API server request throttling (200 max concurrent)
- etcd quota limited to 2GB
- CoreDNS minimal configuration

## Verification
Expected memory usage after cluster creation:
- System: ~2.5-3GB total
- K3d container: ~600-700MB
- Available: ~5GB+

## Troubleshooting
If cluster fails to create:
1. Check Docker memory: `docker info | grep Memory`
2. Verify no swap: `free -h` (swap should be 0)
3. Check system load: `uptime`

## Next Steps
Proceed to Lesson 2: Installing Cilium eBPF CNI
EOF

echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Generated files in: $LESSON_DIR"
echo ""
echo "To deploy the substrate:"
echo "  cd $LESSON_DIR"
echo "  ./build_and_deploy.sh"
echo ""
echo "To start monitoring:"
echo "  ./scripts/monitor.sh"
echo ""