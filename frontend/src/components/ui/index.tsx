import React from 'react';

export const Card: React.FC<{
  title?: string;
  children: React.ReactNode;
  style?: React.CSSProperties;
  className?: string;
}> = ({ title, children, style, className }) => (
  <div className={className} style={{
    backgroundColor: '#fff', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
    padding: '20px', marginBottom: '16px', ...style,
  }}>
    {title && <h3 style={{ marginTop: 0, marginBottom: '16px', fontSize: '16px', color: '#2d3748' }}>{title}</h3>}
    {children}
  </div>
);

export const Button: React.FC<{
  children: React.ReactNode;
  onClick?: () => void;
  variant?: 'primary' | 'secondary' | 'danger' | 'success';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  type?: 'button' | 'submit';
}> = ({ children, onClick, variant = 'primary', size = 'md', disabled, type = 'button' }) => {
  const colors = {
    primary: { bg: '#4299e1', hover: '#3182ce' },
    secondary: { bg: '#718096', hover: '#4a5568' },
    danger: { bg: '#e53e3e', hover: '#c53030' },
    success: { bg: '#48bb78', hover: '#38a169' },
  };

  const sizes = { sm: '6px 12px', md: '8px 16px', lg: '12px 24px' };

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      style={{
        backgroundColor: colors[variant].bg, color: '#fff', border: 'none',
        borderRadius: '6px', cursor: disabled ? 'not-allowed' : 'pointer',
        padding: sizes[size], fontSize: size === 'sm' ? '12px' : '14px',
        opacity: disabled ? 0.6 : 1, fontWeight: 500,
        transition: 'background-color 0.2s',
      }}
    >
      {children}
    </button>
  );
};

export const Input: React.FC<{
  label: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  type?: string;
  placeholder?: string;
  required?: boolean;
  min?: string;
  error?: string;
  style?: React.CSSProperties;
}> = ({ label, value, onChange, type = 'text', placeholder, required, min, error, style }) => (
  <div style={{ marginBottom: '12px' }}>
    <label style={{ display: 'block', marginBottom: '4px', fontSize: '14px', color: '#4a5568', fontWeight: 500 }}>
      {label} {required && <span style={{ color: '#e53e3e' }}>*</span>}
    </label>
    <input
      type={type} value={value} onChange={onChange} placeholder={placeholder} min={min} required={required}
      style={{
        width: '100%', padding: '8px 12px', border: `1px solid ${error ? '#e53e3e' : '#e2e8f0'}`,
        borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box', ...style,
      }}
    />
    {error && <span style={{ color: '#e53e3e', fontSize: '12px' }}>{error}</span>}
  </div>
);

export const Select: React.FC<{
  label: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
  options: { value: string; label: string }[];
  required?: boolean;
}> = ({ label, value, onChange, options, required }) => (
  <div style={{ marginBottom: '12px' }}>
    <label style={{ display: 'block', marginBottom: '4px', fontSize: '14px', color: '#4a5568', fontWeight: 500 }}>
      {label} {required && <span style={{ color: '#e53e3e' }}>*</span>}
    </label>
    <select
      value={value} onChange={onChange}
      style={{
        width: '100%', padding: '8px 12px', border: '1px solid #e2e8f0',
        borderRadius: '6px', fontSize: '14px', backgroundColor: '#fff',
      }}
    >
      {options.map(opt => <option key={opt.value} value={opt.value}>{opt.label}</option>)}
    </select>
  </div>
);

export const Badge: React.FC<{
  status: string;
  variant?: 'success' | 'warning' | 'danger' | 'info';
  daysOverdue?: number;
}> = ({ status, variant, daysOverdue }) => {
  const variants: Record<string, string> = {
    success: '#c6f6d5',
    warning: '#fefcbf',
    danger: '#fed7d7',
    info: '#bee3f8',
  };

  const textColors: Record<string, string> = {
    success: '#22543d',
    warning: '#744210',
    danger: '#742a2a',
    info: '#2a4365',
  };

  const autoVariant = variant || (() => {
    const s = status.toUpperCase();
    if (s === 'PAID' || s === 'ACTIVE' || s === 'SENT') return 'success';
    if (s === 'PENDING' || s === 'PARTIALLY_PAID') return 'warning';
    if (s === 'OVERDUE' || s === 'SUSPENDED' || s === 'FAILED' || s === 'CANCELLED') return 'danger';
    return 'info';
  })();

  return (
    <span style={{
      padding: '2px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600,
      backgroundColor: variants[autoVariant], color: textColors[autoVariant],
    }}>
      {status}{daysOverdue !== undefined && status.toUpperCase() === 'OVERDUE' ? ` (${daysOverdue} day${daysOverdue !== 1 ? 's' : ''})` : ''}
    </span>
  );
};

export const StatCard: React.FC<{
  label: string;
  value: string | number;
  icon?: string;
  color?: string;
}> = ({ label, value, icon, color = '#4299e1' }) => (
  <div style={{
    backgroundColor: '#fff', borderRadius: '8px', padding: '20px',
    boxShadow: '0 1px 3px rgba(0,0,0,0.1)', display: 'flex', alignItems: 'center', gap: '16px',
  }}>
    <div style={{
      width: '48px', height: '48px', borderRadius: '8px',
      backgroundColor: color + '20', display: 'flex', alignItems: 'center',
      justifyContent: 'center', fontSize: '24px',
    }}>
      {icon}
    </div>
    <div>
      <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#2d3748' }}>{value}</div>
      <div style={{ fontSize: '14px', color: '#718096' }}>{label}</div>
    </div>
  </div>
);

export const Table: React.FC<{
  headers: string[];
  children: React.ReactNode;
}> = ({ headers, children }) => (
  <div style={{ overflowX: 'auto' }}>
    <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px' }}>
      <thead>
        <tr style={{ backgroundColor: '#f7fafc', borderBottom: '2px solid #e2e8f0' }}>
          {headers.map(h => (
            <th key={h} style={{ padding: '12px 16px', textAlign: 'left', fontWeight: 600, color: '#4a5568' }}>{h}</th>
          ))}
        </tr>
      </thead>
      <tbody>{children}</tbody>
    </table>
  </div>
);

export const Modal: React.FC<{
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}> = ({ isOpen, onClose, title, children }) => {
  if (!isOpen) return null;
  return (
    <div style={{
      position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex',
      alignItems: 'center', justifyContent: 'center', zIndex: 1000,
    }} onClick={onClose}>
      <div style={{
        backgroundColor: '#fff', borderRadius: '8px', padding: '24px',
        maxWidth: '600px', width: '90%', maxHeight: '80vh', overflow: 'auto',
      }} onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
          <h2 style={{ margin: 0, fontSize: '18px' }}>{title}</h2>
          <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer' }}>✕</button>
        </div>
        {children}
      </div>
    </div>
  );
};
