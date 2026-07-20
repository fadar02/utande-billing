import React, { useEffect, useState } from 'react';
import { paymentAPI, invoiceAPI, customerAPI } from '../../services/api';
import { Card, Button, Badge, Table, Modal, Input, Select } from '../../components/ui';
import { useSettings } from '../../context/SettingsContext';
import type { Payment, Invoice, Customer } from '../../types';

export const PaymentsPage: React.FC = () => {
  const { formatMoney } = useSettings();
  const [payments, setPayments] = useState<Payment[]>([]);
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({ invoiceId: '', customerId: '', amount: '', paymentMethod: 'BANK_TRANSFER', reference: '', notes: '' });

  const loadPayments = async () => {
    setLoading(true);
    try {
      const res = await paymentAPI.getAll();
      setPayments(res.data.payments);
    } finally { setLoading(false); }
  };

  useEffect(() => {
    loadPayments();
    Promise.all([
      invoiceAPI.getAll({ status: 'PENDING' }).then(res => {
        const pending = res.data.invoices;
        Promise.all([
          invoiceAPI.getAll({ status: 'OVERDUE' }).then(r => r.data.invoices),
          invoiceAPI.getAll({ status: 'PARTIALLY_PAID' }).then(r => r.data.invoices),
        ]).then(([overdue, partial]) => {
          setInvoices([...pending, ...overdue, ...partial]);
        }).catch(() => setInvoices(pending));
      }),
      customerAPI.getAll().then(res => setCustomers(res.data.customers)),
    ]);
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await paymentAPI.record({
      ...form,
      amount: parseFloat(form.amount),
    });
    setShowModal(false);
    setForm({ invoiceId: '', customerId: '', amount: '', paymentMethod: 'BANK_TRANSFER', reference: '', notes: '' });
    loadPayments();
  };

  const handleSelectInvoice = (invoiceId: string) => {
    const inv = invoices.find(i => i.id === invoiceId);
    if (inv) {
      const balance = Number(inv.total) - Number(inv.amountPaid);
      setForm({ ...form, invoiceId, customerId: inv.customerId, amount: balance.toString() });
    }
  };

  const handleDownloadReceipt = async (id: string) => {
    const res = await paymentAPI.downloadReceipt(id);
    const url = window.URL.createObjectURL(new Blob([res.data]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `receipt-${id}.pdf`);
    document.body.appendChild(link);
    link.click();
  };

  const totalPayments = payments.reduce((sum, p) => sum + Number(p.amount), 0);

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
        <div>
          <h1 style={{ margin: 0, color: '#2d3748' }}>Payments</h1>
          <p style={{ margin: '4px 0 0', color: '#718096', fontSize: '14px' }}>
            Total: {formatMoney(totalPayments)} ({payments.length} payments)
          </p>
        </div>
        <Button onClick={() => setShowModal(true)}>+ Record Payment</Button>
      </div>

      <Card>
        <Table headers={['Payment #', 'Customer', 'Invoice', 'Amount', 'Method', 'Reference', 'Date', 'Actions']}>
          {payments.map(p => (
            <tr key={p.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
              <td style={{ padding: '10px 16px', fontWeight: 500 }}>{p.paymentNumber}</td>
              <td style={{ padding: '10px 16px' }}>{p.customer?.firstName} {p.customer?.lastName}</td>
              <td style={{ padding: '10px 16px' }}>{p.invoice?.invoiceNumber || '-'}</td>
              <td style={{ padding: '10px 16px', fontWeight: 600, color: '#48bb78' }}>{formatMoney(p.amount)}</td>
              <td style={{ padding: '10px 16px' }}>{p.paymentMethod}</td>
              <td style={{ padding: '10px 16px', fontSize: '12px' }}>{p.reference || '-'}</td>
              <td style={{ padding: '10px 16px' }}>{new Date(p.paymentDate).toLocaleDateString()}</td>
              <td style={{ padding: '10px 16px' }}>
                <button onClick={() => handleDownloadReceipt(p.id)} style={{ background: 'none', border: 'none', color: '#4299e1', cursor: 'pointer' }}>
                  Receipt
                </button>
              </td>
            </tr>
          ))}
        </Table>
      </Card>

      <Modal isOpen={showModal} onClose={() => setShowModal(false)} title="Record Payment">
        <form onSubmit={handleSubmit}>
          <Select label="Invoice" value={form.invoiceId} onChange={e => handleSelectInvoice(e.target.value)} required
            options={[{ value: '', label: 'Select invoice...' }, ...invoices.map(i => ({
              value: i.id, label: `${i.invoiceNumber} - ${formatMoney(Number(i.total) - Number(i.amountPaid))} outstanding`
            }))]} />
          <Select label="Customer" value={form.customerId} onChange={e => setForm({ ...form, customerId: e.target.value })} required
            options={[{ value: '', label: 'Select customer...' }, ...customers.map(c => ({
              value: c.id, label: `${c.firstName} ${c.lastName}`
            }))]} />
          <Input label="Amount" type="number" value={form.amount} onChange={e => setForm({ ...form, amount: e.target.value })} required />
          <Select label="Payment Method" value={form.paymentMethod} onChange={e => setForm({ ...form, paymentMethod: e.target.value })} options={[
            { value: 'CASH', label: 'Cash' },
            { value: 'BANK_TRANSFER', label: 'Bank Transfer' },
            { value: 'MOBILE_MONEY', label: 'Mobile Money' },
            { value: 'CARD', label: 'Card' },
            { value: 'CHEQUE', label: 'Cheque' },
            { value: 'OTHER', label: 'Other' },
          ]} required />
          <Input label="Reference" value={form.reference} onChange={e => setForm({ ...form, reference: e.target.value })} placeholder="Transaction reference" />
          <Input label="Notes" value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })} />

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '16px' }}>
            <Button variant="secondary" onClick={() => setShowModal(false)}>Cancel</Button>
            <Button type="submit">Record Payment</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
