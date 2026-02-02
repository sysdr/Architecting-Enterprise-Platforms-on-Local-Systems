#!/bin/bash
set -euo pipefail

echo "🧪 Testing Cilium NetworkPolicy Enforcement"

NAMESPACE="cni-test"

# Create test namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "📦 Deploying test workloads..."

# Deploy nginx server
kubectl -n $NAMESPACE run nginx --image=nginx:alpine --port=80 --labels="app=nginx" \
  --overrides='{"spec":{"containers":[{"name":"nginx","image":"nginx:alpine","resources":{"requests":{"memory":"32Mi","cpu":"50m"},"limits":{"memory":"64Mi","cpu":"100m"}}}]}}'

# Deploy client pod
kubectl -n $NAMESPACE run client --image=alpine --restart=Never \
  --overrides='{"spec":{"containers":[{"name":"client","image":"alpine","command":["sh","-c","sleep 3600"],"resources":{"requests":{"memory":"16Mi","cpu":"25m"},"limits":{"memory":"32Mi","cpu":"50m"}}}]}}'

# Wait for pods
echo "⏳ Waiting for pods to be ready..."
kubectl -n $NAMESPACE wait --for=condition=ready pod/nginx --timeout=60s
kubectl -n $NAMESPACE wait --for=condition=ready pod/client --timeout=60s

# Test 1: Verify connectivity BEFORE policy
echo ""
echo "🔓 Test 1: Connectivity BEFORE NetworkPolicy"
NGINX_IP=$(kubectl -n $NAMESPACE get pod nginx -o jsonpath='{.status.podIP}')
if kubectl -n $NAMESPACE exec client -- wget -qO- --timeout=3 http://$NGINX_IP 2>/dev/null | grep -q "Welcome to nginx"; then
    echo "✅ Client can reach nginx (expected)"
else
    echo "❌ Client cannot reach nginx (unexpected!)"
    exit 1
fi

# Apply deny-all NetworkPolicy
echo ""
echo "🔒 Applying deny-all NetworkPolicy..."
cat <<POLICY | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: $NAMESPACE
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
  - Ingress
POLICY

sleep 3  # Allow policy to propagate

# Test 2: Verify connectivity AFTER policy
echo ""
echo "🚫 Test 2: Connectivity AFTER NetworkPolicy"
NGINX_IP=$(kubectl -n $NAMESPACE get pod nginx -o jsonpath='{.status.podIP}')
if kubectl -n $NAMESPACE exec client -- wget -qO- --timeout=3 http://$NGINX_IP 2>/dev/null; then
    echo "❌ Client can still reach nginx (policy not enforced!)"
    exit 1
else
    echo "✅ Client blocked by NetworkPolicy (expected)"
fi

# Test 3: Apply allow policy and verify
echo ""
echo "✅ Test 3: Applying allow policy..."
cat <<POLICY | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-client
  namespace: $NAMESPACE
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          run: client
    ports:
    - protocol: TCP
      port: 80
POLICY

sleep 3

NGINX_IP=$(kubectl -n $NAMESPACE get pod nginx -o jsonpath='{.status.podIP}')
if kubectl -n $NAMESPACE exec client -- wget -qO- --timeout=3 http://$NGINX_IP 2>/dev/null | grep -q "Welcome to nginx"; then
    echo "✅ Client can reach nginx after allow policy (expected)"
else
    echo "❌ Client still blocked (unexpected!)"
    exit 1
fi

echo ""
echo "🎉 All NetworkPolicy tests passed!"
echo "🔍 eBPF is enforcing policies correctly"

# Show Cilium policy verification
CILIUM_POD=$(kubectl -n kube-system get pods -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')
echo ""
echo "📊 Cilium Policy Status:"
kubectl -n kube-system exec $CILIUM_POD -- cilium endpoint list | grep $NAMESPACE || true
