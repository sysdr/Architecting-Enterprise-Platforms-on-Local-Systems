"""
Kernel Memory Map Monitor
Tracks vm.max_map_count utilization across processes.
Resource Budget: <60MB memory, <1% CPU
"""
from pathlib import Path
from typing import Dict, List, Optional
from fastapi import FastAPI, HTTPException
from fastapi.responses import PlainTextResponse
import asyncio
from datetime import datetime

app = FastAPI(title="Kernel Map Monitor", version="1.0.0")

class MapMonitor:
    """Efficient memory map counter using direct /proc access."""
    
    @staticmethod
    def get_process_maps(pid: int) -> int:
        """Count memory mappings for a process."""
        maps_file = Path(f"/proc/{pid}/maps")
        try:
            if not maps_file.exists():
                return 0
            with maps_file.open() as f:
                return sum(1 for _ in f)
        except (PermissionError, FileNotFoundError, ProcessLookupError):
            return 0
    
    @staticmethod
    def get_current_limit() -> int:
        """Read current kernel max_map_count limit."""
        try:
            return int(Path("/proc/sys/vm/max_map_count").read_text().strip())
        except (FileNotFoundError, ValueError):
            return 65530  # Default fallback
    
    @staticmethod
    def get_process_info(pid: int) -> Optional[str]:
        """Get process command line."""
        cmdline_file = Path(f"/proc/{pid}/cmdline")
        try:
            cmdline = cmdline_file.read_text().replace('\x00', ' ').strip()
            return cmdline[:100] if cmdline else None
        except (PermissionError, FileNotFoundError, ProcessLookupError):
            return None

monitor = MapMonitor()

@app.get("/health")
async def health_check() -> Dict:
    """Health check endpoint."""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.get("/metrics/maps")
async def get_metrics() -> Dict:
    """
    Aggregate memory map statistics.
    Returns current utilization and top consumers.
    """
    total_maps = 0
    process_data: List[Dict] = []
    
    # Scan all processes
    for pid_dir in Path("/proc").glob("[0-9]*"):
        try:
            pid = int(pid_dir.name)
            map_count = monitor.get_process_maps(pid)
            
            if map_count == 0:
                continue
            
            total_maps += map_count
            
            # Only track significant processes (>500 maps)
            if map_count > 500:
                cmdline = monitor.get_process_info(pid)
                if cmdline:
                    process_data.append({
                        "pid": pid,
                        "command": cmdline,
                        "map_count": map_count
                    })
        except (ValueError, OSError):
            continue
    
    # Get kernel limit
    max_limit = monitor.get_current_limit()
    utilization = (total_maps / max_limit * 100) if max_limit > 0 else 0
    
    # Sort by map count
    top_consumers = sorted(process_data, key=lambda x: x["map_count"], reverse=True)[:15]
    
    return {
        "timestamp": datetime.utcnow().isoformat(),
        "total_maps": total_maps,
        "max_map_count": max_limit,
        "utilization_percent": round(utilization, 2),
        "status": "warning" if utilization > 80 else "ok",
        "top_consumers": top_consumers
    }

@app.get("/metrics", response_class=PlainTextResponse)
async def prometheus_metrics() -> str:
    """
    Prometheus-compatible metrics endpoint.
    No Prometheus server required.
    """
    data = await get_metrics()
    
    return f"""# HELP vm_max_map_count Current kernel limit for memory maps
# TYPE vm_max_map_count gauge
vm_max_map_count {data['max_map_count']}

# HELP vm_maps_total Total memory maps currently in use
# TYPE vm_maps_total gauge
vm_maps_total {data['total_maps']}

# HELP vm_maps_utilization_percent Memory map utilization percentage
# TYPE vm_maps_utilization_percent gauge
vm_maps_utilization_percent {data['utilization_percent']}

# HELP vm_maps_status Status indicator (1=ok, 0=warning)
# TYPE vm_maps_status gauge
vm_maps_status {1 if data['status'] == 'ok' else 0}
"""

@app.get("/sysctl/apply")
async def apply_sysctl() -> Dict:
    """
    Check if sysctl tuning is applied.
    This endpoint doesn't modify (requires host access).
    """
    current = monitor.get_current_limit()
    recommended = 524288
    
    return {
        "current_value": current,
        "recommended_value": recommended,
        "tuning_applied": current >= recommended,
        "message": "Tuning applied correctly" if current >= recommended 
                   else f"Run: sudo sysctl -w vm.max_map_count={recommended}"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080, log_level="info")
