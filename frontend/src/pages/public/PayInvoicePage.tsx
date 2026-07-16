import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import axios from 'axios';
import { useSettings } from '../../context/SettingsContext';

interface InvoiceData {
  id: string;
  invoiceNumber: string;
  status: string;
  total: number;
  taxRate: number;
  taxAmount: number;
  description: string;
  dueDate: string;
  billingPeriodStart: string;
  billingPeriodEnd: string;
  createdAt: string;
  items: { description: string; quantity: number; unitPrice: number; amount: number }[];
  customer: { firstName: string; lastName: string; email: string; phone: string; customerCode: string };
  serviceName: string;
  payments: { number: string; amount: number; method: string; date: string }[];
  balance: number;
}

const API = axios.create({ baseURL: 'http://localhost:3000/api/public' });

export const PayInvoicePage: React.FC = () => {
  const { formatMoney } = useSettings();
  const { id } = useParams<{ id: string }>();
  const [invoice, setInvoice] = useState<InvoiceData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [payAmount, setPayAmount] = useState('');
  const [payMethod, setPayMethod] = useState('CASH');
  const [payRef, setPayRef] = useState('');
  const [paying, setPaying] = useState(false);
  const [paySuccess, setPaySuccess] = useState('');
  const [payError, setPayError] = useState('');

  useEffect(() => {
    if (!id) return;
    API.get(`/invoices/${id}`)
      .then(res => {
        setInvoice(res.data);
        setPayAmount(res.data.balance.toFixed(2));
      })
      .catch(() => setError('Invoice not found'))
      .finally(() => setLoading(false));
  }, [id]);

  const handlePay = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!id) return;
    setPaying(true);
    setPayError('');
    setPaySuccess('');
    try {
      const res = await API.post(`/invoices/${id}/pay`, {
        amount: parseFloat(payAmount),
        paymentMethod: payMethod,
        reference: payRef || undefined,
      });
      setPaySuccess(`Payment successful! Receipt: ${res.data.payment.paymentNumber}`);
      // Refresh invoice
      const updated = await API.get(`/invoices/${id}`);
      setInvoice(updated.data);
      setPayAmount(updated.data.balance.toFixed(2));
    } catch (err: any) {
      setPayError(err.response?.data?.error || 'Payment failed');
    } finally {
      setPaying(false);
    }
  };

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f7fafc' }}>
      <p style={{ color: '#718096' }}>Loading invoice...</p>
    </div>
  );

  if (error) return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f7fafc' }}>
      <div style={{ textAlign: 'center' }}>
        <img src="/logo.png" alt="Utande" style={{ height: '48px', marginBottom: '16px' }} />
        <p style={{ color: '#e53e3e', fontSize: '18px' }}>{error}</p>
      </div>
    </div>
  );

  if (!invoice) return null;

  const isPaid = invoice.status === 'PAID' || invoice.balance <= 0;

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f7fafc', fontFamily: 'Arial, sans-serif' }}>
      <div style={{ backgroundColor: '#1a2332', padding: '16px 0' }}>
        <div style={{ maxWidth: '800px', margin: '0 auto', padding: '0 24px', display: 'flex', alignItems: 'center', gap: '12px' }}>
          <img src="/logo.png" alt="Utande" style={{ height: '40px' }} />
          <div>
            <h1 style={{ color: '#fff', margin: 0, fontSize: '20px' }}>Utande Billing</h1>
            <p style={{ color: '#a0aec0', margin: 0, fontSize: '12px' }}>Smart Billing System</p>
          </div>
        </div>
      </div>

      <div style={{ maxWidth: '800px', margin: '0 auto', padding: '24px' }}>
        <div style={{ backgroundColor: '#fff', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', overflow: 'hidden' }}>
          <div style={{ padding: '24px', borderBottom: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '12px' }}>
            <div>
              <h2 style={{ margin: 0, fontSize: '22px', color: '#2d3748' }}>Invoice {invoice.invoiceNumber}</h2>
              <p style={{ margin: '4px 0 0', color: '#718096', fontSize: '14px' }}>
                For: {invoice.customer.firstName} {invoice.customer.lastName} ({invoice.customer.customerCode})
              </p>
              {invoice.serviceName && <p style={{ margin: '2px 0 0', color: '#718096', fontSize: '13px' }}>Service: {invoice.serviceName}</p>}
            </div>
            <div style={{ textAlign: 'right' }}>
              <span style={{
                display: 'inline-block', padding: '4px 12px', borderRadius: '12px', fontSize: '13px', fontWeight: 600,
                backgroundColor: isPaid ? '#c6f6d5' : invoice.status === 'OVERDUE' ? '#fed7d7' : invoice.status === 'CANCELLED' ? '#e2e8f0' : '#fefcbf',
                color: isPaid ? '#22543d' : invoice.status === 'OVERDUE' ? '#742a2a' : invoice.status === 'CANCELLED' ? '#4a5568' : '#744210',
              }}>
                {isPaid ? 'PAID' : invoice.status}
              </span>
            </div>
          </div>

          <div style={{ padding: '24px', borderBottom: '1px solid #e2e8f0' }}>
            <div style={{ display: 'grid', gridTemplateColumns: invoice.billingPeriodStart ? '1fr 1fr 1fr' : '1fr 1fr', gap: '16px', fontSize: '14px' }}>
              <div>
                <div style={{ color: '#718096', marginBottom: '2px' }}>Invoice Date</div>
                <div style={{ fontWeight: 500 }}>{new Date(invoice.createdAt).toLocaleDateString()}</div>
              </div>
              <div>
                <div style={{ color: '#718096', marginBottom: '2px' }}>Due Date</div>
                <div style={{ fontWeight: 500 }}>{new Date(invoice.dueDate).toLocaleDateString()}</div>
              </div>
              {invoice.billingPeriodStart && (
                <div>
                  <div style={{ color: '#718096', marginBottom: '2px' }}>Billing Period</div>
                  <div style={{ fontWeight: 500 }}>
                    {new Date(invoice.billingPeriodStart).toLocaleDateString()} - {new Date(invoice.billingPeriodEnd).toLocaleDateString()}
                  </div>
                </div>
              )}
            </div>
          </div>

          <div style={{ padding: '24px', borderBottom: '1px solid #e2e8f0' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px' }}>
              <thead>
                <tr style={{ backgroundColor: '#f7fafc', textAlign: 'left' }}>
                  <th style={{ padding: '10px 12px', borderBottom: '2px solid #e2e8f0' }}>Description</th>
                  <th style={{ padding: '10px 12px', borderBottom: '2px solid #e2e8f0', textAlign: 'right' }}>Qty</th>
                  <th style={{ padding: '10px 12px', borderBottom: '2px solid #e2e8f0', textAlign: 'right' }}>Unit Price</th>
                  <th style={{ padding: '10px 12px', borderBottom: '2px solid #e2e8f0', textAlign: 'right' }}>Amount</th>
                </tr>
              </thead>
              <tbody>
                {invoice.items.map((item, i) => (
                  <tr key={i} style={{ borderBottom: '1px solid #e2e8f0' }}>
                    <td style={{ padding: '10px 12px' }}>{item.description}</td>
                    <td style={{ padding: '10px 12px', textAlign: 'right' }}>{item.quantity}</td>
                    <td style={{ padding: '10px 12px', textAlign: 'right' }}>{formatMoney(item.unitPrice)}</td>
                    <td style={{ padding: '10px 12px', textAlign: 'right' }}>{formatMoney(item.amount)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {invoice.payments.length > 0 && (
            <div style={{ padding: '24px', borderBottom: '1px solid #e2e8f0' }}>
              <h3 style={{ margin: '0 0 12px', fontSize: '16px', color: '#2d3748' }}>Payment History</h3>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                <thead>
                  <tr style={{ backgroundColor: '#f7fafc', textAlign: 'left' }}>
                    <th style={{ padding: '8px 12px', borderBottom: '1px solid #e2e8f0' }}>Receipt #</th>
                    <th style={{ padding: '8px 12px', borderBottom: '1px solid #e2e8f0' }}>Date</th>
                    <th style={{ padding: '8px 12px', borderBottom: '1px solid #e2e8f0' }}>Method</th>
                    <th style={{ padding: '8px 12px', borderBottom: '1px solid #e2e8f0', textAlign: 'right' }}>Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {invoice.payments.map((p, i) => (
                    <tr key={i} style={{ borderBottom: '1px solid #e2e8f0' }}>
                      <td style={{ padding: '8px 12px' }}>{p.number}</td>
                      <td style={{ padding: '8px 12px' }}>{new Date(p.date).toLocaleDateString()}</td>
                      <td style={{ padding: '8px 12px' }}>{p.method}</td>
                      <td style={{ padding: '8px 12px', textAlign: 'right', color: '#48bb78', fontWeight: 500 }}>{formatMoney(p.amount)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          <div style={{ padding: '16px 24px', textAlign: 'center', color: '#a0aec0', fontSize: '12px', borderTop: '1px solid #e2e8f0' }}>
            Utande Smart Billing System
          </div>
        </div>
      </div>
    </div>
  );
};
