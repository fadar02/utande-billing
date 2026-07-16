import React from 'react';
import { Sidebar } from './Sidebar';

export const Layout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      <Sidebar />
      <main style={{ flex: 1, backgroundColor: '#f7fafc', overflow: 'auto' }}>
        <div style={{ padding: '24px', maxWidth: '1400px' }}>
          {children}
        </div>
      </main>
    </div>
  );
};
