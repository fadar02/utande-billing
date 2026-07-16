import React, { useEffect, useState } from 'react';
import { dashboardAPI } from '../../services/api';
import { Card, StatCard, Badge, Table } from '../../components/ui';
import { useSettings } from '../../context/SettingsContext';
import type { DashboardStats } from '../../types';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

export const DashboardPage: React.FC = () => {
  const { formatMoney } = useSettings();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [revenueChart, setRevenueChart] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      dashboardAPI.getStats().then(res => setStats(res.data)),
      dashboardAPI.getRevenueChart().then(res => setRevenueChart(res.data)),
    ]).finally(() => setLoading(false));
  }, []);

  if (loading) return <div style={{ padding: '40px', textAlign: 'center' }}>Loading dashboard...</div>;
  if (!stats) return <div>Error loading dashboard</div>;

  const revenueData = Object.entries(revenueChart).map(([month, amount]) => ({
    month,
    revenue: amount,
  }));

  const invoicePieData = [
    { name: 'Paid', value: stats.invoices.paid, color: '#48bb78' },
    { name: 'Pending', value: stats.invoices.pending, color: '#ecc94b' },
    { name: 'Overdue', value: stats.invoices.overdue, color: '#fc8181' },
  ];

  return (
    <div>
      <h1 style={{ marginTop: 0, color: '#2d3748' }}>Dashboard</h1>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <StatCard label="Total Customers" value={stats.customers.total} icon="👥" color="#4299e1" />
        <StatCard label="Active Services" value={stats.services.active} icon="🌐" color="#48bb78" />
        <StatCard label="Pending Invoices" value={stats.invoices.pending} icon="📄" color="#ecc94b" />
        <StatCard label="Overdue Invoices" value={stats.invoices.overdue} icon="⚠️" color="#fc8181" />
        <StatCard label="Total Revenue" value={formatMoney(stats.revenue.total)} icon="💰" color="#48bb78" />
        <StatCard label="Outstanding" value={formatMoney(stats.revenue.outstanding)} icon="📊" color="#ed8936" />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '16px' }}>
        <Card title="Revenue Trend">
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={revenueData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip formatter={(value) => formatMoney(Number(value))} />
              <Bar dataKey="revenue" fill="#4299e1" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>

        <Card title="Invoice Status">
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie data={invoicePieData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={100}>
                {invoicePieData.map((entry, index) => (
                  <Cell key={index} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
          <div style={{ display: 'flex', justifyContent: 'center', gap: '16px', marginTop: '8px' }}>
            {invoicePieData.map(item => (
              <div key={item.name} style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px' }}>
                <div style={{ width: '12px', height: '12px', borderRadius: '2px', backgroundColor: item.color }} />
                {item.name}: {item.value}
              </div>
            ))}
          </div>
        </Card>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginTop: '16px' }}>
        <Card title="Recent Payments">
          <Table headers={['Customer', 'Amount', 'Method', 'Date']}>
            {stats.recentPayments.slice(0, 5).map((payment: any) => (
              <tr key={payment.id} style={{ borderBottom: '1px solid #e2e8f0' }}>
                <td style={{ padding: '10px 16px' }}>{payment.customer?.firstName} {payment.customer?.lastName}</td>
                <td style={{ padding: '10px 16px', fontWeight: 600, color: '#48bb78' }}>{formatMoney(payment.amount)}</td>
                <td style={{ padding: '10px 16px' }}>{payment.paymentMethod}</td>
                <td style={{ padding: '10px 16px' }}>{new Date(payment.paymentDate).toLocaleDateString()}</td>
              </tr>
            ))}
          </Table>
        </Card>

        <Card title="Recent Activity">
          <div style={{ maxHeight: '300px', overflow: 'auto' }}>
            {stats.recentActivity.slice(0, 10).map((activity: any) => (
              <div key={activity.id} style={{ padding: '10px 0', borderBottom: '1px solid #e2e8f0', fontSize: '13px' }}>
                <div style={{ fontWeight: 500 }}>{activity.action}</div>
                <div style={{ color: '#718096' }}>
                  {activity.user?.firstName} {activity.user?.lastName} - {new Date(activity.createdAt).toLocaleString()}
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
};
