import { useState, useEffect } from 'react'
import axios from 'axios'

interface PriorityClass {
  name: string
  value: number
  global_default: boolean
  description: string | null
  preemption_policy: string | null
}

interface PodPriority {
  pod_name: string
  namespace: string
  priority_class: string
  priority_value: number
  memory_usage: string | null
  status: string
}

interface Stats {
  [key: string]: {
    count: number
    priority_value: number
    running: number
    pending: number
    failed: number
  }
}

function App() {
  const [priorityClasses, setPriorityClasses] = useState<PriorityClass[]>([])
  const [pods, setPods] = useState<PodPriority[]>([])
  const [stats, setStats] = useState<Stats>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [autoRefresh, setAutoRefresh] = useState(true)

  const fetchData = async () => {
    try {
      const [pcsRes, podsRes, statsRes] = await Promise.all([
        axios.get<PriorityClass[]>('/api/priorityclasses'),
        axios.get<PodPriority[]>('/api/pods/priorities'),
        axios.get<Stats>('/api/stats')
      ])
      
      setPriorityClasses(pcsRes.data)
      setPods(podsRes.data)
      setStats(statsRes.data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch data')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
    
    if (autoRefresh) {
      const interval = setInterval(fetchData, 5000)
      return () => clearInterval(interval)
    }
  }, [autoRefresh])

  const getPriorityBadgeClass = (value: number) => {
    if (value >= 100000) return 'badge-critical'
    if (value >= 1000) return 'badge-core'
    return 'badge-tenant'
  }

  const getStatusBadgeClass = (status: string) => {
    switch (status.toLowerCase()) {
      case 'running': return 'badge-running'
      case 'pending': return 'badge-pending'
      case 'failed': return 'badge-failed'
      default: return 'badge-tenant'
    }
  }

  if (loading) {
    return <div className="loading">Loading priority data...</div>
  }

  return (
    <div className="container">
      <div className="header">
        <h1>🎯 Priority Monitor</h1>
        <p>Lesson 9: PriorityClasses - OOM Killer Control</p>
      </div>

      {error && (
        <div className="error">
          <strong>Error:</strong> {error}
        </div>
      )}

      <div className="stats-grid">
        <div className="stat-card">
          <h3>Total Pods</h3>
          <div className="value">{pods.length}</div>
        </div>
        <div className="stat-card">
          <h3>Priority Classes</h3>
          <div className="value">{priorityClasses.length}</div>
        </div>
        <div className="stat-card">
          <h3>Running Pods</h3>
          <div className="value">
            {Object.values(stats).reduce((sum, s) => sum + s.running, 0)}
          </div>
        </div>
        <div className="stat-card">
          <h3>Auto-Refresh</h3>
          <button onClick={() => setAutoRefresh(!autoRefresh)}>
            {autoRefresh ? 'ON' : 'OFF'}
          </button>
        </div>
      </div>

      <div className="section">
        <h2>Priority Classes</h2>
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Priority Value</th>
              <th>Global Default</th>
              <th>Preemption Policy</th>
              <th>Pod Count</th>
            </tr>
          </thead>
          <tbody>
            {priorityClasses.map(pc => (
              <tr key={pc.name}>
                <td>
                  <span className={`badge ${getPriorityBadgeClass(pc.value)}`}>
                    {pc.name}
                  </span>
                </td>
                <td>{pc.value.toLocaleString()}</td>
                <td>{pc.global_default ? '✓' : '—'}</td>
                <td>{pc.preemption_policy || 'PreemptLowerPriority'}</td>
                <td>{stats[pc.name]?.count || 0}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="section">
        <h2>Pod Priority Assignments</h2>
        <table>
          <thead>
            <tr>
              <th>Pod Name</th>
              <th>Namespace</th>
              <th>Priority Class</th>
              <th>Priority Value</th>
              <th>Status</th>
              <th>Memory</th>
            </tr>
          </thead>
          <tbody>
            {pods.map((pod, idx) => (
              <tr key={idx}>
                <td>{pod.pod_name}</td>
                <td>{pod.namespace}</td>
                <td>
                  <span className={`badge ${getPriorityBadgeClass(pod.priority_value)}`}>
                    {pod.priority_class}
                  </span>
                </td>
                <td>{pod.priority_value.toLocaleString()}</td>
                <td>
                  <span className={`badge ${getStatusBadgeClass(pod.status)}`}>
                    {pod.status}
                  </span>
                </td>
                <td>{pod.memory_usage || 'N/A'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default App
