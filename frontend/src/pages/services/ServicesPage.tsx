import React, { useEffect, useState } from 'react';
import { serviceAPI } from '../../services/api';
import { Card, Button, Badge, Table, Modal, Input, Select } from '../../components/ui';
import type { Service } from '../../types';

export const ServicesPage: React.FC = () => {
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editService, setEditService] = useState<Service | null>(null);
  const [form, setForm] = useState({ name: '', description: '', type: 'INTERNET', monthlyRate: '', setupFee: '' });

  const loadServices = async () => {
    setLoading(true);
    try {
      const res = await serviceAPI.getAll();
      setServices(res.data);
    } finally { setLoading(false); }
  };

  useEffect(() => { loadServices(); }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const data = { ...form, monthlyRate: parseFloat(form.monthlyRate), setupFee: parseFloat(form.setupFee || '0') };
    if (editService) {
      await serviceAPI.update(editService.id, data);
    } else {
      await serviceAPI.create(data);
    }
    setShowModal(false);
    setEditService(null);
    setForm({ name: '', description: '', type: 'INTERNET', monthlyRate: '', setupFee: '' });
    loadServices();
  };

  const serviceColors: Record<string, string> = {
    INTERNET: '#4299e1', STARLINK: '#9f7aea', CCTV: '#48bb78', VOIP: '#ed8936', OTHER: '#718096',
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
        <h1 style={{ margin: 0, color: '#2d3748' }}>Services</h1>
        <Button onClick={() => { setEditService(null); setForm({ name: '', description: '', type: 'INTERNET', monthlyRate: '', setupFee: '' }); setShowModal(true); }}>
          + Add Service
        </Button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '16px' }}>
        {services.map(s => (
          <Card key={s.id} style={{ borderLeft: `4px solid ${serviceColors[s.type] || '#718096'}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
              <div>
                <h3 style={{ margin: 0, color: '#2d3748' }}>{s.name}</h3>
                <p style={{ margin: '4px 0', color: '#718096', fontSize: '13px' }}>{s.description}</p>
              </div>
              <Badge status={s.isActive ? 'Active' : 'Inactive'} />
            </div>
            <div style={{ marginTop: '12px', display: 'flex', gap: '16px' }}>
              <div>
                <div style={{ fontSize: '12px', color: '#718096' }}>Type</div>
                <div style={{ fontWeight: 500 }}>{s.type}</div>
              </div>
              <div>
                <div style={{ fontSize: '12px', color: '#718096' }}>Monthly Rate</div>
                <div style={{ fontWeight: 500, color: '#48bb78' }}>${Number(s.monthlyRate).toFixed(2)}</div>
              </div>
              <div>
                <div style={{ fontSize: '12px', color: '#718096' }}>Setup Fee</div>
                <div style={{ fontWeight: 500 }}>${Number(s.setupFee).toFixed(2)}</div>
              </div>
              <div>
                <div style={{ fontSize: '12px', color: '#718096' }}>Customers</div>
                <div style={{ fontWeight: 500 }}>{s._count?.customerServices || 0}</div>
              </div>
            </div>
            <div style={{ marginTop: '12px' }}>
              <button onClick={() => { setEditService(s); setForm({ name: s.name, description: s.description || '', type: s.type, monthlyRate: s.monthlyRate.toString(), setupFee: s.setupFee.toString() }); setShowModal(true); }} style={{ background: 'none', border: 'none', color: '#4299e1', cursor: 'pointer', fontSize: '13px' }}>Edit</button>
            </div>
          </Card>
        ))}
      </div>

      <Modal isOpen={showModal} onClose={() => { setShowModal(false); setEditService(null); }} title={editService ? 'Edit Service' : 'Add Service'}>
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
            <Input label="Monthly Rate ($)" type="number" value={form.monthlyRate} onChange={e => setForm({ ...form, monthlyRate: e.target.value })} required />
            <Input label="Setup Fee ($)" type="number" value={form.setupFee} onChange={e => setForm({ ...form, setupFee: e.target.value })} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
            <Button variant="secondary" onClick={() => { setShowModal(false); setEditService(null); }}>Cancel</Button>
            <Button type="submit">{editService ? 'Update' : 'Create'}</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
