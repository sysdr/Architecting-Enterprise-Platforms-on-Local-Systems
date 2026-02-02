# Lesson 4: Tuned Cilium CNI Installation

## Quick Start

1. Install Cilium:
```bash
   cd scripts
   ./install_cilium.sh
```

2. Verify installation:
```bash
   ./verify.sh
```

3. Test network policies:
```bash
   ./test_network_policy.sh
```

## Memory Budget

- Cilium Agents: ~120MB (vs 512MB default)
- Cilium Operator: ~60MB (vs 300MB default)
- **Total: ~180MB (vs 850MB default)**

## Files Generated

- `cilium-config/cilium-values.yaml` - Tuned Helm values
- `scripts/install_cilium.sh` - Installation script
- `scripts/test_network_policy.sh` - NetworkPolicy tests
- `scripts/verify.sh` - Health checks
- `cni-monitor/` - Python + React monitoring dashboard

## Next Steps

Run the CNI monitor dashboard (optional):
```bash
cd cni-monitor/backend
docker build -t localhost:5000/cni-monitor-backend .
docker push localhost:5000/cni-monitor-backend
kubectl create namespace nano-idp
kubectl apply -f ../k8s/backend-deployment.yaml
```
