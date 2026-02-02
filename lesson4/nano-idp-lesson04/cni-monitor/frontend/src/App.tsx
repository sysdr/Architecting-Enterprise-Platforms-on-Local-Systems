import { useQuery } from '@tanstack/react-query'
import axios from 'axios'

interface CNIMetrics {
  cni_type: string
  total_memory_mb: number
  agent_count: number
  policy_count: number
  status: {
    agent_ready: boolean
    operator_ready: boolean
    agent_memory_mb: number
    operator_memory_mb: number
    ebpf_status: string
  }
}

function App() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['cni-health'],
    queryFn: async () => {
      const response = await axios.get<CNIMetrics>('/api/cni/health')
      return response.data
    },
    refetchInterval: 5000
  })

  if (isLoading) return <div className="loading">Loading CNI metrics...</div>
  if (error) return <div className="error">Error: {String(error)}</div>

  const isHealthy = data?.status.agent_ready && data?.status.operator_ready

  return (
    <div className="container">
      <h1>🌐 CNI Health Monitor</h1>
      
      <div className={`status-card ${isHealthy ? 'healthy' : 'degraded'}`}>
        <h2>System Status: {isHealthy ? '✅ Healthy' : '⚠️ Degraded'}</h2>
        <div className="metrics">
          <div className="metric">
            <span className="label">CNI Type:</span>
            <span className="value">{data?.cni_type.toUpperCase()}</span>
          </div>
          <div className="metric">
            <span className="label">Total Memory:</span>
            <span className="value">{data?.total_memory_mb.toFixed(1)} MB</span>
          </div>
          <div className="metric">
            <span className="label">Agent Count:</span>
            <span className="value">{data?.agent_count}</span>
          </div>
          <div className="metric">
            <span className="label">NetworkPolicies:</span>
            <span className="value">{data?.policy_count}</span>
          </div>
        </div>
      </div>

      <div className="details">
        <h3>Component Details</h3>
        <div className="component">
          <div>Cilium Agent: {data?.status.agent_memory_mb.toFixed(1)} MB</div>
          <div className={data?.status.agent_ready ? 'ready' : 'not-ready'}>
            {data?.status.agent_ready ? '✅ Ready' : '❌ Not Ready'}
          </div>
        </div>
        <div className="component">
          <div>Cilium Operator: {data?.status.operator_memory_mb.toFixed(1)} MB</div>
          <div className={data?.status.operator_ready ? 'ready' : 'not-ready'}>
            {data?.status.operator_ready ? '✅ Ready' : '❌ Not Ready'}
          </div>
        </div>
        <div className="component">
          <div>eBPF Status: {data?.status.ebpf_status}</div>
        </div>
      </div>

      <style>{`
        .container {
          max-width: 800px;
          margin: 40px auto;
          padding: 20px;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }
        h1 { color: #333; }
        .status-card {
          border: 2px solid;
          border-radius: 8px;
          padding: 20px;
          margin: 20px 0;
        }
        .healthy { border-color: #22c55e; background: #f0fdf4; }
        .degraded { border-color: #f59e0b; background: #fffbeb; }
        .metrics { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
        .metric { display: flex; justify-content: space-between; padding: 10px; background: white; border-radius: 4px; }
        .label { font-weight: 600; }
        .value { font-family: monospace; }
        .details { margin-top: 30px; }
        .component { display: flex; justify-content: space-between; padding: 10px; border-bottom: 1px solid #e5e7eb; }
        .ready { color: #22c55e; font-weight: 600; }
        .not-ready { color: #ef4444; font-weight: 600; }
        .loading, .error { text-align: center; padding: 40px; }
      `}</style>
    </div>
  )
}

export default App
