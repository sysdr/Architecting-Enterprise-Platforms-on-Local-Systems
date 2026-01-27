import React from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

interface MemoryStats {
  total_mb: number;
  available_mb: number;
  used_mb: number;
  swap_total_mb: number;
  swap_used_mb: number;
  swap_free_mb: number;
  swappiness: number;
  cache_pressure: number;
  pressure_level: string;
}

interface Recommendation {
  severity: string;
  message: string;
  command: string;
}

const API_BASE = import.meta.env.VITE_API_URL || '';
const DEMO_MODE = new URLSearchParams(window.location.search).get('demo') === 'true';

export const MemoryDashboard: React.FC = () => {
  const [history, setHistory] = React.useState<Array<{ timestamp: string; used: number; swap: number }>>([]);

  const { data: stats, isLoading } = useQuery<MemoryStats>({
    queryKey: ['memory-stats', DEMO_MODE],
    queryFn: () => axios.get(`${API_BASE}/api/memory/stats${DEMO_MODE ? '?demo=true' : ''}`).then((r) => r.data),
    refetchInterval: 3000,
  });

  const { data: recommendations } = useQuery<{ recommendations: Recommendation[] }>({
    queryKey: ['memory-recommendations', DEMO_MODE],
    queryFn: () => axios.get(`${API_BASE}/api/memory/recommendations${DEMO_MODE ? '?demo=true' : ''}`).then((r) => r.data),
    refetchInterval: 10000,
  });

  React.useEffect(() => {
    if (stats) {
      const now = new Date().toLocaleTimeString();
      setHistory((prev) =>
        [...prev, { timestamp: now, used: stats.used_mb, swap: stats.swap_used_mb }].slice(-20)
      );
    }
  }, [stats]);

  if (isLoading) {
    return <div style={{ color: '#888' }}>Loading memory stats...</div>;
  }

  if (!stats) {
    return <div style={{ color: '#ff4444' }}>Failed to load memory stats</div>;
  }

  const pressureColors = {
    low: '#00ff88',
    medium: '#ffaa00',
    high: '#ff6600',
    critical: '#ff0000',
  };

  const usedPercentage = ((stats.used_mb / stats.total_mb) * 100).toFixed(1);
  const swapPercentage = stats.swap_total_mb > 0 
    ? ((stats.swap_used_mb / stats.swap_total_mb) * 100).toFixed(1)
    : '0';

  return (
    <div style={{ display: 'grid', gap: '20px' }}>
      {DEMO_MODE && (
        <div style={{ 
          background: '#1a3a1a', 
          padding: '15px', 
          borderRadius: '8px', 
          borderLeft: '4px solid #00ff88',
          marginBottom: '10px'
        }}>
          <strong style={{ color: '#00ff88' }}>📊 DEMO MODE ACTIVE</strong>
          <div style={{ color: '#aaa', fontSize: '14px', marginTop: '5px' }}>
            Showing simulated memory data that cycles through different pressure levels. 
            <a href="?" style={{ color: '#00aaff', marginLeft: '10px' }}>Switch to real data</a>
          </div>
        </div>
      )}
      {!DEMO_MODE && (
        <div style={{ 
          background: '#1a1a1a', 
          padding: '10px', 
          borderRadius: '8px',
          textAlign: 'right'
        }}>
          <a href="?demo=true" style={{ color: '#00aaff', fontSize: '14px' }}>
            🎭 View Demo Data
          </a>
        </div>
      )}
      {/* Stats Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '15px' }}>
        <StatCard
          title="Memory Usage"
          value={`${stats.used_mb} MB`}
          subtitle={`${usedPercentage}% of ${stats.total_mb} MB`}
          color={pressureColors[stats.pressure_level as keyof typeof pressureColors]}
        />
        <StatCard
          title="Available"
          value={`${stats.available_mb} MB`}
          subtitle={`Pressure: ${stats.pressure_level.toUpperCase()}`}
          color={pressureColors[stats.pressure_level as keyof typeof pressureColors]}
        />
        <StatCard
          title="Swap Usage"
          value={`${stats.swap_used_mb} MB`}
          subtitle={`${swapPercentage}% of ${stats.swap_total_mb} MB`}
          color="#00aaff"
        />
        <StatCard
          title="Kernel Settings"
          value={`Swappiness: ${stats.swappiness}`}
          subtitle={`Cache Pressure: ${stats.cache_pressure}`}
          color="#aa88ff"
        />
      </div>

      {/* Chart */}
      <div style={{ background: '#1a1a1a', padding: '20px', borderRadius: '8px' }}>
        <h3 style={{ marginBottom: '15px', color: '#00ff88' }}>Memory Trend (Last 60s)</h3>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={history}>
            <CartesianGrid strokeDasharray="3 3" stroke="#333" />
            <XAxis dataKey="timestamp" stroke="#888" />
            <YAxis stroke="#888" />
            <Tooltip
              contentStyle={{ background: '#0f0f0f', border: '1px solid #333' }}
              labelStyle={{ color: '#00ff88' }}
            />
            <Legend />
            <Line type="monotone" dataKey="used" stroke="#00ff88" name="Used RAM (MB)" />
            <Line type="monotone" dataKey="swap" stroke="#00aaff" name="Swap (MB)" />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Recommendations */}
      {recommendations && recommendations.recommendations.length > 0 && (
        <div style={{ background: '#1a1a1a', padding: '20px', borderRadius: '8px' }}>
          <h3 style={{ marginBottom: '15px', color: '#ffaa00' }}>⚠️ Recommendations</h3>
          {recommendations.recommendations.map((rec, idx) => (
            <div
              key={idx}
              style={{
                background: '#0f0f0f',
                padding: '15px',
                marginBottom: '10px',
                borderLeft: `4px solid ${rec.severity === 'critical' ? '#ff0000' : '#ffaa00'}`,
              }}
            >
              <div style={{ fontWeight: 'bold', marginBottom: '5px' }}>{rec.message}</div>
              <code style={{ background: '#000', padding: '5px 10px', display: 'block', marginTop: '10px' }}>
                {rec.command}
              </code>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

const StatCard: React.FC<{ title: string; value: string; subtitle: string; color: string }> = ({
  title,
  value,
  subtitle,
  color,
}) => (
  <div style={{ background: '#1a1a1a', padding: '20px', borderRadius: '8px', borderLeft: `4px solid ${color}` }}>
    <div style={{ fontSize: '14px', color: '#888', marginBottom: '5px' }}>{title}</div>
    <div style={{ fontSize: '24px', fontWeight: 'bold', color, marginBottom: '5px' }}>{value}</div>
    <div style={{ fontSize: '12px', color: '#aaa' }}>{subtitle}</div>
  </div>
);
