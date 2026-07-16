import React, { useEffect, useState } from 'react';
import { invoiceAPI, customerAPI } from '../../services/api';
import { Card, Button, Badge, Table, Modal, Input, Select } from '../../components/ui';
import { useSettings } from '../../context/SettingsContext';
import type { Invoice, Customer } from '../../types';

export const InvoicesPage: React.FC = () => {
  const { formatMoney } = useSettings();

  const getDaysOverdue = (dueDate: string) => {
    const due = new Date(dueDate);
    const now = new Date();
    const diff = Math.ceil((now.getTime() - due.getTime()) / (1000 * 60 * 60 * 24));
    return diff > 0 ? diff : 0;
  };

  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [selectedInvoice, setSelectedInvoice] = useState<Invoice | null>(null);
  const getDefaultDueDate = () => {
    const d = new Date();
    d.setDate(d.getDate() + 30);
    return d.toISOString().split('T')[0];
  };
  const [form, setForm] = useState({
    customerId: '', customerServiceId: '', items: [{ description: '', quantity: '1', unitPrice: '' }], taxRate: '0',
    dueDate: getDefaultDueDate(), description: '',
  });

  const handleCustomerChange = async (customerId: string) => {
    if (!customerId) {
      setForm({ ...form, customerId: '', customerServiceId: '', items: [{ description: '', quantity: '1', unitPrice: '' }] });
      return;
    }
    try {
      const res = await customerAPI.getById(customerId);
      const services = (res.data.services || []).filter((s: any) => s.status === 'ACTIVE');
      if (services.length > 0) {
        const items = services.map((s: any) => ({
          description: s.service?.name || '',
          quantity: '1',
          unitPrice: String(s.customRate || s.monthlyRate || 0),
        }));
        setForm({ ...form, customerId, customerServiceId: services[0].id, items });
      } else {
        setForm({ ...form, customerId, customerServiceId: '', items: [{ description: '', quantity: '1', unitPrice: '' }] });
      }
    } catch {
      setForm({ ...form, customerId, customerServiceId: '', items: [{ description: '', quantity: '1', unitPrice: '' }] });
    }
  };

  const loadInvoices = async () => {
    setLoading(true);
    try {
      const res = await invoiceAPI.getAll({ status: statusFilter });
      setInvoices(res.data.invoices);
    } finally { setLoading(false); }
  };

  useEffect(() => {
    loadInvoices();
    customerAPI.getAll().then(res => setCustomers(res.data.customers));
  }, [statusFilter]);

  const [error, setError] = useState('');

  const handleCreateInvoice = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    const validItems = form.items.filter(i => i.description.trim() && i.unitPrice && parseFloat(i.unitPrice) > 0);

    if (!form.customerId) { setError('Please select a customer'); return; }
    if (!form.dueDate) { setError('Please select a due date'); return; }
    if (validItems.length === 0) { setError('Add at least one invoice item with a description and price'); return; }

    try {
      const data = {
        customerId: form.customerId,
        customerServiceId: form.customerServiceId || undefined,
        items: validItems.map(i => ({
          description: i.description.trim(),
          quantity: parseFloat(i.quantity) || 1,
          unitPrice: parseFloat(i.unitPrice),
        })),
        taxRate: parseFloat(form.taxRate) || 0,
        dueDate: form.dueDate,
        description: form.description,
      };
      await invoiceAPI.create(data);
      setShowCreateModal(false);
      setError('');
      setForm({ customerId: '', customerServiceId: '', items: [{ description: '', quantity: '1', unitPrice: '' }], taxRate: '0', dueDate: getDefaultDueDate(), description: '' });
      loadInvoices();
    } catch (err: any) {
      setError(err.response?.data?.error || 'Failed to create invoice');
    }
  };

  const handleDownloadPDF = async (id: string) => {
    const res = await invoiceAPI.downloadPDF(id);
    const url = window.URL.createObjectURL(new Blob([res.data]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `invoice-${id}.pdf`);
    document.body.appendChild(link);
    link.click();
  };

  const totalAmount = invoices.reduce((sum, inv) => sum + Number(inv.total), 0);
  const totalOutstanding = invoices.filter(i => i.status !== 'PAID' && i.status !== 'CANCELLED')
    .reduce((sum, inv) => sum + Number(inv.total) - Number(inv.amountPaid), 0);

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
        <div>
          <h1 style={{ margin: 0, color: '#2d3748' }}>Invoices</h1>
          <p style={{ margin: '4px 0 0', color: '#718096', fontSize: '14px' }}>
            Total: {formatMoney(totalAmount)} | Outstanding: {formatMoney(totalOutstanding)}
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          <Button onClick={() => setShowCreateModal(true)}>+ New Invoice</Button>
        </div>
      </div>

      <Card>
        <div style={{ display: 'flex', gap: '8px', marginBottom: '16px' }}>
          {['', 'PENDING', 'PAID', 'OVERDUE', 'PARTIALLY_PAID'].map(s => (
            <button key={s} onClick={() => setStatusFilter(s)} style={{
              padding: '6px 12px', border: '1px solid #e2e8f0', borderRadius: '16px',
              backgroundColor: statusFilter === s ? '#4299e1' : '#fff',
              color: statusFilter === s ? '#fff' : '#4a5568', cursor: 'pointer', fontSize: '13px',
            }}>
              {s || 'All'}
            </button>
          ))}
        </div>

        <Table headers={['Invoice #', 'Customer', 'Total', 'Paid', 'Balance', 'Status', 'Due Date', 'Actions']}>
          {invoices.map(inv => (
            <tr key={inv.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
              <td style={{ padding: '10px 16px', fontWeight: 500 }}>{inv.invoiceNumber}</td>
              <td style={{ padding: '10px 16px' }}>{inv.customer?.firstName} {inv.customer?.lastName}</td>
              <td style={{ padding: '10px 16px' }}>{formatMoney(inv.total)}</td>
              <td style={{ padding: '10px 16px', color: '#48bb78' }}>{formatMoney(inv.amountPaid)}</td>
              <td style={{ padding: '10px 16px', fontWeight: 500, color: Number(inv.total) - Number(inv.amountPaid) > 0 ? '#e53e3e' : '#48bb78' }}>
                {formatMoney(Number(inv.total) - Number(inv.amountPaid))}
              </td>
              <td style={{ padding: '10px 16px' }}><Badge status={inv.status} daysOverdue={getDaysOverdue(inv.dueDate)} /></td>
              <td style={{ padding: '10px 16px' }}>{new Date(inv.dueDate).toLocaleDateString()}</td>
              <td style={{ padding: '10px 16px' }}>
                <button onClick={() => setSelectedInvoice(inv)} style={{ background: 'none', border: 'none', color: '#4299e1', cursor: 'pointer', marginRight: '8px' }}>View</button>
                <button onClick={() => handleDownloadPDF(inv.id)} style={{ background: 'none', border: 'none', color: '#48bb78', cursor: 'pointer' }}>PDF</button>
              </td>
            </tr>
          ))}
        </Table>
      </Card>

      {/* Create Invoice Modal */}
      <Modal isOpen={showCreateModal} onClose={() => setShowCreateModal(false)} title="Create Invoice">
        <form onSubmit={handleCreateInvoice}>
          <Select label="Customer" value={form.customerId} onChange={e => handleCustomerChange(e.target.value)} required
            options={[{ value: '', label: 'Select customer...' }, ...customers.map(c => ({ value: c.id, label: `${c.firstName} ${c.lastName} (${c.customerCode})` }))]} />
          <Input label="Due Date" type="date" value={form.dueDate} onChange={e => setForm({ ...form, dueDate: e.target.value })} required min="2024-01-01" />
          <Input label="Description" value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
          <Input label="Tax Rate (%)" type="number" value={form.taxRate} onChange={e => setForm({ ...form, taxRate: e.target.value })} />

          <h4 style={{ marginBottom: '8px' }}>Invoice Items</h4>
          {error && (
            <div style={{ backgroundColor: '#fed7d7', color: '#742a2a', padding: '10px', borderRadius: '6px', marginBottom: '12px', fontSize: '13px' }}>
              {error}
            </div>
          )}
          {form.items.map((item, idx) => (
            <div key={idx} style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr auto', gap: '8px', marginBottom: '8px', alignItems: 'end' }}>
              <Input label="" value={item.description} onChange={e => {
                const items = [...form.items]; items[idx].description = e.target.value; setForm({ ...form, items });
              }} placeholder="Description" />
              <Input label="" value={item.quantity} onChange={e => {
                const items = [...form.items]; items[idx].quantity = e.target.value; setForm({ ...form, items });
              }} placeholder="Qty" type="number" />
              <Input label="" value={item.unitPrice} onChange={e => {
                const items = [...form.items]; items[idx].unitPrice = e.target.value; setForm({ ...form, items });
              }} placeholder="Unit Price" type="number" />
              {form.items.length > 1 && (
                <button type="button" onClick={() => {
                  const items = form.items.filter((_, i) => i !== idx); setForm({ ...form, items });
                }} style={{ background: 'none', border: 'none', color: '#e53e3e', cursor: 'pointer', fontSize: '18px', padding: '4px' }}>✕</button>
              )}
            </div>
          ))}
          <Button variant="secondary" onClick={() => setForm({ ...form, items: [...form.items, { description: '', quantity: '1', unitPrice: '' }] })}>
            + Add Item
          </Button>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
            <Button variant="secondary" onClick={() => setShowCreateModal(false)}>Cancel</Button>
            <Button type="submit">Create Invoice</Button>
          </div>
        </form>
      </Modal>

      {/* View Invoice Modal */}
      <Modal isOpen={!!selectedInvoice} onClose={() => setSelectedInvoice(null)} title={`Invoice ${selectedInvoice?.invoiceNumber}`}>
        {selectedInvoice && (
          <div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div>
                <p><strong>Customer:</strong> {selectedInvoice.customer?.firstName} {selectedInvoice.customer?.lastName}</p>
                <p><strong>Email:</strong> {selectedInvoice.customer?.email}</p>
                <p><strong>Phone:</strong> {selectedInvoice.customer?.phone}</p>
              </div>
              <div>
                <p><strong>Status:</strong> <Badge status={selectedInvoice.status} daysOverdue={getDaysOverdue(selectedInvoice.dueDate)} /></p>
                <p><strong>Due Date:</strong> {new Date(selectedInvoice.dueDate).toLocaleDateString()}</p>
                <p><strong>Total:</strong> {formatMoney(selectedInvoice.total)}</p>
                <p><strong>Paid:</strong> {formatMoney(selectedInvoice.amountPaid)}</p>
                <p><strong>Balance:</strong> {formatMoney(Number(selectedInvoice.total) - Number(selectedInvoice.amountPaid))}</p>
              </div>
            </div>
            {selectedInvoice.items && (
              <div style={{ marginTop: '16px' }}>
                <h4>Items</h4>
                <Table headers={['Description', 'Qty', 'Price', 'Amount']}>
                  {selectedInvoice.items.map(item => (
                    <tr key={item.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                      <td style={{ padding: '8px 12px' }}>{item.description}</td>
                      <td style={{ padding: '8px 12px' }}>{item.quantity}</td>
                      <td style={{ padding: '8px 12px' }}>{formatMoney(item.unitPrice)}</td>
                      <td style={{ padding: '8px 12px' }}>{formatMoney(item.amount)}</td>
                    </tr>
                  ))}
                </Table>
              </div>
            )}
            <div style={{ display: 'flex', gap: '8px', marginTop: '16px' }}>
              <Button variant="success" onClick={() => handleDownloadPDF(selectedInvoice.id)}>Download PDF</Button>
              {selectedInvoice.status !== 'PAID' && selectedInvoice.status !== 'CANCELLED' && (
                <Button variant="danger" onClick={async () => { await invoiceAPI.cancel(selectedInvoice.id); setSelectedInvoice(null); loadInvoices(); }}>
                  Cancel Invoice
                </Button>
              )}
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
