import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryDashboard } from './components/MemoryDashboard';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <div style={{ padding: '20px' }}>
        <h1 style={{ color: '#00ff88', marginBottom: '20px' }}>
          Nano-IDP Memory Monitor
        </h1>
        <MemoryDashboard />
      </div>
    </QueryClientProvider>
  );
}

export default App;
