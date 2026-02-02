#!/bin/bash
set -euo pipefail

echo "🧹 Cleaning up Lesson 4 resources"

# Remove test namespace
kubectl delete namespace cni-test --ignore-not-found=true

# Remove CNI monitor
kubectl delete namespace nano-idp --ignore-not-found=true

# Optional: Uninstall Cilium (will break cluster networking!)
read -p "⚠️  Remove Cilium? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    helm uninstall cilium -n kube-system
    echo "✅ Cilium removed (cluster networking is down!)"
fi

echo "✅ Cleanup complete"
