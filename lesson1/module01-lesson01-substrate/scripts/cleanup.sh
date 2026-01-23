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
