import axios from 'axios';

const API_BASE_URL = 'http://localhost:3000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const authAPI = {
  login: (data: { email: string; password: string }) => api.post('/auth/login', data),
  register: (data: any) => api.post('/auth/register', data),
  getProfile: () => api.get('/auth/profile'),
  getUsers: () => api.get('/auth/users'),
  updateUser: (id: string, data: any) => api.put(`/auth/users/${id}`, data),
};

export const customerAPI = {
  getAll: (params?: any) => api.get('/customers', { params }),
  getById: (id: string) => api.get(`/customers/${id}`),
  create: (data: any) => api.post('/customers', data),
  update: (id: string, data: any) => api.put(`/customers/${id}`, data),
  delete: (id: string) => api.delete(`/customers/${id}`),
  getStatement: (id: string, params?: any) => api.get(`/customers/${id}/statement`, { params }),
  sendEmail: (id: string, data: { subject: string; message: string }) => api.post(`/customers/${id}/send-email`, data),
};

export const serviceAPI = {
  getAll: (params?: any) => api.get('/services', { params }),
  getById: (id: string) => api.get(`/services/${id}`),
  create: (data: any) => api.post('/services', data),
  update: (id: string, data: any) => api.put(`/services/${id}`, data),
  delete: (id: string) => api.delete(`/services/${id}`),
  assignToCustomer: (data: any) => api.post('/services/assign', data),
  updateCustomerService: (id: string, data: any) => api.put(`/services/customer-service/${id}`, data),
  removeCustomerService: (id: string) => api.delete(`/services/customer-service/${id}`),
};

export const invoiceAPI = {
  getAll: (params?: any) => api.get('/invoices', { params }),
  getById: (id: string) => api.get(`/invoices/${id}`),
  create: (data: any) => api.post('/invoices', data),
  update: (id: string, data: any) => api.put(`/invoices/${id}`, data),
  cancel: (id: string) => api.post(`/invoices/${id}/cancel`),
  downloadPDF: (id: string) => api.get(`/invoices/${id}/pdf`, { responseType: 'blob' }),
  getReminderHistory: (id: string) => api.get(`/invoices/${id}/reminders`),
  autoGenerate: () => api.post('/invoices/auto-generate'),
};

export const paymentAPI = {
  getAll: (params?: any) => api.get('/payments', { params }),
  getById: (id: string) => api.get(`/payments/${id}`),
  record: (data: any) => api.post('/payments', data),
  downloadReceipt: (id: string) => api.get(`/payments/${id}/receipt`, { responseType: 'blob' }),
};

export const reportAPI = {
  getOutstanding: () => api.get('/reports/outstanding-invoices'),
  getPaid: (params?: any) => api.get('/reports/paid-invoices', { params }),
  getOverdue: () => api.get('/reports/overdue-invoices'),
  getRevenue: (params?: any) => api.get('/reports/revenue', { params }),
  getPayments: () => api.get('/reports/payments'),
  getEmails: () => api.get('/reports/emails'),
  getReminders: () => api.get('/reports/reminders'),
};

export const dashboardAPI = {
  getStats: () => api.get('/dashboard/stats'),
  getRevenueChart: () => api.get('/dashboard/revenue-chart'),
  getAuditLogs: (params?: any) => api.get('/dashboard/audit-logs', { params }),
};

export const reminderAPI = {
  getConfig: () => api.get('/reminders/config'),
  updateConfig: (data: any) => api.put('/reminders/config', data),
  getHistory: (invoiceId: string) => api.get(`/reminders/history/${invoiceId}`),
  getAllLogs: () => api.get('/reminders/logs'),
  trigger: () => api.post('/reminders/trigger'),
};

export const settingsAPI = {
  getAll: () => api.get('/settings'),
  get: (key: string) => api.get(`/settings/${key}`),
  update: (settings: { key: string; value: string }[]) => api.put('/settings', { settings }),
  reset: () => api.post('/settings/reset'),
};

export default api;
