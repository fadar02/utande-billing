export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'ADMIN' | 'FINANCE' | 'SALES' | 'TECHNICAL';
  isActive: boolean;
  lastLogin?: string;
  createdAt: string;
}

export interface Customer {
  id: string;
  customerCode: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  status: 'ACTIVE' | 'SUSPENDED' | 'INACTIVE';
  notes?: string;
  createdAt: string;
  services?: CustomerService[];
  _count?: { invoices: number; payments: number };
}

export interface Service {
  id: string;
  name: string;
  description?: string;
  type: 'INTERNET' | 'STARLINK' | 'CCTV' | 'VOIP' | 'OTHER';
  monthlyRate: number;
  setupFee: number;
  isActive: boolean;
  _count?: { customerServices: number };
}

export interface CustomerService {
  id: string;
  customerId: string;
  serviceId: string;
  status: 'ACTIVE' | 'SUSPENDED' | 'CANCELLED';
  monthlyRate: number;
  customRate?: number;
  startDate: string;
  endDate?: string;
  customer?: Customer;
  service?: Service;
}

export interface Invoice {
  id: string;
  invoiceNumber: string;
  customerId: string;
  customerServiceId?: string;
  status: 'DRAFT' | 'PENDING' | 'PAID' | 'PARTIALLY_PAID' | 'OVERDUE' | 'CANCELLED';
  subtotal: number;
  taxRate: number;
  taxAmount: number;
  total: number;
  amountPaid: number;
  dueDate: string;
  issuedDate: string;
  paidDate?: string;
  description?: string;
  notes?: string;
  billingPeriodStart?: string;
  billingPeriodEnd?: string;
  customer?: Customer;
  customerService?: CustomerService;
  items?: InvoiceItem[];
  payments?: Payment[];
  reminderLogs?: ReminderLog[];
}

export interface InvoiceItem {
  id: string;
  invoiceId: string;
  description: string;
  quantity: number;
  unitPrice: number;
  amount: number;
}

export interface Payment {
  id: string;
  paymentNumber: string;
  customerId: string;
  invoiceId?: string;
  amount: number;
  paymentMethod: 'CASH' | 'BANK_TRANSFER' | 'MOBILE_MONEY' | 'CARD' | 'CHEQUE' | 'OTHER';
  reference?: string;
  notes?: string;
  receivedById: string;
  paymentDate: string;
  receiptSent: boolean;
  customer?: Customer;
  invoice?: Invoice;
  receivedBy?: User;
}

export interface ReminderLog {
  id: string;
  invoiceId: string;
  reminderType: string;
  status: string;
  sentAt?: string;
  failedAt?: string;
  errorMessage?: string;
  retryCount: number;
  recipientEmail: string;
  subject: string;
  createdAt: string;
}

export interface DashboardStats {
  customers: { total: number; active: number; suspended: number };
  services: { total: number; active: number };
  invoices: { pending: number; overdue: number; paid: number };
  revenue: { total: number; outstanding: number };
  recentPayments: Payment[];
  recentActivity: any[];
}

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  pages: number;
}

export interface PaginatedResponse<T> {
  pagination: Pagination;
  [key: string]: any;
}
