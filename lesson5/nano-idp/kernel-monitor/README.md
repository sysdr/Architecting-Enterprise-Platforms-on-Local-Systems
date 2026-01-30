# Lesson 5: Kernel Tuning - Memory Map Monitor

## Overview
Lightweight monitoring tool for tracking `vm.max_map_count` utilization.

**Resource Budget:**
- Memory: 32-64MB
- CPU: 25-100m
- No external dependencies

## Quick Start

### 1. Apply Kernel Tuning
```bash
./scripts/apply_sysctl.sh
```

### 2. Build and Deploy
```bash
./scripts/build_and_deploy.sh
```

### 3. Verify
```bash
./scripts/verify.sh
```

### 4. Access Metrics
```bash
kubectl port-forward -n kube-system svc/kernel-monitor 8080:8080
curl http://localhost:8080/metrics/maps | jq .
```

## Endpoints

- `GET /health` - Health check
- `GET /metrics/maps` - JSON metrics with top consumers
- `GET /metrics` - Prometheus-compatible metrics
- `GET /sysctl/apply` - Check tuning status

## Cleanup
```bash
./scripts/cleanup.sh
```

## Memory Impact
- **Before:** 0MB (no monitoring)
- **After:** ~45MB (Python + FastAPI)
- **Net Cost:** 45MB for cluster-wide visibility
