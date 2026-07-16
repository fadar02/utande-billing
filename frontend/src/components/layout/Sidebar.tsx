import React, { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const navItems = [
  { path: '/dashboard', label: 'Dashboard', icon: '📊' },
  { path: '/customers', label: 'Customers', icon: '👥' },
  { path: '/services', label: 'Packages', icon: '📦' },
  { path: '/invoices', label: 'Invoices', icon: '📄' },
  { path: '/reports', label: 'Reports', icon: '📈' },
  { path: '/settings', label: 'Settings', icon: '⚙️', roles: ['ADMIN', 'FINANCE'] },
  { path: '/users', label: 'Users', icon: '👤', roles: ['ADMIN'] },
];

export const Sidebar: React.FC = () => {
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [collapsed, setCollapsed] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const filteredNav = navItems.filter(item => {
    if (item.roles && user) {
      return item.roles.includes(user.role);
    }
    return true;
  });

  return (
    <div className={`sidebar ${collapsed ? 'collapsed' : ''}`} style={{
      width: collapsed ? '60px' : '240px',
      height: '100vh',
      backgroundColor: '#1a2332',
      color: '#a0aec0',
      display: 'flex',
      flexDirection: 'column',
      transition: 'width 0.3s',
      overflow: 'hidden',
    }}>
      <div style={{ padding: '20px', borderBottom: '1px solid #2d3748', display: 'flex', alignItems: 'center', gap: '10px' }}>
        <img src="/logo.png" alt="Utande" style={{ height: '36px', width: 'auto', objectFit: 'contain' }} />
        {!collapsed && <h2 style={{ color: '#fff', margin: 0, fontSize: '16px', whiteSpace: 'nowrap' }}>Utande Billing</h2>}
        <button onClick={() => setCollapsed(!collapsed)} style={{
          background: 'none', border: 'none', color: '#a0aec0', cursor: 'pointer', fontSize: '18px', padding: '5px', marginLeft: collapsed ? '0' : 'auto'
        }}>{collapsed ? '☰' : '✕'}</button>
      </div>

      <nav style={{ flex: 1, padding: '10px 0' }}>
        {filteredNav.map(item => (
          <Link key={item.path} to={item.path} style={{
            display: 'flex', alignItems: 'center', padding: '12px 20px',
            color: location.pathname === item.path ? '#fff' : '#a0aec0',
            backgroundColor: location.pathname === item.path ? '#2d3748' : 'transparent',
            textDecoration: 'none', fontSize: '14px', gap: '10px',
            borderLeft: location.pathname === item.path ? '3px solid #4299e1' : '3px solid transparent',
          }}>
            <span>{item.icon}</span>
            {!collapsed && <span>{item.label}</span>}
          </Link>
        ))}
      </nav>

      <div style={{ padding: '15px 20px', borderTop: '1px solid #2d3748' }}>
        {user && !collapsed && (
          <div style={{ fontSize: '12px', marginBottom: '10px' }}>
            <div style={{ color: '#fff' }}>{user.firstName} {user.lastName}</div>
            <div style={{ color: '#718096' }}>{user.role}</div>
          </div>
        )}
        <button onClick={handleLogout} style={{
          width: '100%', padding: '8px', backgroundColor: '#e53e3e', color: '#fff',
          border: 'none', borderRadius: '4px', cursor: 'pointer', fontSize: '12px',
        }}>
          {collapsed ? '🚪' : 'Logout'}
        </button>
      </div>
    </div>
  );
};
