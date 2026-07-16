import React, { useEffect, useState } from 'react';
import { reportAPI } from '../../services/api';
import { Card, Badge, Table, Button } from '../../components/ui';
import { useSettings } from '../../context/SettingsContext';

export const ReportsPage: React.FC = () => {
  const { formatMoney } = useSettings();
  const [activeTab, setActiveTab] = useState('outstanding');
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const loadReport = async (tab: string) => {
    setLoading(true);
    try {
      let res;
      switch (tab) {
        case 'outstanding': res = await reportAPI.getOutstanding(); break;
        case 'paid': res = await reportAPI.getPaid(); break;
        case 'overdue': res = await reportAPI.getOverdue(); break;
        case 'revenue': res = await reportAPI.getRevenue(); break;
        case 'emails': res = await reportAPI.getEmails(); break;
        case 'reminders': res = await reportAPI.getReminders(); break;
        default: res = { data: null };
      }
      setData(res.data);
    } finally { setLoading(false); }
  };

  useEffect(() => { loadReport(activeTab); }, [activeTab]);

  const tabs = [
    { id: 'outstanding', label: 'Outstanding' },
    { id: 'paid', label: 'Paid' },
    { id: 'overdue', label: 'Overdue' },
    { id: 'revenue', label: 'Revenue' },
    { id: 'emails', label: 'Email Log' },
    { id: 'reminders', label: 'Reminders' },
  ];

  return (
    <div>
      <h1 style={{ marginTop: 0, color: '#2d3748' }}>Reports</h1>

      <div style={{ display: 'flex', gap: '8px', marginBottom: '16px' }}>
        {tabs.map(tab => (
          <button key={tab.id} onClick={() => setActiveTab(tab.id)} style={{
            padding: '8px 16px', border: '1px solid #e2e8f0', borderRadius: '6px',
            backgroundColor: activeTab === tab.id ? '#4299e1' : '#fff',
            color: activeTab === tab.id ? '#fff' : '#4a5568', cursor: 'pointer',
          }}>
            {tab.label}
          </button>
        ))}
      </div>

      {loading ? <div style={{ padding: '20px', textAlign: 'center' }}>Loading...</div> : (
        <Card>
          {activeTab === 'outstanding' && data && (
            <>
              <div style={{ marginBottom: '16px', fontSize: '14px', color: '#718096' }}>
                {data.count} invoices | Total: <strong>{formatMoney(data.total)}</strong>
              </div>
              <Table headers={['Invoice #', 'Customer', 'Total', 'Paid', 'Balance', 'Due Date']}>
                {data.invoices?.map((inv: any) => (
                  <tr key={inv.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                    <td style={{ padding: '10px 16px', fontWeight: 500 }}>{inv.invoiceNumber}</td>
                    <td style={{ padding: '10px 16px' }}>{inv.customer?.firstName} {inv.customer?.lastName}</td>
                    <td style={{ padding: '10px 16px' }}>{formatMoney(inv.total)}</td>
                    <td style={{ padding: '10px 16px' }}>{formatMoney(inv.amountPaid)}</td>
                    <td style={{ padding: '10px 16px', color: '#e53e3e', fontWeight: 600 }}>{formatMoney(Number(inv.total) - Number(inv.amountPaid))}</td>
                    <td style={{ padding: '10px 16px' }}>{new Date(inv.dueDate).toLocaleDateString()}</td>
                  </tr>
                ))}
              </Table>
            </>
          )}

          {activeTab === 'paid' && data && (
            <>
              <div style={{ marginBottom: '16px', fontSize: '14px', color: '#718096' }}>
                {data.count} invoices | Total: <strong>{formatMoney(data.total)}</strong>
              </div>
              <Table headers={['Invoice #', 'Customer', 'Amount', 'Paid Date']}>
                {data.invoices?.map((inv: any) => (
                  <tr key={inv.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                    <td style={{ padding: '10px 16px' }}>{inv.invoiceNumber}</td>
                    <td style={{ padding: '10px 16px' }}>{inv.customer?.firstName} {inv.customer?.lastName}</td>
                    <td style={{ padding: '10px 16px', color: '#48bb78' }}>{formatMoney(inv.total)}</td>
                    <td style={{ padding: '10px 16px' }}>{inv.paidDate ? new Date(inv.paidDate).toLocaleDateString() : '-'}</td>
                  </tr>
                ))}
              </Table>
            </>
          )}

          {activeTab === 'overdue' && data && (
            <>
              <div style={{ marginBottom: '16px', fontSize: '14px', color: '#e53e3e' }}>
                {data.count} overdue invoices | Total: <strong>{formatMoney(data.total)}</strong>
              </div>
              <Table headers={['Invoice #', 'Customer', 'Balance', 'Due Date', 'Days Overdue']}>
                {data.invoices?.map((inv: any) => {
                  const days = Math.floor((Date.now() - new Date(inv.dueDate).getTime()) / (1000 * 60 * 60 * 24));
                  return (
                    <tr key={inv.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                      <td style={{ padding: '10px 16px' }}>{inv.invoiceNumber}</td>
                      <td style={{ padding: '10px 16px' }}>{inv.customer?.firstName} {inv.customer?.lastName}</td>
                      <td style={{ padding: '10px 16px', color: '#e53e3e', fontWeight: 600 }}>{formatMoney(Number(inv.total) - Number(inv.amountPaid))}</td>
                      <td style={{ padding: '10px 16px' }}>{new Date(inv.dueDate).toLocaleDateString()}</td>
                      <td style={{ padding: '10px 16px' }}><Badge status={`${days} days`} variant="danger" /></td>
                    </tr>
                  );
                })}
              </Table>
            </>
          )}

          {activeTab === 'revenue' && data && (
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div>
                <h3>Total Revenue: {formatMoney(data.totalRevenue)}</h3>
                <h4>By Payment Method:</h4>
                {data.byMethod && Object.entries(data.byMethod).map(([method, amount]) => (
                  <div key={method} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid #e2e8f0' }}>
                    <span>{method}</span><span style={{ fontWeight: 600 }}>{formatMoney(amount as number)}</span>
                  </div>
                ))}
              </div>
              <div>
                <h4>By Month:</h4>
                {data.byMonth && Object.entries(data.byMonth).sort().map(([month, amount]) => (
                  <div key={month} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid #e2e8f0' }}>
                    <span>{month}</span><span style={{ fontWeight: 600 }}>{formatMoney(amount as number)}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeTab === 'emails' && data && (
            <>
              <div style={{ display: 'flex', gap: '16px', marginBottom: '16px' }}>
                <div>Sent: <strong>{data.stats?.sent}</strong></div>
                <div>Failed: <strong style={{ color: '#e53e3e' }}>{data.stats?.failed}</strong></div>
                <div>Queued: <strong>{data.stats?.queued}</strong></div>
              </div>
              <Table headers={['To', 'Subject', 'Type', 'Status', 'Date']}>
                {data.emails?.map((e: any) => (
                  <tr key={e.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                    <td style={{ padding: '10px 16px' }}>{e.recipientEmail}</td>
                    <td style={{ padding: '10px 16px' }}>{e.subject}</td>
                    <td style={{ padding: '10px 16px' }}>{e.emailType}</td>
                    <td style={{ padding: '10px 16px' }}><Badge status={e.status} /></td>
                    <td style={{ padding: '10px 16px' }}>{e.sentAt ? new Date(e.sentAt).toLocaleString() : '-'}</td>
                  </tr>
                ))}
              </Table>
            </>
          )}

          {activeTab === 'reminders' && data && (
            <>
              <div style={{ display: 'flex', gap: '16px', marginBottom: '16px' }}>
                <div>Sent: <strong>{data.stats?.sent}</strong></div>
                <div>Failed: <strong style={{ color: '#e53e3e' }}>{data.stats?.failed}</strong></div>
                <div>Pending: <strong>{data.stats?.pending}</strong></div>
              </div>
              <Table headers={['Invoice', 'Customer', 'Type', 'Status', 'Date']}>
                {data.reminders?.map((r: any) => (
                  <tr key={r.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                    <td style={{ padding: '10px 16px' }}>{r.invoice?.invoiceNumber}</td>
                    <td style={{ padding: '10px 16px' }}>{r.invoice?.customer?.firstName} {r.invoice?.customer?.lastName}</td>
                    <td style={{ padding: '10px 16px' }}>{r.reminderType.replace(/_/g, ' ')}</td>
                    <td style={{ padding: '10px 16px' }}><Badge status={r.status} /></td>
                    <td style={{ padding: '10px 16px' }}>{r.sentAt ? new Date(r.sentAt).toLocaleString() : '-'}</td>
                  </tr>
                ))}
              </Table>
            </>
          )}
        </Card>
      )}
    </div>
  );
};
