import React, { useEffect, useState } from 'react';
import { reminderAPI } from '../../services/api';
import { Card, Button, Badge } from '../../components/ui';

interface ReminderLog {
  id: string;
  reminderType: string;
  status: string;
  recipientEmail: string;
  subject: string;
  sentAt: string | null;
  failedAt: string | null;
  retryCount: number;
  createdAt: string;
  invoice: { invoiceNumber: string; total: number; status: string; dueDate: string; customer: { firstName: string; lastName: string; email: string } };
}

export const RemindersPage: React.FC = () => {
  const [config, setConfig] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [logs, setLogs] = useState<ReminderLog[]>([]);
  const [logsLoading, setLogsLoading] = useState(true);
  const [triggering, setTriggering] = useState(false);
  const [triggerMsg, setTriggerMsg] = useState('');

  const loadConfig = () => reminderAPI.getConfig().then(res => { setConfig(res.data); setLoading(false); });
  const loadLogs = () => { setLogsLoading(true); reminderAPI.getAllLogs().then(res => { setLogs(res.data); setLogsLoading(false); }).catch(() => setLogsLoading(false)); };

  useEffect(() => { loadConfig(); loadLogs(); }, []);

  const handleSave = async () => {
    setSaving(true);
    try { await reminderAPI.updateConfig(config); alert('Settings saved'); } finally { setSaving(false); }
  };

  const handleTrigger = async () => {
    setTriggering(true);
    setTriggerMsg('');
    try {
      const res = await reminderAPI.trigger();
      setTriggerMsg(res.data.message);
      loadLogs();
    } catch { setTriggerMsg('Failed to trigger reminders'); }
    finally { setTriggering(false); }
  };

  if (loading) return <div style={{ padding: '40px', textAlign: 'center' }}>Loading...</div>;

  const statusColor = (s: string) => s === 'SENT' ? '#48bb78' : s === 'FAILED' ? '#e53e3e' : '#ed8936';

  return (
    <div>
      <h1 style={{ marginTop: 0, color: '#2d3748' }}>Reminders</h1>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '16px' }}>
        <Card title="Schedule">
          {[
            { key: 'sevenDaysEnabled', label: '7 Days Before Due' },
            { key: 'threeDaysEnabled', label: '3 Days Before Due' },
            { key: 'oneDayEnabled', label: '1 Day Before Due' },
            { key: 'onDueDateEnabled', label: 'On Due Date' },
            { key: 'overdueEnabled', label: 'Overdue (After Due Date)' },
          ].map(item => (
            <div key={item.key} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid #e2e8f0' }}>
              <span style={{ fontSize: '14px' }}>{item.label}</span>
              <label style={{ position: 'relative', display: 'inline-block', width: '44px', height: '24px' }}>
                <input type="checkbox" checked={config[item.key]} onChange={e => setConfig({ ...config, [item.key]: e.target.checked })} style={{ opacity: 0, width: 0, height: 0 }} />
                <span style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: config[item.key] ? '#48bb78' : '#cbd5e0', borderRadius: '12px', cursor: 'pointer', transition: '0.3s' }}>
                  <span style={{ position: 'absolute', width: '18px', height: '18px', left: config[item.key] ? '22px' : '3px', bottom: '3px', backgroundColor: '#fff', borderRadius: '50%', transition: '0.3s' }} />
                </span>
              </label>
            </div>
          ))}
          <div style={{ marginTop: '16px' }}>
            <Button onClick={handleSave} disabled={saving}>{saving ? 'Saving...' : 'Save Settings'}</Button>
          </div>
        </Card>

        <Card title="Controls">
          <p style={{ fontSize: '13px', color: '#718096', marginBottom: '12px' }}>
            Overdue interval: every <strong>{config.overdueIntervalDays}</strong> days &middot; Max retries: <strong>{config.maxRetries}</strong>
          </p>
          <p style={{ fontSize: '13px', color: '#718096', marginBottom: '16px' }}>
            Reminders run automatically every hour. You can also trigger a manual check now.
          </p>
          <Button onClick={handleTrigger} disabled={triggering} variant="secondary">
            {triggering ? 'Running...' : 'Run Reminder Check Now'}
          </Button>
          {triggerMsg && <p style={{ marginTop: '8px', fontSize: '13px', color: '#48bb78' }}>{triggerMsg}</p>}

          <div style={{ marginTop: '20px', padding: '12px', backgroundColor: '#f7fafc', borderRadius: '6px', fontSize: '13px', color: '#718096' }}>
            <strong>How it works:</strong>
            <ul style={{ margin: '8px 0 0', paddingLeft: '18px' }}>
              <li>Cron checks every hour for due/overdue invoices</li>
              <li>Each reminder type is sent only once per invoice</li>
              <li>Failed reminders retry up to {config.maxRetries} times</li>
              <li>Emails stop when the invoice is paid or cancelled</li>
            </ul>
          </div>
        </Card>
      </div>

      <Card title={`Reminder Log (${logs.length})`}>
        {logsLoading ? (
          <div style={{ padding: '20px', textAlign: 'center', color: '#718096' }}>Loading logs...</div>
        ) : logs.length === 0 ? (
          <div style={{ padding: '20px', textAlign: 'center', color: '#718096' }}>No reminders sent yet. They will appear here as invoices trigger reminders.</div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
            <thead>
              <tr style={{ backgroundColor: '#f7fafc', textAlign: 'left' }}>
                <th style={{ padding: '10px 12px', borderBottom: '2px solid #e2e8f0' }}>Type</th>
                <th style={{ padding: '10px 12px', borderBottom: '2px solid #e2e8f0' }}>Invoice</th>
                <th style={{ padding: '10px 12px', borderBottom: '2px solid #e2e8f0' }}>Customer</th>
                <th style={{ padding: '10px 12px', borderBottom: '2px solid #e2e8f0' }}>Status</th>
                <th style={{ padding: '10px 12px', borderBottom: '2px solid #e2e8f0' }}>Sent At</th>
                <th style={{ padding: '10px 12px', borderBottom: '2px solid #e2e8f0' }}>Retries</th>
              </tr>
            </thead>
            <tbody>
              {logs.map(log => (
                <tr key={log.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                  <td style={{ padding: '10px 12px', fontWeight: 500 }}>{log.reminderType.replace(/_/g, ' ')}</td>
                  <td style={{ padding: '10px 12px' }}>{log.invoice?.invoiceNumber || '—'}</td>
                  <td style={{ padding: '10px 12px' }}>{log.invoice?.customer?.firstName} {log.invoice?.customer?.lastName}</td>
                  <td style={{ padding: '10px 12px' }}>
                    <span style={{ display: 'inline-block', padding: '2px 8px', borderRadius: '10px', fontSize: '12px', fontWeight: 500, color: '#fff', backgroundColor: statusColor(log.status) }}>
                      {log.status}
                    </span>
                  </td>
                  <td style={{ padding: '10px 12px', color: '#718096' }}>{log.sentAt ? new Date(log.sentAt).toLocaleString() : '—'}</td>
                  <td style={{ padding: '10px 12px' }}>{log.retryCount}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </div>
  );
};
