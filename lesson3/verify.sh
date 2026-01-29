#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
function log() { echo -e "${GREEN}[CHECK]${NC} $1"; }
function error() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

log "Verifying cluster is ready..."
kubectl get nodes | grep -q "Ready" || error "Node not ready"

log "Verifying NO Traefik pods..."
! kubectl get pods -n kube-system | grep -q traefik || error "Traefik found (should be disabled)"

log "Verifying NO Metrics Server pods..."
! kubectl get pods -n kube-system | grep -q metrics-server || error "Metrics Server found (should be disabled)"

log "Verifying Cilium is running..."
kubectl get pods -n kube-system | grep -q "cilium" || error "Cilium not found"
kubectl get pods -n kube-system -l k8s-app=cilium | grep -q "Running" || error "Cilium not running"

log "Verifying Cilium Operator is running..."
kubectl get pods -n kube-system -l name=cilium-operator | grep -q "Running" || error "Cilium Operator not running"

log "Creating test pod (nginx)..."
kubectl delete pod nginx-test 2>/dev/null || true
kubectl run nginx-test --image=nginx:alpine --port=80 --restart=Never

log "Waiting for test pod to be ready..."
kubectl wait --for=condition=ready pod/nginx-test --timeout=60s

POD_IP=$(kubectl get pod nginx-test -o jsonpath='{.status.podIP}')
log "Test pod IP: $POD_IP"

log "Testing pod connectivity (curl from debug pod)..."
kubectl run -i --rm --restart=Never debug-curl --image=alpine -- \
  sh -c "apk add -q curl && curl -s $POD_IP | grep -q nginx" || error "Pod connectivity failed"

log "Cleaning up test pods..."
kubectl delete pod nginx-test --grace-period=0 --force

echo ""
echo -e "${GREEN}✓ All checks passed!${NC}"
echo ""
echo "Memory footprint:"
docker stats --no-stream k3d-nano-substrate-server-0
