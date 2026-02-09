# Ingress Lite Frontend

A modern, responsive web frontend for testing and monitoring the Ingress Lite Kubernetes setup.

## Features

- **Health Status Monitoring**: Real-time health check of the backend service
- **Backend Information**: Display pod information, paths, and client details
- **Echo Testing**: Test the echo endpoint with custom paths
- **Auto-refresh**: Health status automatically refreshes every 30 seconds
- **Modern UI**: Clean, gradient-based design with smooth animations

## Quick Start

### Option 1: Using the Server Script (Recommended)

```bash
cd frontend
./serve.sh
```

Then open your browser to: `http://localhost:8080`

You can specify a custom port:
```bash
./serve.sh 3000
```

### Option 2: Using Python Directly

```bash
cd frontend
python3 -m http.server 8080
```

### Option 3: Open Directly in Browser

Simply open `index.html` in your web browser. Note: Some browsers may have CORS restrictions when opening files directly.

## Configuration

The frontend is configured to connect to the backend at `http://localhost:30080` by default.

To change the backend URL, edit the `API_BASE` constant in `index.html`:

```javascript
const API_BASE = 'http://localhost:30080';
```

## API Endpoints Used

- `GET /health` - Health check endpoint
- `GET /` - Root endpoint with backend information
- `GET /echo/{path}` - Echo endpoint for testing path-based routing

## Browser Compatibility

- Chrome/Edge (recommended)
- Firefox
- Safari
- Any modern browser with ES6 support

## Troubleshooting

### CORS Errors

If you see CORS errors, make sure:
1. The backend is running and accessible at the configured URL
2. You're using the server script instead of opening the file directly
3. The ingress controller is properly configured

### Connection Refused

If you see connection errors:
1. Verify the backend is running: `kubectl get pods -l app=test-backend`
2. Check the ingress service: `kubectl get svc -n kube-system nginx-ingress`
3. Ensure port 30080 is accessible: `curl http://localhost:30080/health`

