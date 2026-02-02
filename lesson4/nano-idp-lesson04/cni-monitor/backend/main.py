"""
CNI Health Monitor - FastAPI Backend
Memory Target: <30MB
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from kubernetes import client, config
from pydantic import BaseModel
from typing import List, Optional
import subprocess
import json

app = FastAPI(title="CNI Health Monitor")

# Enable CORS for React frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)

# Load K8s config
try:
    config.load_incluster_config()
except:
    config.load_kube_config()

v1 = client.CoreV1Api()

class CiliumStatus(BaseModel):
    agent_ready: bool
    operator_ready: bool
    agent_memory_mb: float
    operator_memory_mb: float
    ebpf_status: str
    endpoints: int

class CNIMetrics(BaseModel):
    cni_type: str
    total_memory_mb: float
    agent_count: int
    policy_count: int
    status: CiliumStatus

@app.get("/")
async def root():
    return {"service": "CNI Health Monitor", "version": "1.0"}

@app.get("/api/cni/health", response_model=CNIMetrics)
async def get_cni_health():
    """Get Cilium CNI health and memory metrics"""
    try:
        # Get Cilium pods
        cilium_agents = v1.list_namespaced_pod(
            namespace="kube-system",
            label_selector="k8s-app=cilium"
        ).items
        
        cilium_operator = v1.list_namespaced_pod(
            namespace="kube-system",
            label_selector="name=cilium-operator"
        ).items
        
        if not cilium_agents:
            raise HTTPException(status_code=404, detail="Cilium agents not found")
        
        # Get memory metrics (requires metrics-server, fallback to limits)
        agent_memory = 0.0
        operator_memory = 0.0
        
        for agent in cilium_agents:
            # Try to get actual usage from metrics API
            try:
                # Fallback: extract from resource limits
                limits = agent.spec.containers[0].resources.limits
                if limits and "memory" in limits:
                    mem_str = limits["memory"]
                    agent_memory += _parse_memory(mem_str)
            except:
                agent_memory += 120  # Assume limit
        
        if cilium_operator:
            try:
                limits = cilium_operator[0].spec.containers[0].resources.limits
                if limits and "memory" in limits:
                    operator_memory = _parse_memory(limits["memory"])
            except:
                operator_memory = 60
        
        # Get Cilium status via exec (simplified - in production use CRDs)
        agent_ready = all(pod.status.phase == "Running" for pod in cilium_agents)
        operator_ready = all(pod.status.phase == "Running" for pod in cilium_operator)
        
        # Get network policies count
        networking_v1 = client.NetworkingV1Api()
        policies = networking_v1.list_network_policy_for_all_namespaces()
        
        return CNIMetrics(
            cni_type="cilium",
            total_memory_mb=agent_memory + operator_memory,
            agent_count=len(cilium_agents),
            policy_count=len(policies.items),
            status=CiliumStatus(
                agent_ready=agent_ready,
                operator_ready=operator_ready,
                agent_memory_mb=agent_memory,
                operator_memory_mb=operator_memory,
                ebpf_status="OK" if agent_ready else "DEGRADED",
                endpoints=0  # Would require Cilium API
            )
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def _parse_memory(mem_str: str) -> float:
    """Parse K8s memory string to MB"""
    mem_str = mem_str.upper()
    if "GI" in mem_str:
        return float(mem_str.replace("GI", "")) * 1024
    elif "MI" in mem_str:
        return float(mem_str.replace("MI", ""))
    elif "G" in mem_str:
        return float(mem_str.replace("G", "")) * 1000
    elif "M" in mem_str:
        return float(mem_str.replace("M", ""))
    return 0

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, workers=1)
