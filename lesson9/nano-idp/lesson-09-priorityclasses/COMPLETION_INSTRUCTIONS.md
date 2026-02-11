# Lesson 9 Setup Completion Instructions

## Current Status

✅ **Completed:**
- All files generated successfully by setup.sh
- PriorityClasses created and configured:
  - `platform-critical` (value: 1000000) - for CoreDNS, CNI
  - `platform-core` (value: 10000) - for Ingress, platform services
  - `tenant-default` (value: 0, global default) - for tenant workloads
- Platform components patched with PriorityClasses (CoreDNS)
- Kubernetes deployments, services, and ingress created
- No duplicate services detected
- Scripts are executable and ready

⚠️ **Pending:**
- Docker images need to be built and pushed to localhost:5000
- Pods are in `ImagePullBackOff` state waiting for images

## Fix Docker Access Issue

The Docker daemon is running but your current session doesn't have access. To fix this:

### Option 1: Refresh Group Membership (Recommended)
```bash
# Log out and log back in, OR
exec su -l $USER
# Then verify:
docker ps
```

### Option 2: Use newgrp
```bash
newgrp docker
docker ps
```

### Option 3: Use sudo (if configured)
```bash
sudo docker ps
```

## Build and Push Docker Images

Once Docker access is working, build and push the images:

```bash
cd /home/systemdr/git/Architecting-Enterprise-Platforms-on-Local-Systems/lesson9/nano-idp/lesson-09-priorityclasses

# Build backend
cd backend
docker build -t localhost:5000/priority-monitor-backend:latest .
docker push localhost:5000/priority-monitor-backend:latest
cd ..

# Build frontend
cd frontend
docker build -t localhost:5000/priority-monitor-frontend:latest .
docker push localhost:5000/priority-monitor-frontend:latest
cd ..
```

Or simply re-run the build script:
```bash
./build_and_deploy.sh
```

## Verify Deployment

After images are built, pods should start automatically. Verify with:

```bash
./verify.sh
```

Or manually check:
```bash
kubectl get pods -n priority-monitor
kubectl get services -n priority-monitor
kubectl get ingress -n priority-monitor
```

## Access the Dashboard

1. Add to `/etc/hosts`:
   ```
   127.0.0.1 priority.nano-idp.local
   ```

2. Access the dashboard:
   ```
   http://priority.nano-idp.local
   ```

## Test PriorityClasses

Deploy test workloads to see PriorityClasses in action:

```bash
cd scripts
./deploy-test-workloads.sh
```

## Summary

- ✅ Script verification: All files generated
- ✅ No duplicate services
- ✅ PriorityClasses configured
- ⚠️ Docker images need to be built (Docker access issue)
- ⏳ Dashboard validation pending (waiting for pods to start)

