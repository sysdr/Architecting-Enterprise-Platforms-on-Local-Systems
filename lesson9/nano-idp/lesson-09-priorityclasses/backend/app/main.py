"""
Priority Monitor API - FastAPI backend for PriorityClass visibility
Memory footprint: ~40MB
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from kubernetes import client, config
from kubernetes.client.rest import ApiException
from pydantic import BaseModel
from typing import List, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Priority Monitor", version="1.0.0")

# CORS - allow frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load K8s config
try:
    config.load_incluster_config()
    logger.info("Loaded in-cluster Kubernetes config")
except:
    config.load_kube_config()
    logger.info("Loaded local Kubernetes config")

v1 = client.CoreV1Api()
scheduling_v1 = client.SchedulingV1Api()


class PriorityClassInfo(BaseModel):
    name: str
    value: int
    global_default: bool
    description: Optional[str]
    preemption_policy: Optional[str]


class PodPriorityInfo(BaseModel):
    pod_name: str
    namespace: str
    priority_class: str
    priority_value: int
    memory_usage: Optional[str]
    status: str


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}


@app.get("/api/priorityclasses", response_model=List[PriorityClassInfo])
async def list_priority_classes():
    """List all PriorityClasses in the cluster"""
    try:
        priority_classes = scheduling_v1.list_priority_class()
        
        results = []
        for pc in priority_classes.items:
            results.append(PriorityClassInfo(
                name=pc.metadata.name,
                value=pc.value,
                global_default=pc.global_default or False,
                description=pc.description,
                preemption_policy=pc.preemption_policy
            ))
        
        return sorted(results, key=lambda x: x.value, reverse=True)
    
    except ApiException as e:
        logger.error(f"K8s API error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/pods/priorities", response_model=List[PodPriorityInfo])
async def get_pod_priorities():
    """Get priority information for all running pods"""
    try:
        # Build priority class lookup
        priority_classes = {
            pc.metadata.name: pc.value 
            for pc in scheduling_v1.list_priority_class().items
        }
        
        # Default for pods without explicit priority class
        if "tenant-default" in priority_classes:
            default_priority = priority_classes["tenant-default"]
        else:
            default_priority = 0
        
        results = []
        pods = v1.list_pod_for_all_namespaces()
        
        for pod in pods.items:
            priority_class = pod.spec.priority_class_name or "tenant-default"
            priority_value = priority_classes.get(priority_class, default_priority)
            
            # Try to get memory usage from metrics server
            memory_usage = None
            try:
                custom_api = client.CustomObjectsApi()
                metrics = custom_api.get_namespaced_custom_object(
                    group="metrics.k8s.io",
                    version="v1beta1",
                    namespace=pod.metadata.namespace,
                    plural="pods",
                    name=pod.metadata.name
                )
                if metrics.get("containers"):
                    memory_usage = metrics["containers"][0]["usage"].get("memory")
            except:
                pass  # Metrics server might not be available
            
            results.append(PodPriorityInfo(
                pod_name=pod.metadata.name,
                namespace=pod.metadata.namespace,
                priority_class=priority_class,
                priority_value=priority_value,
                memory_usage=memory_usage,
                status=pod.status.phase
            ))
        
        return sorted(results, key=lambda x: x.priority_value, reverse=True)
    
    except ApiException as e:
        logger.error(f"K8s API error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/stats")
async def get_priority_stats():
    """Get aggregate statistics about priority class usage"""
    try:
        pods = v1.list_pod_for_all_namespaces()
        priority_classes = {
            pc.metadata.name: pc.value 
            for pc in scheduling_v1.list_priority_class().items
        }
        
        stats = {}
        for pod in pods.items:
            priority_class = pod.spec.priority_class_name or "tenant-default"
            
            if priority_class not in stats:
                stats[priority_class] = {
                    "count": 0,
                    "priority_value": priority_classes.get(priority_class, 0),
                    "running": 0,
                    "pending": 0,
                    "failed": 0
                }
            
            stats[priority_class]["count"] += 1
            
            if pod.status.phase == "Running":
                stats[priority_class]["running"] += 1
            elif pod.status.phase == "Pending":
                stats[priority_class]["pending"] += 1
            elif pod.status.phase == "Failed":
                stats[priority_class]["failed"] += 1
        
        return stats
    
    except ApiException as e:
        logger.error(f"K8s API error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
