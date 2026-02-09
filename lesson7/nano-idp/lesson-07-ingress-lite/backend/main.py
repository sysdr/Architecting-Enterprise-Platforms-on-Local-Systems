"""
Minimal test backend for ingress verification.
Memory footprint: ~40MB
"""
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Ingress Test Backend", version="1.0.0")

# Add CORS middleware to allow frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)

@app.get("/health")
async def health():
    """Health check endpoint for K8s probes."""
    return JSONResponse(
        status_code=200,
        content={
            "status": "healthy",
            "pod": os.getenv("HOSTNAME", "unknown"),
            "service": "test-backend"
        }
    )

@app.get("/ready")
async def ready():
    """Readiness check endpoint."""
    return JSONResponse(
        status_code=200,
        content={"status": "ready"}
    )

@app.get("/")
async def root(request: Request):
    """Root endpoint to verify ingress routing."""
    return JSONResponse(
        status_code=200,
        content={
            "message": "Ingress routing works!",
            "pod": os.getenv("HOSTNAME", "unknown"),
            "path": str(request.url.path),
            "host": request.headers.get("host", "unknown"),
            "client_ip": request.client.host if request.client else "unknown"
        }
    )

@app.get("/echo/{path:path}")
async def echo(path: str, request: Request):
    """Echo endpoint to test path-based routing."""
    return JSONResponse(
        status_code=200,
        content={
            "message": f"Echo: {path}",
            "pod": os.getenv("HOSTNAME", "unknown"),
            "full_path": str(request.url.path),
            "query_params": dict(request.query_params)
        }
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info",
        access_log=False  # Reduce memory overhead
    )
