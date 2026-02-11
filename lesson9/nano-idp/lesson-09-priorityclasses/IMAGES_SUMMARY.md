# Docker Images for Priority Monitor Project

## Required Docker Images

### 1. Backend Image
**Image Name:** `localhost:5000/priority-monitor-backend:latest`

**Dockerfile:**
```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app/ ./app/

# Run with minimal resources
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "1"]
```

**Base Image:** `python:3.12-slim`
**Size:** ~150-200MB (estimated)
**Port:** 8080
**Memory Footprint:** ~40MB

**Dependencies:**
- fastapi==0.104.1
- uvicorn==0.24.0
- kubernetes==28.1.0
- pydantic==2.5.0

---

### 2. Frontend Image
**Image Name:** `localhost:5000/priority-monitor-frontend:latest`

**Dockerfile:**
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Base Images:** 
- Builder: `node:18-alpine`
- Runtime: `nginx:alpine`
**Size:** ~50-80MB (estimated, multi-stage build)
**Port:** 80
**Memory Footprint:** ~20-30MB

**Dependencies:**
- react: ^18.2.0
- react-dom: ^18.2.0
- axios: ^1.6.2
- vite: ^5.0.8 (dev)
- typescript: ^5.3.3 (dev)

---

## Image Build Commands

### Build Backend:
```bash
cd backend
docker build -t localhost:5000/priority-monitor-backend:latest .
docker push localhost:5000/priority-monitor-backend:latest
```

### Build Frontend:
```bash
cd frontend
docker build -t localhost:5000/priority-monitor-frontend:latest .
docker push localhost:5000/priority-monitor-frontend:latest
```

### Or use the automated script:
```bash
./build_and_deploy.sh
```

---

## Current Status

**Images Status:** ❌ Not built yet
- Backend pod: `ImagePullBackOff` (waiting for image)
- Frontend pod: `ImagePullBackOff` (waiting for image)

**Registry:** `localhost:5000` (local Docker registry)

---

## UI Preview

A visual preview of the frontend UI has been created at:
- `ui_preview.html` - Open in browser to see the dashboard design

The UI features:
- Dark theme with green accent colors (#00ff88)
- Real-time statistics cards
- Priority class table with color-coded badges
- Pod priority assignments table
- Auto-refresh functionality (every 5 seconds)

**Color Scheme:**
- 🔴 Red badges: Critical priority classes (system-node-critical, system-cluster-critical, platform-critical)
- 🟠 Orange badges: Core platform services (platform-core)
- ⚫ Gray badges: Tenant workloads (tenant-default)
- 🟢 Green badges: Running status
- 🟡 Yellow badges: Pending status

