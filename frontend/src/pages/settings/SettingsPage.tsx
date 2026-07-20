import React, { useEffect, useState } from 'react';
import { settingsAPI } from '../../services/api';
import { Card, Button, Input } from '../../components/ui';
import { useSettings } from '../../context/SettingsContext';

interface Setting {
  key: string;
  value: string;
  description: string;
}

interface Section {
  title: string;
  icon: string;
  description: string;
  settings: { key: string; label: string; type: 'text' | 'number' | 'email' | 'toggle' | 'select'; options?: { value: string; label: string }[] }[];
}

const sections: Section[] = [
  {
    title: 'Company Information',
    icon: '🏢',
    description: 'Company details used across invoices, emails, and communications',
    settings: [
      { key: 'company_name', label: 'Company Name', type: 'text' },
      { key: 'company_email', label: 'Company Email', type: 'email' },
      { key: 'company_phone', label: 'Company Phone', type: 'text' },
      { key: 'company_address', label: 'Company Address', type: 'text' },
    ],
  },
  {
    title: 'Currency & Tax',
    icon: '💱',
    description: 'Default currency and tax configuration for all invoices',
    settings: [
      { key: 'currency', label: 'Currency Code', type: 'select', options: [{ value: 'MWK', label: 'MWK — Malawian Kwacha' }] },
      { key: 'currency_symbol', label: 'Currency Symbol', type: 'text' },
      { key: 'tax_enabled', label: 'Enable Tax', type: 'toggle' },
      { key: 'tax_rate', label: 'Tax Rate (%)', type: 'number' },
    ],
  },
  {
    title: 'Invoice Settings',
    icon: '📄',
    description: 'Defaults for invoice generation and numbering',
    settings: [
      { key: 'default_payment_terms', label: 'Default Payment Terms (days)', type: 'number' },
      { key: 'invoice_prefix', label: 'Invoice Number Prefix', type: 'text' },
      { key: 'payment_number_prefix', label: 'Payment Receipt Prefix', type: 'text' },
      { key: 'customer_code_prefix', label: 'Customer Code Prefix', type: 'text' },
      { key: 'auto_generate_invoices', label: 'Auto-Generate Monthly Invoices', type: 'toggle' },
      { key: 'auto_generate_day', label: 'Auto-Generate Day of Month', type: 'number' },
      { key: 'overdue_threshold_days', label: 'Overdue Threshold (days after due)', type: 'number' },
      { key: 'overdue_reminder_interval_days', label: 'Overdue Reminder Interval (days)', type: 'number' },
    ],
  },
  {
    title: 'Email Settings',
    icon: '📧',
    description: 'Email notification and SMTP configuration',
    settings: [
      { key: 'email_notifications_enabled', label: 'Enable Email Notifications', type: 'toggle' },
      { key: 'admin_email', label: 'Admin Email (CC on reminders)', type: 'email' },
      { key: 'smtp_host', label: 'SMTP Host', type: 'text' },
      { key: 'smtp_port', label: 'SMTP Port', type: 'number' },
      { key: 'smtp_user', label: 'SMTP Username / Email', type: 'email' },
      { key: 'smtp_from_name', label: 'Email Sender Name', type: 'text' },
    ],
  },
];

