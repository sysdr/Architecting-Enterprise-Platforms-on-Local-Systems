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
