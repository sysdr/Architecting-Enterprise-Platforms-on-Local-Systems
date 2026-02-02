#!/bin/bash
set -euo pipefail

echo "📦 Installing Tuned Cilium CNI"

# Check prerequisites
if ! command -v helm &> /dev/null; then
    echo "❌ Helm not found. Install: https://helm.sh/docs/intro/install/"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo "❌ No Kubernetes cluster detected"
    exit 1
fi

# Backup existing CNI (if Flannel)
echo "🔄 Backing up existing CNI configuration..."
kubectl -n kube-system get ds kube-flannel -o yaml > flannel-backup.yaml 2>/dev/null || true

# Remove Flannel
echo "🗑️  Removing Flannel..."
kubectl -n kube-system delete ds kube-flannel --ignore-not-found=true
kubectl -n kube-system delete cm kube-flannel-cfg --ignore-not-found=true

# Add Cilium repo
echo "📚 Adding Cilium Helm repository..."
helm repo add cilium https://helm.cilium.io/ 2>/dev/null || true
helm repo update

# Install Cilium with tuned values
echo "🚀 Installing Cilium (this may take 2-3 minutes)..."
helm install cilium cilium/cilium \
  --version 1.14.5 \
  --namespace kube-system \
  --values ../cilium-config/cilium-values.yaml

# Wait for Cilium to be ready
echo "⏳ Waiting for Cilium agents to be ready..."
kubectl -n kube-system rollout status ds/cilium --timeout=300s

echo "✅ Cilium installed successfully"
echo ""
echo "🔍 Verify with: kubectl -n kube-system exec -it <cilium-pod> -- cilium status"
