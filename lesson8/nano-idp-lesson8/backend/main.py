from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from kubernetes_asyncio import client, config
from typing import List, Dict
from contextlib import asynccontextmanager
import os
import atexit

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Load Kubernetes config
    if os.path.exists("/var/run/secrets/kubernetes.io/serviceaccount"):
        config.load_incluster_config()
    else:
        await config.load_kube_config()
    yield
    # Shutdown: cleanup if needed
    pass

app = FastAPI(title="Storage Monitor", version="1.0.0", lifespan=lifespan)

# CORS for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
async def health():
    return {"status": "healthy", "service": "storage-monitor"}

@app.get("/api/storage/volumes")
async def get_volumes() -> List[Dict]:
    """List all PVs and their bound PVCs."""
    async with client.ApiClient() as api_client:
        v1 = client.CoreV1Api(api_client)
        
        pvs = await v1.list_persistent_volume()
        pvcs = await v1.list_persistent_volume_claim_for_all_namespaces()
        
        volumes = []
        for pv in pvs.items:
            bound_pvc = next(
                (p for p in pvcs.items if p.spec.volume_name == pv.metadata.name),
                None
            )
            
            pv_spec = pv.spec
            volumes.append({
                "name": pv.metadata.name,
                "capacity": pv.spec.capacity.get("storage", "unknown"),
                "status": pv.status.phase,
                "storageClass": pv.spec.storage_class_name,
                "claim": f"{bound_pvc.metadata.namespace}/{bound_pvc.metadata.name}" if bound_pvc else None,
                "hostPath": pv_spec.local.path if pv_spec.local else (
                    pv_spec.host_path.path if pv_spec.host_path else None
                ),
                "reclaimPolicy": pv_spec.persistent_volume_reclaim_policy
            })
        
        return volumes

@app.get("/api/storage/iostat")
async def get_iostat() -> Dict:
    """Parse /proc/diskstats for disk I/O metrics."""
    try:
        with open("/host/proc/diskstats") as f:
            lines = f.readlines()
    except FileNotFoundError:
        # Fallback if not mounted
        with open("/proc/diskstats") as f:
            lines = f.readlines()
    
    stats = {}
    for line in lines:
        fields = line.split()
        if len(fields) < 14:
            continue
        
        device = fields[2]
        # Filter for physical disks only
        if device.startswith(("sd", "nvme", "vd")):
            stats[device] = {
                "reads_completed": int(fields[3]),
                "sectors_read": int(fields[5]),
                "writes_completed": int(fields[7]),
                "sectors_written": int(fields[9]),
                "io_time_ms": int(fields[12])
            }
    
    return stats

@app.get("/api/storage/pvcs")
async def get_pvcs() -> List[Dict]:
    """List all PVCs across namespaces."""
    async with client.ApiClient() as api_client:
        v1 = client.CoreV1Api(api_client)
        pvcs = await v1.list_persistent_volume_claim_for_all_namespaces()
        
        claims = []
        for pvc in pvcs.items:
            claims.append({
                "name": pvc.metadata.name,
                "namespace": pvc.metadata.namespace,
                "status": pvc.status.phase,
                "volumeName": pvc.spec.volume_name,
                "storageClass": pvc.spec.storage_class_name,
                "capacity": pvc.status.capacity.get("storage") if pvc.status.capacity else None,
                "requested": pvc.spec.resources.requests.get("storage")
            })
        
        return claims
