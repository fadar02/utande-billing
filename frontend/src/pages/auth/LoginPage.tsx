import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

export const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email, password);
      navigate('/dashboard');
    } catch (err: any) {
      setError(err.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      backgroundColor: '#1a2332',
    }}>
      <div style={{
        backgroundColor: '#fff', borderRadius: '12px', padding: '40px',
        width: '100%', maxWidth: '400px', boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
      }}>
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <img src="/logo.png" alt="Utande" style={{ height: '64px', width: 'auto', objectFit: 'contain', marginBottom: '12px' }} />
          <h1 style={{ margin: 0, fontSize: '24px', color: '#2d3748' }}>Utande Billing</h1>
          <p style={{ color: '#718096', marginTop: '4px' }}>Smart Billing System</p>
        </div>

        {error && (
          <div style={{ backgroundColor: '#fed7d7', color: '#742a2a', padding: '10px', borderRadius: '6px', marginBottom: '16px', fontSize: '14px' }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', marginBottom: '4px', fontSize: '14px', fontWeight: 500 }}>Email</label>
            <input
              type="email" value={email} onChange={e => setEmail(e.target.value)}
              placeholder="admin@utande.com"
              style={{
                width: '100%', padding: '10px', border: '1px solid #e2e8f0',
                borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box',
              }}
            />
          </div>
          <div style={{ marginBottom: '24px' }}>
            <label style={{ display: 'block', marginBottom: '4px', fontSize: '14px', fontWeight: 500 }}>Password</label>
            <input
              type="password" value={password} onChange={e => setPassword(e.target.value)}
              placeholder="Enter password"
              style={{
                width: '100%', padding: '10px', border: '1px solid #e2e8f0',
                borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box',
              }}
            />
          </div>
          <button type="submit" disabled={loading} style={{
            width: '100%', padding: '12px', backgroundColor: '#4299e1', color: '#fff',
            border: 'none', borderRadius: '6px', fontSize: '14px', fontWeight: 600,
            cursor: loading ? 'not-allowed' : 'pointer', opacity: loading ? 0.6 : 1,
          }}>
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div style={{ marginTop: '20px', padding: '12px', backgroundColor: '#f7fafc', borderRadius: '6px', fontSize: '12px', color: '#718096' }}>
          <strong>Demo Accounts:</strong>
          <div>Admin: admin@utande.com / admin123</div>
          <div>Finance: finance@utande.com / finance123</div>
          <div>Sales: sales@utande.com / sales123</div>
        </div>
      </div>
    </div>
  );
};
