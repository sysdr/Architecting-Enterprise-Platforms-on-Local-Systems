# Priority Monitor Dashboard - Access URLs

## 🎯 Primary Dashboard URL

### Option 1: Via Ingress (Recommended - Once pods are running)

**URL:** `http://priority.nano-idp.local`

**Setup Required:**
1. Add to `/etc/hosts`:
   ```bash
   echo "127.0.0.1 priority.nano-idp.local" | sudo tee -a /etc/hosts
   ```
   Or for WSL2/K3d:
   ```bash
   echo "172.19.0.2 priority.nano-idp.local" | sudo tee -a /etc/hosts
   ```

2. Access via:
   - **http://priority.nano-idp.local** (main dashboard)
   - **http://priority.nano-idp.local/api/priorityclasses** (API endpoint)

**Note:** This requires the pods to be running (currently in ImagePullBackOff)

---

### Option 2: Via Port-Forward (Works Immediately)

**Setup:**
```bash
# Forward frontend service
kubectl port-forward -n priority-monitor svc/priority-monitor-frontend 8080:80

# In another terminal, forward backend service
kubectl port-forward -n priority-monitor svc/priority-monitor-backend 8081:8080
```

**URL:** `http://localhost:8080`

**Note:** The frontend will try to call `/api/*` which needs to be proxied. You may need to modify the frontend to point to `http://localhost:8081` for API calls, or use a reverse proxy.

---

### Option 3: Via NodePort (Direct Access)

**URL:** `http://localhost:30080`

**Host Header Required:**
```bash
curl -H "Host: priority.nano-idp.local" http://localhost:30080
```

Or use a browser extension to set the Host header, or add to `/etc/hosts`:
```bash
echo "127.0.0.1 priority.nano-idp.local" | sudo tee -a /etc/hosts
```

Then access: `http://priority.nano-idp.local:30080`

---

### Option 4: Via LoadBalancer (Traefik)

**URL:** `http://172.19.0.2` (with Host header: `priority.nano-idp.local`)

**Note:** The ingress uses `ingressClassName: nginx`, so it's configured for nginx-ingress, not traefik.

---

## 📊 API Endpoints

Once the backend is running, you can access:

- **Health Check:** `http://priority.nano-idp.local/api/health`
- **Priority Classes:** `http://priority.nano-idp.local/api/priorityclasses`
- **Pod Priorities:** `http://priority.nano-idp.local/api/pods/priorities`
- **Statistics:** `http://priority.nano-idp.local/api/stats`

---

## 🔧 Current Status

**Pods Status:**
- Backend: `ImagePullBackOff` (waiting for Docker image)
- Frontend: `ImagePullBackOff` (waiting for Docker image)

**Services:**
- Frontend: `ClusterIP 10.43.134.49:80`
- Backend: `ClusterIP 10.43.87.188:8080`

**Ingress:**
- Host: `priority.nano-idp.local`
- Class: `nginx`
- Status: Configured but no address assigned yet

---

## 🚀 Quick Start (Once Images are Built)

1. **Add hostname to /etc/hosts:**
   ```bash
   echo "127.0.0.1 priority.nano-idp.local" | sudo tee -a /etc/hosts
   ```

2. **Access dashboard:**
   ```
   http://priority.nano-idp.local
   ```

3. **Or use port-forward for immediate access:**
   ```bash
   kubectl port-forward -n priority-monitor svc/priority-monitor-frontend 8080:80
   ```
   Then open: `http://localhost:8080`

---

## 📝 Ingress Configuration

The ingress is configured in `k8s/frontend-deployment.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: priority-monitor
  namespace: priority-monitor
spec:
  ingressClassName: nginx
  rules:
  - host: priority.nano-idp.local
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: priority-monitor-backend
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: priority-monitor-frontend
            port:
              number: 80
```

