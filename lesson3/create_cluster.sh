#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'
function log() { echo -e "${GREEN}[NANO]${NC} $1"; }

CLUSTER_NAME="nano-substrate"

# Destroy existing cluster (idempotent)
log "Destroying existing cluster '$CLUSTER_NAME'..."
k3d cluster delete "$CLUSTER_NAME" 2>/dev/null || true
sleep 2

# Create stripped K3d cluster
log "Creating minimalist K3d cluster..."
k3d cluster create "$CLUSTER_NAME" \
  --agents 0 \
  --k3s-arg "--disable=traefik@server:0" \
  --k3s-arg "--disable=metrics-server@server:0" \
  --k3s-arg "--disable-cloud-controller@server:0" \
  --k3s-arg "--flannel-backend=none@server:0" \
  --k3s-arg "--disable-network-policy@server:0" \
  --wait

log "Cluster created. Waiting 10s for K3s to stabilize..."
sleep 10

kubectl get nodes
