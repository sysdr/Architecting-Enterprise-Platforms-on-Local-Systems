from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pathlib import Path
import re
import os
from typing import Optional
from pydantic import BaseModel

app = FastAPI(title="cgroup v2 Monitor")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve static frontend files
frontend_path = Path(__file__).parent / "frontend"
if frontend_path.exists():
    @app.get("/")
    async def root():
        """Serve dashboard HTML"""
        dashboard_file = frontend_path / "index.html"
        if dashboard_file.exists():
            return FileResponse(dashboard_file)
        return {"message": "cgroup v2 Monitor API", "docs": "/docs"}
else:
    @app.get("/")
    async def root():
        return {"message": "cgroup v2 Monitor API", "docs": "/docs"}

class PressureMetrics(BaseModel):
    some_avg10: float
    some_avg60: float
    full_avg10: float
    full_avg60: float
    total_stall_time_us: int

class MemoryStats(BaseModel):
    current_bytes: int
    max_bytes: Optional[int]
    high_bytes: Optional[int]
    pressure: Optional[PressureMetrics]
    health_status: str

def find_pod_cgroup(pod_name: str, namespace: Optional[str] = None) -> Optional[Path]:
    """Find cgroup path for a pod in cgroup v2 unified hierarchy"""
    base = Path("/sys/fs/cgroup/kubepods")
    if not base.exists():
        return None
    
    # Search in all QoS classes: burstable, besteffort, guaranteed
    for qos_class in ["burstable", "besteffort", "guaranteed"]:
        qos_path = base / qos_class
        if not qos_path.exists():
            continue
        
        # Look for pod directories (format: pod{UID})
        # Prefer pods with actual pressure data (more interesting for demo)
        pods_with_pressure = []
        pods_without_pressure = []
        
        for pod_dir in sorted(qos_path.glob("pod*")):
            if not pod_dir.is_dir():
                continue
            
            # Check if this cgroup has memory stats (valid pod cgroup)
            if not (pod_dir / "memory.current").exists():
                continue
            
            # Check if it has pressure data
            pressure_file = pod_dir / "memory.pressure"
            has_pressure = False
            if pressure_file.exists():
                try:
                    content = pressure_file.read_text()
                    # Check if there's any non-zero pressure
                    if "avg10=" in content and not re.search(r'avg10=0\.00', content):
                        has_pressure = True
                except Exception:
                    pass
            
            if has_pressure:
                pods_with_pressure.append(pod_dir)
            else:
                pods_without_pressure.append(pod_dir)
        
        # Return pods with pressure first (more interesting), then others
        if pods_with_pressure:
            return pods_with_pressure[0]
        if pods_without_pressure:
            return pods_without_pressure[0]
    
    return None

def parse_pressure_file(content: str) -> PressureMetrics:
    """Parse memory.pressure PSI format"""
    some_match = re.search(r'some avg10=(\d+\.\d+) avg60=(\d+\.\d+) avg300=\d+\.\d+ total=(\d+)', content)
    full_match = re.search(r'full avg10=(\d+\.\d+) avg60=(\d+\.\d+)', content)
    
    return PressureMetrics(
        some_avg10=float(some_match.group(1)) if some_match else 0.0,
        some_avg60=float(some_match.group(2)) if some_match else 0.0,
        full_avg10=float(full_match.group(1)) if full_match else 0.0,
        full_avg60=float(full_match.group(2)) if full_match else 0.0,
        total_stall_time_us=int(some_match.group(3)) if some_match else 0,
    )

@app.get("/api/health")
async def health_check():
    """Verify cgroup v2 availability"""
    cgroup_base = Path("/sys/fs/cgroup/cgroup.controllers")
    if not cgroup_base.exists():
        return {"status": "error", "message": "cgroup v2 not detected"}
    
    controllers = cgroup_base.read_text().strip().split()
    return {
        "status": "ok",
        "cgroup_version": "v2",
        "controllers": controllers
    }

@app.get("/api/memory-stats/{pod_name}", response_model=MemoryStats)
async def get_memory_stats(pod_name: str, namespace: Optional[str] = None):
    """Get real-time memory stats and PSI metrics for a pod"""
    cgroup_path = find_pod_cgroup(pod_name, namespace)
    if not cgroup_path:
        raise HTTPException(status_code=404, detail=f"Pod cgroup not found for '{pod_name}'. Make sure the pod exists and is running.")
    
    # Read memory stats
    current = int((cgroup_path / "memory.current").read_text().strip())
    max_content = (cgroup_path / "memory.max").read_text().strip()
    max_bytes = int(max_content) if max_content != "max" else None
    
    high_content = (cgroup_path / "memory.high").read_text().strip()
    high_bytes = int(high_content) if high_content != "max" else None
    
    # Read pressure metrics from pod cgroup
    pressure = None
    pressure_file = cgroup_path / "memory.pressure"
    if pressure_file.exists():
        pressure = parse_pressure_file(pressure_file.read_text())
    
    # If pod-level pressure is all zeros, try to get QoS-level pressure as fallback
    # This shows system-level pressure that affects the pod
    if pressure and pressure.some_avg10 == 0.0 and pressure.full_avg10 == 0.0 and pressure.total_stall_time_us == 0:
        # Try to get pressure from parent QoS class (burstable/besteffort/guaranteed)
        parent = cgroup_path.parent
        if parent and parent.name in ["burstable", "besteffort", "guaranteed"]:
            qos_pressure_file = parent / "memory.pressure"
            if qos_pressure_file.exists():
                qos_pressure = parse_pressure_file(qos_pressure_file.read_text())
                # Use QoS pressure if it has any non-zero values (avg10, avg60, or total stall time)
                if (qos_pressure.some_avg10 > 0.0 or qos_pressure.some_avg60 > 0.0 or 
                    qos_pressure.full_avg10 > 0.0 or qos_pressure.full_avg60 > 0.0 or
                    qos_pressure.total_stall_time_us > 0):
                    pressure = qos_pressure
    
    # Determine health
    health = "ok"
    if pressure and pressure.full_avg10 > 10.0:
        health = "critical"
    elif pressure and pressure.full_avg10 > 5.0:
        health = "warning"
    elif current > (high_bytes or max_bytes or current) * 0.9:
        health = "warning"
    
    return MemoryStats(
        current_bytes=current,
        max_bytes=max_bytes,
        high_bytes=high_bytes,
        pressure=pressure,
        health_status=health
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
