import React, { useEffect, useState } from 'react';
import { serviceAPI } from '../../services/api';
import { Card, Button, Badge, Modal, Input, Select } from '../../components/ui';
import { useSettings } from '../../context/SettingsContext';
import type { Service } from '../../types';

export const PackagesPage: React.FC = () => {
  const { formatMoney } = useSettings();
  const [packages, setPackages] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editPkg, setEditPkg] = useState<Service | null>(null);
  const [form, setForm] = useState({ name: '', description: '', type: 'INTERNET', monthlyRate: '', setupFee: '' });

  const loadPackages = async () => {
    setLoading(true);
    try {
      const res = await serviceAPI.getAll();
      setPackages(res.data);
    } finally { setLoading(false); }
  };

  useEffect(() => { loadPackages(); }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const data = { ...form, monthlyRate: parseFloat(form.monthlyRate), setupFee: parseFloat(form.setupFee || '0') };
    if (editPkg) {
      await serviceAPI.update(editPkg.id, data);
    } else {
      await serviceAPI.create(data);
    }
    setShowModal(false);
    setEditPkg(null);
    setForm({ name: '', description: '', type: 'INTERNET', monthlyRate: '', setupFee: '' });
    loadPackages();
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this package?')) {
      await serviceAPI.delete(id);
      loadPackages();
    }
  };

  const typeColors: Record<string, string> = {
    INTERNET: '#4299e1', STARLINK: '#9f7aea', CCTV: '#48bb78', VOIP: '#ed8936', OTHER: '#718096',
  };

  if (loading) return <div style={{ padding: '40px', textAlign: 'center', color: '#718096' }}>Loading packages...</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
        <h1 style={{ margin: 0, color: '#2d3748' }}>Packages</h1>
        <Button onClick={() => { setEditPkg(null); setForm({ name: '', description: '', type: 'INTERNET', monthlyRate: '', setupFee: '' }); setShowModal(true); }}>
          + Add Package
        </Button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '16px' }}>
        {packages.map(pkg => (
          <Card key={pkg.id} style={{ borderLeft: `4px solid ${typeColors[pkg.type] || '#718096'}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
              <div>
                <h3 style={{ margin: 0, color: '#2d3748' }}>{pkg.name}</h3>
                <p style={{ margin: '4px 0', color: '#718096', fontSize: '13px' }}>{pkg.description}</p>
              </div>
              <Badge status={pkg.isActive ? 'Active' : 'Inactive'} />
            </div>
            <div style={{ marginTop: '12px', display: 'flex', gap: '16px' }}>
              <div>
                <div style={{ fontSize: '12px', color: '#718096' }}>Type</div>
                <div style={{ fontWeight: 500 }}>{pkg.type}</div>
              </div>
              <div>
                <div style={{ fontSize: '12px', color: '#718096' }}>Monthly Rate</div>
                <div style={{ fontWeight: 500, color: '#48bb78' }}>{formatMoney(pkg.monthlyRate)}</div>
              </div>
              <div>
                <div style={{ fontSize: '12px', color: '#718096' }}>Setup Fee</div>
                <div style={{ fontWeight: 500 }}>{formatMoney(pkg.setupFee)}</div>
              </div>
              <div>
                <div style={{ fontSize: '12px', color: '#718096' }}>Customers</div>
                <div style={{ fontWeight: 500 }}>{pkg._count?.customerServices || 0}</div>
              </div>
            </div>
            <div style={{ marginTop: '12px', display: 'flex', gap: '12px' }}>
              <button
                onClick={() => { setEditPkg(pkg); setForm({ name: pkg.name, description: pkg.description || '', type: pkg.type, monthlyRate: pkg.monthlyRate.toString(), setupFee: pkg.setupFee.toString() }); setShowModal(true); }}
                style={{ background: 'none', border: 'none', color: '#4299e1', cursor: 'pointer', fontSize: '13px' }}
              >
                Edit
              </button>
              <button
                onClick={() => handleDelete(pkg.id)}
                style={{ background: 'none', border: 'none', color: '#e53e3e', cursor: 'pointer', fontSize: '13px' }}
              >
                Delete
              </button>
            </div>
          </Card>
        ))}
      </div>

      {packages.length === 0 && (
        <div style={{ padding: '40px', textAlign: 'center', color: '#718096' }}>No packages found. Create your first package.</div>
      )}

      <Modal isOpen={showModal} onClose={() => { setShowModal(false); setEditPkg(null); }} title={editPkg ? 'Edit Package' : 'Add Package'}>
        <form onSubmit={handleSubmit}>
          <Input label="Name" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required />
          <Input label="Description" value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
          <Select label="Type" value={form.type} onChange={e => setForm({ ...form, type: e.target.value })} options={[
            { value: 'INTERNET', label: 'Internet' },
            { value: 'STARLINK', label: 'Starlink' },
            { value: 'CCTV', label: 'CCTV' },
            { value: 'VOIP', label: 'VoIP' },
            { value: 'OTHER', label: 'Other' },
          ]} required />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <Input label="Monthly Rate" type="number" value={form.monthlyRate} onChange={e => setForm({ ...form, monthlyRate: e.target.value })} required />
            <Input label="Setup Fee" type="number" value={form.setupFee} onChange={e => setForm({ ...form, setupFee: e.target.value })} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
            <Button variant="secondary" onClick={() => { setShowModal(false); setEditPkg(null); }}>Cancel</Button>
            <Button type="submit">{editPkg ? 'Update' : 'Create'}</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
