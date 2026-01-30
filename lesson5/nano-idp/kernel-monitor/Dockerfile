FROM python:3.12-slim

# Metadata
LABEL maintainer="Nano-IDP"
LABEL description="Kernel memory map monitor - <60MB runtime"

# Install minimal dependencies
RUN pip install --no-cache-dir \
    fastapi==0.109.0 \
    uvicorn[standard]==0.27.0

# Create app directory
WORKDIR /app

# Copy application
COPY src/main.py .

# Non-root user
RUN useradd -m -u 1000 monitor && \
    chown -R monitor:monitor /app
USER monitor

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"

# Run application
EXPOSE 8080
CMD ["python", "main.py"]
