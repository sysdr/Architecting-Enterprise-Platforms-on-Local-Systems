# Lesson 8: Storage on a Budget

## Quick Start

1. **Recreate K3d with Volume Mapping:**
```bash
k3d cluster delete nano-k8s
sudo mkdir -p /data/k3d-volumes
k3d cluster create nano-k8s \
  --volume /data/k3d-volumes:/var/lib/rancher/k3s/storage@all \
  --k3s-arg "--disable=traefik,metrics-server@server:*" \
  --registry-create k3d-registry.localhost:5000
```

2. **Deploy Everything:**
```bash
./scripts/build_and_deploy.sh
kubectl apply -f k8s/
```

3. **Verify:**
```bash
./scripts/verify.sh
```

4. **Access UI:**
```bash
kubectl port-forward -n storage-demo svc/storage-monitor 8080:80
# Open http://localhost:8080
```

## Architecture

- **Backend**: FastAPI + kubernetes-asyncio (60MB)
- **Frontend**: React + TanStack Query + Vite
- **Storage**: K3d local-path-provisioner mapped to host SSD
- **Test Workload**: PostgreSQL 15 Alpine (240MB image)

## Memory Budget

- local-path-provisioner: 35MB
- Postgres test pod: 128-256MB
- Storage Monitor: 64-128MB
- **Total**: ~300MB for full stack

## Cleanup
```bash
./scripts/cleanup.sh
```
