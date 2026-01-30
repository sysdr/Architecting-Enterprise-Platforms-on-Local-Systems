#!/bin/bash
set -euo pipefail

echo "=== Lesson 5: Complete Setup ==="

# Step 1: Apply sysctl
echo ""
echo "Step 1: Applying kernel tuning..."
./scripts/apply_sysctl.sh

# Step 2: Build and deploy
echo ""
echo "Step 2: Building and deploying monitor..."
cd "$(dirname "$0")"
./scripts/build_and_deploy.sh

# Step 3: Verify
echo ""
echo "Step 3: Running verification..."
sleep 5
./scripts/verify.sh

echo ""
echo "=== Setup Complete ==="
echo "Monitor running at: kubectl port-forward -n kube-system svc/kernel-monitor 8080:8080"
