import { useQuery } from '@tanstack/react-query'
import axios from 'axios'
import './App.css'

interface Volume {
  name: string
  capacity: string
  status: string
  storageClass: string
  claim: string | null
  hostPath: string | null
  reclaimPolicy: string
}

interface PVC {
  name: string
  namespace: string
  status: string
  volumeName: string
  storageClass: string
  capacity: string | null
  requested: string
}

interface IOStat {
  [device: string]: {
    reads_completed: number
    sectors_read: number
    writes_completed: number
    sectors_written: number
    io_time_ms: number
  }
}

function App() {
  const { data: volumes, isLoading: volumesLoading } = useQuery<Volume[]>({
    queryKey: ['volumes'],
    queryFn: async () => {
      const res = await axios.get('/api/storage/volumes')
      return res.data
    }
  })

  const { data: pvcs, isLoading: pvcsLoading } = useQuery<PVC[]>({
    queryKey: ['pvcs'],
    queryFn: async () => {
      const res = await axios.get('/api/storage/pvcs')
      return res.data
    }
  })

  const { data: iostat } = useQuery<IOStat>({
    queryKey: ['iostat'],
    queryFn: async () => {
      const res = await axios.get('/api/storage/iostat')
      return res.data
    }
  })

  return (
    <div className="container">
      <header>
        <h1>📦 Storage Monitor</h1>
        <p>Nano-IDP Lesson 8: Local-Path Storage</p>
      </header>

      <section className="card">
        <h2>Persistent Volumes</h2>
        {volumesLoading ? (
          <p>Loading...</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Capacity</th>
                <th>Status</th>
                <th>Storage Class</th>
                <th>Bound To</th>
                <th>Host Path</th>
              </tr>
            </thead>
            <tbody>
              {volumes?.map((vol) => (
                <tr key={vol.name}>
                  <td className="mono">{vol.name}</td>
                  <td>{vol.capacity}</td>
                  <td>
                    <span className={`status ${vol.status.toLowerCase()}`}>
                      {vol.status}
                    </span>
                  </td>
                  <td>{vol.storageClass}</td>
                  <td className="mono">{vol.claim || '-'}</td>
                  <td className="mono small">{vol.hostPath || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card">
        <h2>Persistent Volume Claims</h2>
        {pvcsLoading ? (
          <p>Loading...</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Namespace</th>
                <th>Name</th>
                <th>Status</th>
                <th>Requested</th>
                <th>Capacity</th>
                <th>Volume</th>
              </tr>
            </thead>
            <tbody>
              {pvcs?.map((pvc) => (
                <tr key={`${pvc.namespace}/${pvc.name}`}>
                  <td>{pvc.namespace}</td>
                  <td className="mono">{pvc.name}</td>
                  <td>
                    <span className={`status ${pvc.status.toLowerCase()}`}>
                      {pvc.status}
                    </span>
                  </td>
                  <td>{pvc.requested}</td>
                  <td>{pvc.capacity || '-'}</td>
                  <td className="mono small">{pvc.volumeName || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="card">
        <h2>Disk I/O Statistics</h2>
        <div className="iostat-grid">
          {Object.entries(iostat || {}).map(([device, stats]) => (
            <div key={device} className="iostat-card">
              <h3>{device}</h3>
              <div className="stat">
                <span>Reads:</span>
                <span className="value">{stats.reads_completed.toLocaleString()}</span>
              </div>
              <div className="stat">
                <span>Sectors Read:</span>
                <span className="value">{stats.sectors_read.toLocaleString()}</span>
              </div>
              <div className="stat">
                <span>Writes:</span>
                <span className="value">{stats.writes_completed.toLocaleString()}</span>
              </div>
              <div className="stat">
                <span>Sectors Written:</span>
                <span className="value">{stats.sectors_written.toLocaleString()}</span>
              </div>
              <div className="stat">
                <span>I/O Time:</span>
                <span className="value">{(stats.io_time_ms / 1000).toFixed(2)}s</span>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}

export default App
