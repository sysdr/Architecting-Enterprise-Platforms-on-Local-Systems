#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
function log() { echo -e "${GREEN}[NANO]${NC} $1"; }
function error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

# Check if Cilium CLI is installed
if ! command -v cilium >/dev/null 2>&1; then
  log "Installing Cilium CLI..."
  CILIUM_VERSION="v0.15.0"
  curl -L "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_VERSION}/cilium-linux-amd64.tar.gz" | tar xz
  sudo mv cilium /usr/local/bin/
  log "Cilium CLI installed at /usr/local/bin/cilium"
fi

# Install Cilium in kube-proxy replacement mode
log "Installing Cilium CNI (kube-proxy replacement mode)..."
cilium install \
  --set kubeProxyReplacement=strict \
  --set operator.replicas=1 \
  --set hubble.enabled=false \
  --set prometheus.enabled=false \
  --set operator.prometheus.enabled=false

log "Waiting for Cilium to be ready (timeout: 5m)..."
cilium status --wait --wait-duration=5m

log "Cilium installation complete!"
kubectl get pods -n kube-system | grep cilium
