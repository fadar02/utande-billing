import React, { useEffect, useState } from 'react';
import { authAPI } from '../../services/api';
import { Card, Badge, Table, Button, Modal, Input, Select } from '../../components/ui';
import type { User } from '../../types';

export const UsersPage: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({ email: '', password: '', firstName: '', lastName: '', role: 'SALES' });

  const loadUsers = async () => {
    setLoading(true);
    try {
      const res = await authAPI.getUsers();
      setUsers(res.data);
    } finally { setLoading(false); }
  };

  useEffect(() => { loadUsers(); }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    await authAPI.register(form);
    setShowModal(false);
    setForm({ email: '', password: '', firstName: '', lastName: '', role: 'SALES' });
    loadUsers();
  };

  const handleToggleActive = async (user: User) => {
    await authAPI.updateUser(user.id, { isActive: !user.isActive });
    loadUsers();
  };

  const roleColors: Record<string, string> = {
    ADMIN: '#e53e3e', FINANCE: '#48bb78', SALES: '#4299e1', TECHNICAL: '#9f7aea',
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
        <h1 style={{ margin: 0, color: '#2d3748' }}>User Management</h1>
        <Button onClick={() => setShowModal(true)}>+ Add User</Button>
      </div>

      <Card>
        <Table headers={['Name', 'Email', 'Role', 'Status', 'Last Login', 'Actions']}>
          {users.map(u => (
            <tr key={u.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
              <td style={{ padding: '10px 16px', fontWeight: 500 }}>{u.firstName} {u.lastName}</td>
              <td style={{ padding: '10px 16px' }}>{u.email}</td>
              <td style={{ padding: '10px 16px' }}>
                <span style={{ padding: '2px 8px', borderRadius: '4px', backgroundColor: roleColors[u.role] + '20', color: roleColors[u.role], fontSize: '12px', fontWeight: 600 }}>
                  {u.role}
                </span>
              </td>
              <td style={{ padding: '10px 16px' }}><Badge status={u.isActive ? 'Active' : 'Inactive'} /></td>
              <td style={{ padding: '10px 16px', fontSize: '12px' }}>{u.lastLogin ? new Date(u.lastLogin).toLocaleString() : 'Never'}</td>
              <td style={{ padding: '10px 16px' }}>
                <button onClick={() => handleToggleActive(u)} style={{
                  background: 'none', border: 'none', color: u.isActive ? '#e53e3e' : '#48bb78', cursor: 'pointer', fontSize: '12px',
                }}>
                  {u.isActive ? 'Deactivate' : 'Activate'}
                </button>
              </td>
            </tr>
          ))}
        </Table>
      </Card>

      <Modal isOpen={showModal} onClose={() => setShowModal(false)} title="Add User">
        <form onSubmit={handleCreate}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <Input label="First Name" value={form.firstName} onChange={e => setForm({ ...form, firstName: e.target.value })} required />
            <Input label="Last Name" value={form.lastName} onChange={e => setForm({ ...form, lastName: e.target.value })} required />
          </div>
          <Input label="Email" type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} required />
          <Input label="Password" type="password" value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} required />
          <Select label="Role" value={form.role} onChange={e => setForm({ ...form, role: e.target.value })} options={[
            { value: 'ADMIN', label: 'Administrator' },
            { value: 'FINANCE', label: 'Finance Officer' },
            { value: 'SALES', label: 'Sales Officer' },
            { value: 'TECHNICAL', label: 'Technical Team' },
          ]} required />
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
            <Button variant="secondary" onClick={() => setShowModal(false)}>Cancel</Button>
            <Button type="submit">Create User</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
