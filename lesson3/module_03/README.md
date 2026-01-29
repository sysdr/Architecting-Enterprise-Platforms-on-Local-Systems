# Lesson 03: K3d Minimalist Boot

## What This Does

Creates a K3d cluster with:
- **Traefik disabled** (saves ~180MB)
- **Metrics Server disabled** (saves ~40MB)
- **Cloud Controller Manager disabled** (saves ~30MB)
- **Flannel disabled** (replaced with Cilium, saves ~80MB)

Total savings: **~260MB** (46% reduction from standard K3d)

## Quick Start
```bash
# 1. Create stripped cluster
./create_cluster.sh

# 2. Install Cilium CNI
./install_cilium.sh

# 3. Verify everything works
./verify.sh

# 4. Monitor memory usage
./monitor_memory.sh
```

## Scripts

- `create_cluster.sh` - Creates minimalist K3d cluster
- `install_cilium.sh` - Installs Cilium as CNI + kube-proxy replacement
- `verify.sh` - Runs connectivity tests
- `monitor_memory.sh` - Real-time memory monitoring
- `compare_memory.sh` - Compare standard vs minimalist memory usage
- `cleanup.sh` - Destroys cluster

## Memory Budget

Target: **~305MB** for K3d server (vs ~565MB standard)

Breakdown:
- K3s Server (stripped): ~280MB
- CoreDNS: ~25MB

## Verification

After running `verify.sh`, you should see:
- ✓ Node ready
- ✓ No Traefik pods
- ✓ No Metrics Server pods
- ✓ Cilium running
- ✓ Pod connectivity working

## Homework

Reduce K3d server memory from 305MB to <280MB by:
1. Tuning CoreDNS cache size
2. Disabling K3s event logging
3. Adjusting API server flags

Measure with: `docker stats k3d-nano-substrate-server-0`
