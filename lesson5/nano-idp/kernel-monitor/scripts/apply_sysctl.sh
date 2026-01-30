#!/bin/bash
set -euo pipefail

echo "=== Applying Kernel Tuning ==="

SYSCTL_FILE="/etc/sysctl.d/99-k3d-maps.conf"
TARGET_VALUE=524288

# Check current value
CURRENT=$(cat /proc/sys/vm/max_map_count)
echo "Current vm.max_map_count: $CURRENT"
echo "Target vm.max_map_count: $TARGET_VALUE"

if [ "$CURRENT" -ge "$TARGET_VALUE" ]; then
    echo "✓ Tuning already applied"
    exit 0
fi

# Apply tuning (requires sudo)
echo ""
echo "Applying persistent sysctl configuration..."
echo "This requires sudo access."

sudo tee "$SYSCTL_FILE" > /dev/null <<SYSCTL
# Nano-IDP Kernel Tuning
# Support for container-dense workloads on 8GB systems
# Date: $(date +%Y-%m-%d)

# Maximum number of memory map areas a process may have
# Default: 65530
# Nano-IDP: 524288 (supports ~30 mixed pods)
vm.max_map_count=$TARGET_VALUE
SYSCTL

# Apply immediately
sudo sysctl -p "$SYSCTL_FILE"

# Verify
NEW_VALUE=$(cat /proc/sys/vm/max_map_count)
echo ""
echo "✓ Applied successfully"
echo "New value: $NEW_VALUE"
echo "Configuration persisted to: $SYSCTL_FILE"
