import React, { useEffect, useState } from 'react';
import { customerAPI } from '../../services/api';
import { Card, Button, Input, Badge, Table, Modal } from '../../components/ui';
import { useSettings } from '../../context/SettingsContext';
import type { Customer } from '../../types';

export const CustomersPage: React.FC = () => {
  const { formatMoney } = useSettings();
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editCustomer, setEditCustomer] = useState<Customer | null>(null);
  const [form, setForm] = useState({ firstName: '', lastName: '', email: '', phone: '', notes: '' });

  const [showEmailModal, setShowEmailModal] = useState(false);
  const [emailCustomer, setEmailCustomer] = useState<Customer | null>(null);
  const [emailForm, setEmailForm] = useState({ subject: '', message: '' });
  const [emailSending, setEmailSending] = useState(false);
  const [emailSuccess, setEmailSuccess] = useState('');
  const [emailError, setEmailError] = useState('');
  const [expandedCustomer, setExpandedCustomer] = useState<string | null>(null);

  const loadCustomers = async () => {
    setLoading(true);
    try {
      const res = await customerAPI.getAll({ search, status: statusFilter });
      setCustomers(res.data.customers);
    } finally { setLoading(false); }
  };

  useEffect(() => { loadCustomers(); }, [search, statusFilter]);

  const [formError, setFormError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError('');
    try {
      if (editCustomer) {
        await customerAPI.update(editCustomer.id, form);
      } else {
        await customerAPI.create(form);
      }
      setShowModal(false);
      setEditCustomer(null);
      setForm({ firstName: '', lastName: '', email: '', phone: '', notes: '' });
      loadCustomers();
    } catch (err: any) {
      setFormError(err.response?.data?.error || err.response?.data?.message || 'Failed to save customer');
    }
  };

  const handleEdit = (c: Customer) => {
    setEditCustomer(c);
    setForm({ firstName: c.firstName, lastName: c.lastName, email: c.email, phone: c.phone, notes: c.notes || '' });
    setShowModal(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this customer?')) {
      await customerAPI.delete(id);
      loadCustomers();
    }
  };

  const openEmailModal = (c: Customer) => {
    setEmailCustomer(c);
    setEmailForm({ subject: '', message: '' });
    setEmailSuccess('');
    setEmailError('');
    setShowEmailModal(true);
  };

  const handleSendEmail = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!emailCustomer) return;
    setEmailSending(true);
    setEmailError('');
    setEmailSuccess('');
    try {
      await customerAPI.sendEmail(emailCustomer.id, emailForm);
      setEmailSuccess(`Email sent to ${emailCustomer.email}!`);
      setEmailForm({ subject: '', message: '' });
    } catch (err: any) {
      setEmailError(err.response?.data?.error || 'Failed to send email');
    } finally {
      setEmailSending(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
        <h1 style={{ margin: 0, color: '#2d3748' }}>Customers</h1>
        <Button onClick={() => { setEditCustomer(null); setForm({ firstName: '', lastName: '', email: '', phone: '', notes: '' }); setShowModal(true); }}>
          + Add Customer
        </Button>
      </div>

      <Card>
        <div style={{ display: 'flex', gap: '12px', marginBottom: '16px' }}>
          <input
            placeholder="Search customers..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            style={{ flex: 1, padding: '8px 12px', border: '1px solid #e2e8f0', borderRadius: '6px', fontSize: '14px' }}
          />
          <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} style={{ padding: '8px 12px', border: '1px solid #e2e8f0', borderRadius: '6px' }}>
            <option value="">All Status</option>
            <option value="ACTIVE">Active</option>
            <option value="SUSPENDED">Suspended</option>
            <option value="INACTIVE">Inactive</option>
          </select>
        </div>

        <Table headers={['Code', 'Name', 'Email', 'Phone', 'Balance', 'Packages', 'Status', 'Actions']}>
          {customers.map(c => (
            <React.Fragment key={c.id}>
              <tr style={{ borderBottom: '1px solid #e2e8f0' }}>
                <td style={{ padding: '10px 16px', fontWeight: 500 }}>{c.customerCode}</td>
                <td style={{ padding: '10px 16px' }}>{c.firstName} {c.lastName}</td>
                <td style={{ padding: '10px 16px' }}>{c.email}</td>
                <td style={{ padding: '10px 16px' }}>{c.phone}</td>
                <td style={{ padding: '10px 16px' }}>
                  <button
                    onClick={() => setExpandedCustomer(expandedCustomer === c.id ? null : c.id)}
                    style={{
                      background: 'none', border: 'none', cursor: 'pointer', padding: '4px 8px',
                      borderRadius: '4px', fontSize: '13px', fontWeight: 600,
                      color: (c as any).balance > 0 ? '#e53e3e' : '#38a169',
                      backgroundColor: (c as any).balance > 0 ? '#fff5f5' : '#f0fff4',
                    }}
                    title="Click to view packages breakdown"
                  >
                    {(c as any).balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                    <span style={{ fontSize: '10px', marginLeft: '4px' }}>{expandedCustomer === c.id ? '▲' : '▼'}</span>
                  </button>
                </td>
                <td style={{ padding: '10px 16px' }}>
                  {c.services && c.services.length > 0 ? (
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                      {c.services.map((cs: any) => (
                        <span key={cs.id} style={{ padding: '2px 6px', borderRadius: '4px', fontSize: '11px', backgroundColor: cs.status === 'ACTIVE' ? '#c6f6d5' : '#fed7d7', color: cs.status === 'ACTIVE' ? '#22543d' : '#742a2a' }}>
                          {cs.service?.name || 'Package'}
                        </span>
                      ))}
                    </div>
                  ) : <span style={{ color: '#a0aec0', fontSize: '12px' }}>None</span>}
                </td>
                <td style={{ padding: '10px 16px' }}><Badge status={c.status} /></td>
                <td style={{ padding: '10px 16px', whiteSpace: 'nowrap' }}>
                  <button onClick={() => openEmailModal(c)} style={{ marginRight: '6px', background: 'none', border: 'none', cursor: 'pointer', color: '#48bb78', fontSize: '13px' }} title="Send Email">Email</button>
                  <button onClick={() => handleEdit(c)} style={{ marginRight: '6px', background: 'none', border: 'none', cursor: 'pointer', color: '#4299e1', fontSize: '13px' }}>Edit</button>
                  <button onClick={() => handleDelete(c.id)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#e53e3e', fontSize: '13px' }}>Delete</button>
                </td>
              </tr>
              {expandedCustomer === c.id && (
                <tr style={{ borderBottom: '1px solid #e2e8f0' }}>
                  <td colSpan={8} style={{ padding: '0 16px 12px', backgroundColor: '#f7fafc' }}>
                    <div style={{ padding: '12px', borderRadius: '6px' }}>
                      <div style={{ fontSize: '13px', fontWeight: 600, color: '#2d3748', marginBottom: '8px' }}>
                        Packages
                      </div>
                      {c.services && c.services.length > 0 ? (
                        <table style={{ width: '100%', fontSize: '12px', borderCollapse: 'collapse' }}>
                          <thead>
                            <tr style={{ borderBottom: '1px solid #e2e8f0' }}>
                              <th style={{ textAlign: 'left', padding: '6px 8px', color: '#718096' }}>Package</th>
                              <th style={{ textAlign: 'left', padding: '6px 8px', color: '#718096' }}>Type</th>
                              <th style={{ textAlign: 'right', padding: '6px 8px', color: '#718096' }}>Monthly Rate</th>
                              <th style={{ textAlign: 'left', padding: '6px 8px', color: '#718096' }}>Status</th>
                              <th style={{ textAlign: 'left', padding: '6px 8px', color: '#718096' }}>Since</th>
                            </tr>
                          </thead>
                          <tbody>
                            {c.services.map((cs: any) => (
                              <tr key={cs.id} style={{ borderBottom: '1px solid #edf2f7' }}>
                                <td style={{ padding: '6px 8px', fontWeight: 500 }}>{cs.service?.name || 'N/A'}</td>
                                <td style={{ padding: '6px 8px' }}>{cs.service?.type || '-'}</td>
                                <td style={{ padding: '6px 8px', textAlign: 'right' }}>{formatMoney(cs.service?.monthlyRate || 0)}/mo</td>
                                <td style={{ padding: '6px 8px' }}>
                                  <span style={{ padding: '2px 6px', borderRadius: '4px', fontSize: '11px', backgroundColor: cs.status === 'ACTIVE' ? '#c6f6d5' : '#fed7d7', color: cs.status === 'ACTIVE' ? '#22543d' : '#742a2a' }}>
                                    {cs.status}
                                  </span>
                                </td>
                                <td style={{ padding: '6px 8px', color: '#718096' }}>{new Date(cs.startDate).toLocaleDateString()}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      ) : (
                        <div style={{ color: '#a0aec0', fontSize: '12px', padding: '8px' }}>No packages assigned</div>
                      )}
                      <div style={{ marginTop: '8px', fontSize: '12px', color: '#718096' }}>
                        Total Outstanding: <strong style={{ color: '#e53e3e' }}>{(c as any).balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}</strong>
                        {c.services.length > 0 && (
                          <span style={{ marginLeft: '16px' }}>
                            Monthly Commitment: <strong>{formatMoney(c.services.reduce((sum: number, cs: any) => sum + Number(cs.service?.monthlyRate || 0), 0))}/mo</strong>
                          </span>
                        )}
                      </div>
                    </div>
                  </td>
                </tr>
              )}
            </React.Fragment>
          ))}
        </Table>
        {customers.length === 0 && <div style={{ padding: '20px', textAlign: 'center', color: '#718096' }}>No customers found</div>}
      </Card>

      {/* Add/Edit Customer Modal */}
      <Modal isOpen={showModal} onClose={() => { setShowModal(false); setEditCustomer(null); }} title={editCustomer ? 'Edit Customer' : 'Add Customer'}>
        <form onSubmit={handleSubmit}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <Input label="First Name" value={form.firstName} onChange={e => setForm({ ...form, firstName: e.target.value })} required />
            <Input label="Last Name" value={form.lastName} onChange={e => setForm({ ...form, lastName: e.target.value })} required />
          </div>
          <Input label="Email" type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} required />
          <Input label="Phone" value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} required />
          <Input label="Notes" value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })} />

          {formError && (
            <div style={{ padding: '10px', backgroundColor: '#fed7d7', color: '#742a2a', borderRadius: '6px', marginTop: '12px', fontSize: '13px' }}>
              {formError}
            </div>
          )}

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
            <Button variant="secondary" onClick={() => { setShowModal(false); setEditCustomer(null); }}>Cancel</Button>
            <Button type="submit">{editCustomer ? 'Update' : 'Create'}</Button>
          </div>
        </form>
      </Modal>

      {/* Send Email Modal */}
      <Modal isOpen={showEmailModal} onClose={() => setShowEmailModal(false)} title={`Email ${emailCustomer?.firstName} ${emailCustomer?.lastName}`}>
        {emailCustomer && (
          <div>
            <div style={{ padding: '10px', backgroundColor: '#f7fafc', borderRadius: '6px', marginBottom: '16px', fontSize: '13px' }}>
              <strong>To:</strong> {emailCustomer.email}
            </div>

            {emailSuccess && (
              <div style={{ padding: '10px', backgroundColor: '#c6f6d5', color: '#22543d', borderRadius: '6px', marginBottom: '12px', fontSize: '13px' }}>
                {emailSuccess}
              </div>
            )}
            {emailError && (
              <div style={{ padding: '10px', backgroundColor: '#fed7d7', color: '#742a2a', borderRadius: '6px', marginBottom: '12px', fontSize: '13px' }}>
                {emailError}
              </div>
            )}

            <form onSubmit={handleSendEmail}>
              <Input label="Subject" value={emailForm.subject} onChange={e => setEmailForm({ ...emailForm, subject: e.target.value })} required placeholder="e.g. Payment Reminder" />
              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', marginBottom: '4px', fontSize: '14px', color: '#4a5568', fontWeight: 500 }}>
                  Message <span style={{ color: '#e53e3e' }}>*</span>
                </label>
                <textarea
                  value={emailForm.message}
                  onChange={e => setEmailForm({ ...emailForm, message: e.target.value })}
                  placeholder="Type your message here..."
                  required
                  rows={6}
                  style={{
                    width: '100%', padding: '8px 12px', border: '1px solid #e2e8f0',
                    borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box', resize: 'vertical',
                  }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
                <Button variant="secondary" onClick={() => setShowEmailModal(false)}>Cancel</Button>
                <Button type="submit" disabled={emailSending}>
                  {emailSending ? 'Sending...' : 'Send Email'}
                </Button>
              </div>
            </form>
          </div>
        )}
      </Modal>
    </div>
  );
};
