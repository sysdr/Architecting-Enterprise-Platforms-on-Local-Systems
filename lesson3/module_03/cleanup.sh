#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
function log() { echo -e "${GREEN}[CLEANUP]${NC} $1"; }

log "Destroying nano-substrate cluster..."
k3d cluster delete nano-substrate 2>/dev/null || true

log "Removing any test pods..."
kubectl delete pod nginx-test --grace-period=0 --force 2>/dev/null || true

log "Cleanup complete!"
