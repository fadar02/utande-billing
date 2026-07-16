import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create admin user
  const adminPassword = await bcrypt.hash('admin123', 12);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@utande.com' },
    update: {},
    create: {
      email: 'admin@utande.com',
      passwordHash: adminPassword,
      firstName: 'System',
      lastName: 'Administrator',
      role: 'ADMIN',
    },
  });

  // Create finance officer
  const financePassword = await bcrypt.hash('finance123', 12);
  const finance = await prisma.user.upsert({
    where: { email: 'finance@utande.com' },
    update: {},
    create: {
      email: 'finance@utande.com',
      passwordHash: financePassword,
      firstName: 'Sarah',
      lastName: 'Johnson',
      role: 'FINANCE',
    },
  });

  // Create sales officer
  const salesPassword = await bcrypt.hash('sales123', 12);
  const sales = await prisma.user.upsert({
    where: { email: 'sales@utande.com' },
    update: {},
    create: {
      email: 'sales@utande.com',
      passwordHash: salesPassword,
      firstName: 'Mike',
      lastName: 'Williams',
      role: 'SALES',
    },
  });

  // Create technical team
  const techPassword = await bcrypt.hash('tech123', 12);
  const tech = await prisma.user.upsert({
    where: { email: 'tech@utande.com' },
    update: {},
    create: {
      email: 'tech@utande.com',
      passwordHash: techPassword,
      firstName: 'James',
      lastName: 'Brown',
      role: 'TECHNICAL',
    },
  });

  console.log('Users created:', { admin: admin.email, finance: finance.email, sales: sales.email, tech: tech.email });

  // Create services
  const services = await Promise.all([
    prisma.service.create({
      data: {
        name: 'Internet Basic',
        description: '10 Mbps internet connection',
        type: 'INTERNET',
        monthlyRate: 29.99,
        setupFee: 49.99,
      },
    }),
    prisma.service.create({
      data: {
        name: 'Internet Premium',
        description: '50 Mbps internet connection',
        type: 'INTERNET',
        monthlyRate: 59.99,
        setupFee: 49.99,
      },
    }),
    prisma.service.create({
      data: {
        name: 'Starlink Standard',
        description: 'Starlink satellite internet',
        type: 'STARLINK',
        monthlyRate: 99.00,
        setupFee: 299.00,
      },
    }),
    prisma.service.create({
      data: {
        name: 'CCTV Basic',
        description: '4-camera CCTV system',
        type: 'CCTV',
        monthlyRate: 19.99,
        setupFee: 199.99,
      },
    }),
    prisma.service.create({
      data: {
        name: 'VoIP Business',
        description: 'Business VoIP phone system',
        type: 'VOIP',
        monthlyRate: 39.99,
        setupFee: 99.99,
      },
    }),
  ]);

  console.log('Services created:', services.length);

  // Create sample customers
  const customers = await Promise.all([
    prisma.customer.create({
      data: {
        customerCode: 'CUST-00001',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '+1234567890',
        address: '123 Main St',
        city: 'Lusaka',
        status: 'ACTIVE',
      },
    }),
    prisma.customer.create({
      data: {
        customerCode: 'CUST-00002',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@example.com',
        phone: '+1234567891',
        address: '456 Oak Ave',
        city: 'Lusaka',
        status: 'ACTIVE',
      },
    }),
    prisma.customer.create({
      data: {
        customerCode: 'CUST-00003',
        firstName: 'Bob',
        lastName: 'Wilson',
        email: 'bob.wilson@example.com',
        phone: '+1234567892',
        address: '789 Pine Rd',
        city: 'Kitwe',
        status: 'ACTIVE',
      },
    }),
    prisma.customer.create({
      data: {
        customerCode: 'CUST-00004',
        firstName: 'Alice',
        lastName: 'Brown',
        email: 'alice.brown@example.com',
        phone: '+1234567893',
        address: '321 Elm St',
        city: 'Ndola',
        status: 'SUSPENDED',
      },
    }),
    prisma.customer.create({
      data: {
        customerCode: 'CUST-00005',
        firstName: 'Charlie',
        lastName: 'Davis',
        email: 'charlie.davis@example.com',
        phone: '+1234567894',
        address: '654 Maple Dr',
        city: 'Lusaka',
        status: 'ACTIVE',
      },
    }),
  ]);

  console.log('Customers created:', customers.length);

  // Assign services to customers
  const customerServices = await Promise.all([
    prisma.customerService.create({
      data: {
        customerId: customers[0].id,
        serviceId: services[0].id,
        monthlyRate: 29.99,
        status: 'ACTIVE',
      },
    }),
    prisma.customerService.create({
      data: {
        customerId: customers[0].id,
        serviceId: services[3].id,
        monthlyRate: 19.99,
        status: 'ACTIVE',
      },
    }),
    prisma.customerService.create({
      data: {
        customerId: customers[1].id,
        serviceId: services[1].id,
        monthlyRate: 59.99,
        status: 'ACTIVE',
      },
    }),
    prisma.customerService.create({
      data: {
        customerId: customers[2].id,
        serviceId: services[2].id,
        monthlyRate: 99.00,
        status: 'ACTIVE',
      },
    }),
    prisma.customerService.create({
      data: {
        customerId: customers[3].id,
        serviceId: services[0].id,
        monthlyRate: 29.99,
        status: 'SUSPENDED',
      },
    }),
    prisma.customerService.create({
      data: {
        customerId: customers[4].id,
        serviceId: services[4].id,
        monthlyRate: 39.99,
        status: 'ACTIVE',
      },
    }),
  ]);

  console.log('Customer services created:', customerServices.length);

  // Create some invoices
  const now = new Date();
  const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0);
  const dueDate = new Date(now.getFullYear(), now.getMonth(), 15);

  const invoices = await Promise.all([
    prisma.invoice.create({
      data: {
        invoiceNumber: 'INV-2401-0001',
        customerId: customers[0].id,
        customerServiceId: customerServices[0].id,
        status: 'PENDING',
        subtotal: 29.99,
        taxRate: 16,
        taxAmount: 4.80,
        total: 34.79,
        dueDate,
        billingPeriodStart: lastMonth,
        billingPeriodEnd: lastMonthEnd,
        description: 'Internet Basic - January 2024',
        items: {
          create: [{ description: 'Internet Basic - Monthly', quantity: 1, unitPrice: 29.99, amount: 29.99 }],
        },
      },
    }),
    prisma.invoice.create({
      data: {
        invoiceNumber: 'INV-2401-0002',
        customerId: customers[1].id,
        customerServiceId: customerServices[2].id,
        status: 'PAID',
        subtotal: 59.99,
        taxRate: 16,
        taxAmount: 9.60,
        total: 69.59,
        amountPaid: 69.59,
        dueDate: new Date(now.getFullYear(), now.getMonth() - 1, 15),
        paidDate: new Date(now.getFullYear(), now.getMonth() - 1, 10),
        billingPeriodStart: new Date(now.getFullYear(), now.getMonth() - 2, 1),
        billingPeriodEnd: new Date(now.getFullYear(), now.getMonth() - 1, 0),
        description: 'Internet Premium - December 2023',
        items: {
          create: [{ description: 'Internet Premium - Monthly', quantity: 1, unitPrice: 59.99, amount: 59.99 }],
        },
      },
    }),
    prisma.invoice.create({
      data: {
        invoiceNumber: 'INV-2401-0003',
        customerId: customers[2].id,
        customerServiceId: customerServices[3].id,
        status: 'OVERDUE',
        subtotal: 99.00,
        taxRate: 16,
        taxAmount: 15.84,
        total: 114.84,
        dueDate: new Date(now.getFullYear(), now.getMonth() - 1, 15),
        billingPeriodStart: new Date(now.getFullYear(), now.getMonth() - 2, 1),
        billingPeriodEnd: new Date(now.getFullYear(), now.getMonth() - 1, 0),
        description: 'Starlink Standard - December 2023',
        items: {
          create: [{ description: 'Starlink Standard - Monthly', quantity: 1, unitPrice: 99.00, amount: 99.00 }],
        },
      },
    }),
  ]);

  console.log('Invoices created:', invoices.length);

  // Create a payment
  const payment = await prisma.payment.create({
    data: {
      paymentNumber: 'PAY-2401-0001',
      customerId: customers[1].id,
      invoiceId: invoices[1].id,
      amount: 69.59,
      paymentMethod: 'BANK_TRANSFER',
      reference: 'TXN-2024-001',
      receivedById: finance.id,
    },
  });

  console.log('Payment created:', payment.paymentNumber);

  // Initialize reminder config
  await prisma.reminderConfig.create({ data: {} });

  // Create system settings
  await Promise.all([
    prisma.systemSetting.create({ data: { key: 'company_name', value: 'Utande', description: 'Company name' } }),
    prisma.systemSetting.create({ data: { key: 'tax_rate', value: '16', description: 'Default tax rate percentage' } }),
    prisma.systemSetting.create({ data: { key: 'currency', value: 'USD', description: 'Default currency' } }),
  ]);

  console.log('System settings created');
  console.log('Seeding completed!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
