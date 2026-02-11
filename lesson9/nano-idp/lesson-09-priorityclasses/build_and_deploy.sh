#!/bin/bash
set -euo pipefail

echo "🏗️  Building and deploying Lesson 9: PriorityClasses"

# Check prerequisites
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl."
    exit 1
fi

# Check Docker access
if ! docker ps &>/dev/null; then
    echo "⚠️  Warning: Cannot access Docker daemon."
    echo "   This might be a permissions issue. Try:"
    echo "   1. Log out and log back in (to refresh group membership)"
    echo "   2. Or run: newgrp docker"
    echo "   3. Or use: sudo usermod -aG docker $USER && newgrp docker"
    echo ""
    echo "   Attempting to continue anyway..."
    DOCKER_ACCESSIBLE=false
else
    DOCKER_ACCESSIBLE=true
fi

# Configuration
BACKEND_IMAGE="localhost:5000/priority-monitor-backend:latest"
FRONTEND_IMAGE="localhost:5000/priority-monitor-frontend:latest"

# Step 1: Apply PriorityClasses
echo "📋 Step 1: Applying PriorityClasses..."
kubectl apply -f k8s/priorityclasses.yaml
sleep 2

# Step 2: Patch existing platform components
echo "🔧 Step 2: Patching platform components..."
./scripts/patch-platform-priorities.sh
sleep 5

# Step 3: Build backend
echo "🐍 Step 3: Building Python backend..."
if [ "$DOCKER_ACCESSIBLE" = true ]; then
    cd backend
    docker build -t "${BACKEND_IMAGE}" . || (echo "❌ Docker build failed" && exit 1)
    docker push "${BACKEND_IMAGE}" || (echo "❌ Docker push failed" && exit 1)
    cd ..
else
    echo "⚠️  Skipping Docker build (Docker not accessible)"
    echo "   Please build images manually:"
    echo "   cd backend && docker build -t ${BACKEND_IMAGE} . && docker push ${BACKEND_IMAGE}"
    echo "   Then re-run this script or continue with: kubectl apply -f k8s/backend-deployment.yaml"
fi

# Step 4: Build frontend
echo "⚛️  Step 4: Building React frontend..."
cd frontend

# Create production build
cat > Dockerfile <<'DOCKERFILE'
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
DOCKERFILE

cat > nginx.conf <<'NGINX'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://priority-monitor-backend:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINX

if [ "$DOCKER_ACCESSIBLE" = true ]; then
    docker build -t "${FRONTEND_IMAGE}" . || (echo "❌ Docker build failed" && exit 1)
    docker push "${FRONTEND_IMAGE}" || (echo "❌ Docker push failed" && exit 1)
else
    echo "⚠️  Skipping Docker build (Docker not accessible)"
    echo "   Please build images manually:"
    echo "   docker build -t ${FRONTEND_IMAGE} . && docker push ${FRONTEND_IMAGE}"
fi
cd ..

# Step 5: Deploy application
echo "🚀 Step 5: Deploying application..."
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml

# Wait for deployment
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=priority-monitor-backend -n priority-monitor --timeout=120s
kubectl wait --for=condition=ready pod -l app=priority-monitor-frontend -n priority-monitor --timeout=120s

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 View priority assignments:"
echo "  kubectl get pods -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,PRIORITY:.spec.priorityClassName,VALUE:.spec.priority"
echo ""
echo "🌐 Access the UI (after adding to /etc/hosts):"
echo "  http://priority.nano-idp.local"
echo ""
echo "🧪 Deploy test workloads:"
echo "  cd scripts && ./deploy-test-workloads.sh"
