from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
from pydantic import BaseModel, Field
from typing import Dict, Optional
import logging
import time
import random

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Nano-IDP Memory Monitor", version="1.0.0")

# CORS for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class MemoryStats(BaseModel):
    total_mb: int = Field(..., description="Total physical RAM")
    available_mb: int = Field(..., description="Available for allocation")
    used_mb: int = Field(..., description="Currently used RAM")
    swap_total_mb: int = Field(..., description="Total swap space")
    swap_used_mb: int = Field(..., description="Used swap")
    swap_free_mb: int = Field(..., description="Free swap")
    swappiness: int = Field(..., description="Current kernel swappiness")
    cache_pressure: int = Field(..., description="VFS cache pressure")
    pressure_level: str = Field(..., description="low|medium|high|critical")

def parse_meminfo() -> Dict[str, int]:
    """Parse /proc/meminfo without external dependencies."""
    meminfo = {}
    try:
        with Path("/proc/meminfo").open() as f:
            for line in f:
                if line.strip():
                    parts = line.split(":", 1)
                    if len(parts) == 2:
                        key = parts[0].strip()
                        value_parts = parts[1].strip().split()
                        if value_parts:
                            meminfo[key] = int(value_parts[0])
    except FileNotFoundError:
        logger.warning("/proc/meminfo not found - returning mock data")
        return {
            "MemTotal": 8192000,
            "MemAvailable": 4096000,
            "SwapTotal": 4096000,
            "SwapFree": 3500000,
        }
    return meminfo

def get_sysctl_value(param: str) -> int:
    """Read sysctl value safely."""
    try:
        return int(Path(f"/proc/sys/{param.replace('.', '/')}").read_text().strip())
    except (FileNotFoundError, ValueError):
        logger.warning(f"Cannot read {param} - returning default")
        return 60 if "swappiness" in param else 100

def calculate_pressure(available_mb: int, total_mb: int) -> str:
    """Determine memory pressure level."""
    if total_mb == 0:
        return "unknown"
    ratio = available_mb / total_mb
    if ratio > 0.4:
        return "low"
    elif ratio > 0.2:
        return "medium"
    elif ratio > 0.1:
        return "high"
    else:
        return "critical"

def generate_demo_data() -> Dict[str, int]:
    """Generate realistic demo data that varies over time."""
    # Base values for an 8GB system
    total_mb = 8192
    base_time = int(time.time())
    
    # Create a pattern that cycles through different pressure levels
    cycle_position = (base_time % 60) / 60.0  # 60 second cycle
    
    # Simulate memory usage that varies between 30% and 85%
    # Ensure swap usage is always visible in demo mode
    if cycle_position < 0.25:
        # Low pressure phase - minimal swap usage
        used_ratio = 0.3 + (cycle_position / 0.25) * 0.1
        swap_used_ratio = 0.05 + (cycle_position / 0.25) * 0.05  # 5-10% swap
    elif cycle_position < 0.5:
        # Medium pressure phase - moderate swap usage
        used_ratio = 0.4 + ((cycle_position - 0.25) / 0.25) * 0.15
        swap_used_ratio = 0.1 + ((cycle_position - 0.25) / 0.25) * 0.15  # 10-25% swap
    elif cycle_position < 0.75:
        # High pressure phase - significant swap usage
        used_ratio = 0.55 + ((cycle_position - 0.5) / 0.25) * 0.15
        swap_used_ratio = 0.25 + ((cycle_position - 0.5) / 0.25) * 0.25  # 25-50% swap
    else:
        # Critical pressure phase - heavy swap usage
        used_ratio = 0.7 + ((cycle_position - 0.75) / 0.25) * 0.15
        swap_used_ratio = 0.5 + ((cycle_position - 0.75) / 0.25) * 0.3  # 50-80% swap
    
    # Add some random variation (±2%)
    used_ratio += (random.random() - 0.5) * 0.04
    used_ratio = max(0.25, min(0.9, used_ratio))  # Clamp between 25% and 90%
    
    # Add slight variation to swap usage for more realistic demo
    swap_used_ratio += (random.random() - 0.5) * 0.03
    swap_used_ratio = max(0.05, min(0.85, swap_used_ratio))  # Clamp between 5% and 85%
    
    used_mb = int(total_mb * used_ratio)
    available_mb = total_mb - used_mb
    
    # Swap: 4GB total
    swap_total_mb = 4096
    swap_used_mb = int(swap_total_mb * swap_used_ratio)
    swap_free_mb = swap_total_mb - swap_used_mb
    
    return {
        "MemTotal": total_mb * 1024,  # Convert to KB
        "MemAvailable": available_mb * 1024,
        "SwapTotal": swap_total_mb * 1024,
        "SwapFree": swap_free_mb * 1024,
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/api/memory/stats", response_model=MemoryStats)
async def get_memory_stats(demo: Optional[bool] = Query(False, description="Use demo data instead of real system data")):
    """Gather current memory statistics."""
    try:
        if demo:
            logger.info("Generating demo data")
            meminfo = generate_demo_data()
            # Demo mode uses optimized settings
            swappiness = 10
            cache_pressure = 50
        else:
            meminfo = parse_meminfo()
            swappiness = get_sysctl_value("vm.swappiness")
            cache_pressure = get_sysctl_value("vm.vfs_cache_pressure")
        
        total = meminfo.get("MemTotal", 0) // 1024
        available = meminfo.get("MemAvailable", 0) // 1024
        used = total - available
        swap_total = meminfo.get("SwapTotal", 0) // 1024
        swap_free = meminfo.get("SwapFree", 0) // 1024
        swap_used = swap_total - swap_free
        
        return MemoryStats(
            total_mb=total,
            available_mb=available,
            used_mb=used,
            swap_total_mb=swap_total,
            swap_used_mb=swap_used,
            swap_free_mb=swap_free,
            swappiness=swappiness,
            cache_pressure=cache_pressure,
            pressure_level=calculate_pressure(available, total)
        )
    except Exception as e:
        logger.error(f"Error gathering memory stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/memory/recommendations")
async def get_recommendations(demo: Optional[bool] = Query(False, description="Use demo data instead of real system data")):
    """Provide swappiness recommendations based on current state."""
    stats = await get_memory_stats(demo=demo)
    
    recommendations = []
    
    if stats.swappiness > 30:
        recommendations.append({
            "severity": "warning",
            "message": f"Swappiness is {stats.swappiness}. Recommend 10-20 for 8GB systems.",
            "command": "sudo sysctl vm.swappiness=10"
        })
    
    if stats.swap_total_mb == 0:
        recommendations.append({
            "severity": "critical",
            "message": "No swap configured. System vulnerable to OOM kills.",
            "command": "sudo fallocate -l 4G /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
        })
    elif stats.swap_total_mb < stats.total_mb * 0.5:
        recommendations.append({
            "severity": "warning",
            "message": f"Swap ({stats.swap_total_mb}MB) is less than 50% of RAM. Recommend 4GB minimum.",
            "command": "Increase swap size to 4GB"
        })
    
    if stats.pressure_level == "critical":
        recommendations.append({
            "severity": "critical",
            "message": "Critical memory pressure. Consider closing applications or reducing workloads.",
            "command": "kubectl delete pod <least-important-pod>"
        })
    
    return {"recommendations": recommendations, "current_stats": stats}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
