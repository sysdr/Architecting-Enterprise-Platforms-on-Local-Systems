#!/bin/bash
# Helper script to fix Docker access issues

echo "🔧 Attempting to fix Docker access..."

# Method 1: Try newgrp in a subshell
if command -v newgrp &>/dev/null; then
    echo "Trying newgrp docker..."
    newgrp docker <<EOF
docker ps > /dev/null 2>&1 && echo "✅ Docker access works with newgrp" || echo "❌ newgrp didn't help"
EOF
fi

# Method 2: Check if we can use sudo
if command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
    echo "Trying sudo docker..."
    sudo docker ps > /dev/null 2>&1 && echo "✅ Can use sudo docker" || echo "❌ sudo requires password"
fi

# Method 3: Check group membership
echo ""
echo "Current user groups:"
groups
echo ""
echo "Docker socket permissions:"
stat -c "%a %U:%G" /var/run/docker.sock 2>/dev/null || echo "Cannot access socket"
echo ""
echo "If you're in the docker group but still can't access:"
echo "  1. Log out and log back in"
echo "  2. Or run: exec su -l $USER"
echo "  3. Or run: newgrp docker"