export const SettingsPage: React.FC = () => {
  const { reload } = useSettings();
  const [settings, setSettings] = useState<Record<string, string>>({});
  const [original, setOriginal] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saveMsg, setSaveMsg] = useState('');
  const [saveErr, setSaveErr] = useState('');
  const [activeTab, setActiveTab] = useState(0);

  useEffect(() => {
    settingsAPI.getAll().then(res => {
      const map: Record<string, string> = {};
      res.data.forEach((s: Setting) => { map[s.key] = s.value; });
      setSettings(map);
      setOriginal(map);
      setLoading(false);
    });
  }, []);

  const handleChange = (key: string, value: string) => {
    setSettings(prev => ({ ...prev, [key]: value }));
    setSaveMsg('');
    setSaveErr('');
  };

  const handleToggle = (key: string) => {
    handleChange(key, settings[key] === 'true' ? 'false' : 'true');
  };

  const hasChanges = JSON.stringify(settings) !== JSON.stringify(original);

  const handleSave = async () => {
    setSaving(true);
    setSaveMsg('');
    setSaveErr('');
    try {
      const changed = Object.keys(settings)
        .filter(key => settings[key] !== original[key])
        .map(key => ({ key, value: settings[key] }));
      if (changed.length === 0) {
        setSaveMsg('No changes to save');
        setSaving(false);
        return;
      }
      await settingsAPI.update(changed);
      setOriginal({ ...settings });
      setSaveMsg(`Saved ${changed.length} setting(s) successfully`);
      reload();
    } catch (err: any) {
      setSaveErr(err.response?.data?.error || 'Failed to save settings');
    } finally {
      setSaving(false);
    }
  };

  const handleReset = async () => {
    if (!window.confirm('Reset all settings to defaults? This cannot be undone.')) return;
    try {
      await settingsAPI.reset();
      const res = await settingsAPI.getAll();
      const map: Record<string, string> = {};
      res.data.forEach((s: Setting) => { map[s.key] = s.value; });
      setSettings(map);
      setOriginal(map);
      setSaveMsg('All settings reset to defaults');
      reload();
    } catch (err: any) {
      setSaveErr(err.response?.data?.error || 'Failed to reset settings');
    }
  };

  if (loading) return <div style={{ padding: '40px', textAlign: 'center', color: '#718096' }}>Loading settings...</div>;

  const current = sections[activeTab];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <div>
          <h1 style={{ margin: 0, color: '#2d3748' }}>System Settings</h1>
          <p style={{ margin: '4px 0 0', color: '#718096', fontSize: '13px' }}>Configure system-wide settings. Changes apply to all users.</p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          <Button variant="secondary" onClick={handleReset}>Reset Defaults</Button>
          <Button onClick={handleSave} disabled={!hasChanges || saving}>
            {saving ? 'Saving...' : 'Save Changes'}
          </Button>
        </div>
      </div>

      {saveMsg && (
        <div style={{ padding: '10px 16px', backgroundColor: '#c6f6d5', color: '#22543d', borderRadius: '6px', marginBottom: '12px', fontSize: '13px' }}>
          {saveMsg}
        </div>
      )}
      {saveErr && (
        <div style={{ padding: '10px 16px', backgroundColor: '#fed7d7', color: '#742a2a', borderRadius: '6px', marginBottom: '12px', fontSize: '13px' }}>
          {saveErr}
        </div>
      )}

      <div style={{ display: 'flex', gap: '20px' }}>
        {/* Tabs */}
        <div style={{ width: '240px', flexShrink: 0 }}>
          <Card>
            {sections.map((section, i) => (
              <button
                key={i}
                onClick={() => setActiveTab(i)}
                style={{
                  width: '100%', padding: '12px 16px', textAlign: 'left', border: 'none', cursor: 'pointer',
                  backgroundColor: activeTab === i ? '#ebf8ff' : 'transparent',
                  borderLeft: activeTab === i ? '3px solid #3182ce' : '3px solid transparent',
                  borderRadius: '0 6px 6px 0',
                  transition: 'all 0.15s',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <span style={{ fontSize: '18px' }}>{section.icon}</span>
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600, color: activeTab === i ? '#2b6cb0' : '#4a5568' }}>
                      {section.title}
                    </div>
                  </div>
                </div>
              </button>
            ))}
          </Card>
        </div>

        {/* Content */}
        <div style={{ flex: 1 }}>
          <Card>
            <div style={{ marginBottom: '20px' }}>
              <h2 style={{ margin: 0, fontSize: '18px', color: '#2d3748', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span>{current.icon}</span> {current.title}
              </h2>
              <p style={{ margin: '4px 0 0', color: '#718096', fontSize: '13px' }}>{current.description}</p>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {current.settings.map(s => (
                <div key={s.key}>
                  {s.type === 'toggle' ? (
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px', backgroundColor: '#f7fafc', borderRadius: '6px', border: '1px solid #e2e8f0' }}>
                      <div>
                        <div style={{ fontSize: '14px', fontWeight: 500, color: '#2d3748' }}>{s.label}</div>
                        <div style={{ fontSize: '12px', color: '#718096', marginTop: '2px' }}>
                          Currently: <strong style={{ color: settings[s.key] === 'true' ? '#48bb78' : '#e53e3e' }}>
                            {settings[s.key] === 'true' ? 'Enabled' : 'Disabled'}
                          </strong>
                        </div>
                      </div>
                      <button
                        onClick={() => handleToggle(s.key)}
                        style={{
                          width: '48px', height: '24px', borderRadius: '12px', border: 'none', cursor: 'pointer',
                          backgroundColor: settings[s.key] === 'true' ? '#48bb78' : '#cbd5e0',
                          position: 'relative', transition: 'background-color 0.2s',
                        }}
                      >
                        <div style={{
                          width: '20px', height: '20px', borderRadius: '50%', backgroundColor: '#fff',
                          position: 'absolute', top: '2px',
                          left: settings[s.key] === 'true' ? '26px' : '2px',
                          transition: 'left 0.2s',
                          boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
                        }} />
                      </button>
                    </div>
                  ) : s.type === 'select' ? (
                    <div>
                      <label style={{ display: 'block', marginBottom: '6px', fontSize: '13px', color: '#4a5568', fontWeight: 500 }}>
                        {s.label}
                      </label>
                      <select
                        value={settings[s.key] || ''}
                        onChange={e => handleChange(s.key, e.target.value)}
                        style={{
                          width: '100%', padding: '10px 12px', border: '1px solid #e2e8f0',
                          borderRadius: '6px', fontSize: '14px', boxSizing: 'border-box',
                          backgroundColor: settings[s.key] !== original[s.key] ? '#fffff0' : '#fff',
                        }}
                      >
                        {s.options?.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                      </select>
                    </div>
                  ) : (
                    <Input
                      label={s.label}
                      type={s.type}
                      value={settings[s.key] || ''}
                      onChange={e => handleChange(s.key, e.target.value)}
                      style={settings[s.key] !== original[s.key] ? { backgroundColor: '#fffff0' } : undefined}
                    />
                  )}
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
};
