#!/bin/bash
set -euo pipefail

echo "Deploying Nano-IDP Substrate (Lesson 1)..."
echo ""

# Check sudo access
if ! sudo -n true 2>/dev/null; then
  echo "Warning: This script requires sudo access. Some steps may fail."
  echo "Please ensure you have sudo privileges or run with: sudo -v"
  echo ""
fi

# Apply kernel tunings
echo "[1/3] Applying kernel tunings..."
if sudo cp configs/sysctl-k8s.conf /etc/sysctl.d/99-k8s-nanoidp.conf 2>/dev/null; then
  sudo sysctl --system >/dev/null 2>&1
  echo "  ✓ Kernel tunings applied"
else
  echo "  ⚠ Failed to apply kernel tunings (requires sudo)"
  echo "  You can manually apply: sudo cp configs/sysctl-k8s.conf /etc/sysctl.d/99-k8s-nanoidp.conf && sudo sysctl --system"
fi

# Configure Docker (optional - requires restart)
echo ""
echo "[2/3] Docker configuration..."
if [ ! -f /etc/docker/daemon.json ]; then
  echo "  No existing Docker config found."
  if [ -t 0 ]; then
    # Interactive mode
    read -p "  Apply Nano-IDP Docker config? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if sudo cp configs/daemon.json /etc/docker/daemon.json 2>/dev/null; then
        echo "  ✓ Docker config applied"
        echo "  ⚠ Docker restart required: sudo systemctl restart docker"
      else
        echo "  ⚠ Failed to apply Docker config (requires sudo)"
      fi
    fi
  else
    # Non-interactive mode - skip
    echo "  Skipping Docker config (non-interactive mode)"
    echo "  To apply manually: sudo cp configs/daemon.json /etc/docker/daemon.json"
  fi
else
  echo "  Existing Docker config detected. Backup and manual merge recommended."
fi

# Create cluster
echo ""
echo "[3/3] Creating K3d cluster..."
if command -v k3d >/dev/null 2>&1; then
  ./scripts/create_cluster.sh
else
  echo "  ⚠ k3d not installed. Skipping cluster creation."
  echo "  Install k3d: curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"
  echo "  Or run manually: ./scripts/create_cluster.sh"
fi

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
