# ✅ Dashboard is Now Running Locally!

## 🎯 Access the Dashboard

**Main Dashboard URL:**
```
http://localhost:3000
```

**Backend API (direct access):**
```
http://localhost:8080
```

## 📊 API Endpoints

- Health: `http://localhost:3000/api/health`
- Priority Classes: `http://localhost:3000/api/priorityclasses`
- Pod Priorities: `http://localhost:3000/api/pods/priorities`
- Statistics: `http://localhost:3000/api/stats`

## 🔧 Services Running

- **Backend:** FastAPI on port 8080
- **Frontend:** Vite dev server on port 3000 (with proxy to backend)

## 🛑 To Stop Services

```bash
# Kill backend
pkill -f "uvicorn.*8080"

# Kill frontend
pkill -f "vite"
```

## 📝 Note

The frontend is configured with a proxy in `vite.config.ts` that forwards `/api/*` requests to `http://localhost:8080`, so all API calls work seamlessly through the frontend URL.

