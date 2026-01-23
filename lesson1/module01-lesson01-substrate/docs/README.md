# Module 1, Lesson 1: The 8GB Budget

## Overview
This lesson establishes the foundation for the Nano-IDP by configuring system-level constraints and creating a minimal K3d cluster that respects an 8GB RAM budget.

## Contents
- `configs/daemon.json` - Docker daemon configuration with memory limits
- `configs/sysctl-k8s.conf` - Kernel tunings for Kubernetes
- `scripts/create_cluster.sh` - K3d cluster creation with resource constraints
- `scripts/monitor.sh` - Real-time memory monitoring dashboard
- `scripts/verify.sh` - System verification checks
- `scripts/cleanup.sh` - Environment cleanup

## Quick Start
```bash
# Deploy the substrate
./build_and_deploy.sh

# Verify setup
./scripts/verify.sh

# Monitor memory usage
./scripts/monitor.sh
```

## Memory Budget
- Docker: 4GB (enforced by configuration)
- OS: 4GB (reserved)
- K3d Cluster: ~600MB
- Available for workloads: ~3.4GB

## Key Tunings
- K3s with Traefik and Metrics Server disabled
- API server request throttling (200 max concurrent)
- etcd quota limited to 2GB
- CoreDNS minimal configuration

## Verification
Expected memory usage after cluster creation:
- System: ~2.5-3GB total
- K3d container: ~600-700MB
- Available: ~5GB+

## Troubleshooting
If cluster fails to create:
1. Check Docker memory: `docker info | grep Memory`
2. Verify no swap: `free -h` (swap should be 0)
3. Check system load: `uptime`

## Next Steps
Proceed to Lesson 2: Installing Cilium eBPF CNI
