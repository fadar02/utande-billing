"""
Business Reporting Module
Revenue reports, client summaries, monthly analytics
"""
import json
import os
from datetime import datetime, timedelta
from collections import defaultdict


class ReportManager:
    def __init__(self, data_dir=".business"):
        self.data_dir = data_dir
        os.makedirs(data_dir, exist_ok=True)
        self.invoices_file = os.path.join(data_dir, "invoices.json")
        self.clients_file = os.path.join(data_dir, "clients.json")
        self.employees_file = os.path.join(data_dir, "employees.json")
        self.tickets_file = os.path.join(data_dir, "tickets.json")
        self.invoices = self._load_json(self.invoices_file)
        self.clients = self._load_json(self.clients_file)
        self.employees = self._load_json(self.employees_file)
        self.tickets = self._load_json(self.tickets_file)

    def _load_json(self, filepath):
        if os.path.exists(filepath):
            with open(filepath, "r") as f:
                return json.load(f)
        return {}

    def _reload_data(self):
        self.invoices = self._load_json(self.invoices_file)
        self.clients = self._load_json(self.clients_file)
        self.employees = self._load_json(self.employees_file)
        self.tickets = self._load_json(self.tickets_file)

    def is_report_request(self, text):
        text_lower = text.lower()
        keywords = [
            "report", "analytics", "summary", "dashboard",
            "statistics", "metrics", "kpi", "monthly", "weekly",
            "quarterly", "annual", "business report"
        ]
        return any(k in text_lower for k in keywords)

    def handle(self, text):
        text_lower = text.lower().strip()
        self._reload_data()

        if "revenue" in text_lower:
            return self.revenue_report()
        if "client" in text_lower:
            return self.client_summary()
        if "employee" in text_lower or "staff" in text_lower or "team" in text_lower:
            return self.employee_report()
        if "ticket" in text_lower or "support" in text_lower:
            return self.support_report()
        if "monthly" in text_lower:
            return self.monthly_report()
        if "quarterly" in text_lower:
            return self.quarterly_report()
        if "annual" in text_lower:
            return self.annual_report()
        if "dashboard" in text_lower:
            return self.dashboard()
        if "overview" in text_lower or "summary" in text_lower:
            return self.business_overview()

        return self._help_text()

    def revenue_report(self):
        if not self.invoices:
            return "No invoice data for revenue report."

        paid = [i for i in self.invoices.values() if i["status"] == "paid"]
        pending = [i for i in self.invoices.values() if i["status"] == "pending"]
        overdue = [i for i in self.invoices.values() if i["status"] == "overdue"]

        total_revenue = sum(i["amount"] for i in paid)
        total_pending = sum(i["amount"] for i in pending)
        total_overdue = sum(i["amount"] for i in overdue)

        client_revenue = defaultdict(float)
        for inv in paid:
            client_revenue[inv["client"]] += inv["amount"]

        lines = [
            "Revenue Report",
            "=" * 50,
            f"  Total Revenue: ${total_revenue:,.2f}",
            f"  Pending: ${total_pending:,.2f}",
            f"  Overdue: ${total_overdue:,.2f}",
            f"  Total Invoices: {len(self.invoices)}",
            f"  Paid: {len(paid)} | Pending: {len(pending)} | Overdue: {len(overdue)}",
            "\n  Top Clients by Revenue:",
        ]
        for client, rev in sorted(client_revenue.items(), key=lambda x: -x[1])[:5]:
            lines.append(f"    {client}: ${rev:,.2f}")

        return "\n".join(lines)

    def client_summary(self):
        if not self.clients:
            return "No client data."

        lines = [
            "Client Summary",
            "=" * 50,
            f"  Total Clients: {len(self.clients)}",
            "\n  Client Details:",
        ]
        for cid, client in self.clients.items():
            inv_count = len(client.get("invoices", []))
            total = sum(
                self.invoices.get(i, {}).get("amount", 0)
                for i in client.get("invoices", [])
            )
            lines.append(
                f"    {client['name']}: {inv_count} invoices, ${total:,.2f} total"
            )
        return "\n".join(lines)

    def employee_report(self):
        if not self.employees:
            return "No employee data."

        departments = defaultdict(list)
        for eid, emp in self.employees.items():
            departments[emp.get("department", "Unknown")].append(emp)

        lines = [
            "Employee Report",
            "=" * 50,
            f"  Total Employees: {len(self.employees)}",
            "\n  By Department:",
        ]
        for dept, emps in sorted(departments.items()):
            lines.append(f"    {dept}: {len(emps)} employee(s)")
            for emp in emps:
                lines.append(f"      - {emp['name']} ({emp['position']})")

        return "\n".join(lines)

    def support_report(self):
        if not self.tickets:
            return "No support ticket data."

        open_tickets = [t for t in self.tickets.values() if t["status"] == "open"]
        closed_tickets = [t for t in self.tickets.values() if t["status"] == "closed"]
        high_priority = [t for t in open_tickets if t.get("priority") == "high"]

        lines = [
            "Support Report",
            "=" * 50,
            f"  Total Tickets: {len(self.tickets)}",
            f"  Open: {len(open_tickets)} | Closed: {len(closed_tickets)}",
            f"  High Priority: {len(high_priority)}",
        ]

        if high_priority:
            lines.append("\n  High Priority Issues:")
            for t in high_priority:
                lines.append(f"    🔴 {t['id']}: {t['customer']} - {t['issue'][:40]}")

        return "\n".join(lines)

    def monthly_report(self):
        lines = [
            "Monthly Business Report",
            "=" * 50,
            f"  Generated: {datetime.now().strftime('%Y-%m-%d')}",
        ]

        if self.invoices:
            paid = [i for i in self.invoices.values() if i["status"] == "paid"]
            total = sum(i["amount"] for i in paid)
            lines.append(f"  Revenue: ${total:,.2f}")
            lines.append(f"  Invoices: {len(self.invoices)}")

        if self.employees:
            lines.append(f"  Team Size: {len(self.employees)}")

        if self.tickets:
            open_t = len([t for t in self.tickets.values() if t["status"] == "open"])
            lines.append(f"  Open Support Tickets: {open_t}")

        return "\n".join(lines)

    def quarterly_report(self):
        return self.monthly_report().replace("Monthly", "Quarterly")

    def annual_report(self):
        return self.monthly_report().replace("Monthly", "Annual")

    def dashboard(self):
        lines = [
            "",
            "=" * 50,
            "       BUSINESS DASHBOARD",
            "=" * 50,
        ]

        if self.invoices:
            paid = sum(1 for i in self.invoices.values() if i["status"] == "paid")
            revenue = sum(i["amount"] for i in self.invoices.values() if i["status"] == "paid")
            lines.append(f"  💰 Revenue: ${revenue:,.2f}")
            lines.append(f"  📄 Invoices: {len(self.invoices)} ({paid} paid)")

        if self.clients:
            lines.append(f"  👥 Clients: {len(self.clients)}")

        if self.employees:
            lines.append(f"  🏢 Employees: {len(self.employees)}")

        if self.tickets:
            open_t = len([t for t in self.tickets.values() if t["status"] == "open"])
            lines.append(f"  🎫 Support Tickets: {open_t} open")

        lines.append("=" * 50)
        return "\n".join(lines)

    def business_overview(self):
        lines = [
            "Business Overview",
            "=" * 50,
        ]

        if self.invoices:
            total = sum(i["amount"] for i in self.invoices.values())
            paid = sum(i["amount"] for i in self.invoices.values() if i["status"] == "paid")
            lines.append(f"  Total invoiced: ${total:,.2f}")
            lines.append(f"  Collected: ${paid:,.2f}")

        if self.clients:
            lines.append(f"  Active clients: {len(self.clients)}")

        if self.employees:
            lines.append(f"  Team size: {len(self.employees)}")

        if self.tickets:
            open_t = len([t for t in self.tickets.values() if t["status"] == "open"])
            lines.append(f"  Pending support: {open_t}")

        return "\n".join(lines)

    def _help_text(self):
        return (
            "Business Reports Commands:\n"
            "  Revenue report\n"
            "  Client summary\n"
            "  Employee report\n"
            "  Support report\n"
            "  Monthly report\n"
            "  Quarterly report\n"
            "  Annual report\n"
            "  Dashboard\n"
            "  Business overview"
        )
