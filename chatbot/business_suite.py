"""
Invoice & Billing Module
Tracks invoices, generates templates, sends reminders, revenue tracking
"""
import json
import os
from datetime import datetime, timedelta


class InvoiceManager:
    def __init__(self, data_dir=".business"):
        self.data_dir = data_dir
        os.makedirs(data_dir, exist_ok=True)
        self.invoices_file = os.path.join(data_dir, "invoices.json")
        self.clients_file = os.path.join(data_dir, "clients.json")
        self.invoices = self._load_json(self.invoices_file)
        self.clients = self._load_json(self.clients_file)

    def _load_json(self, filepath):
        if os.path.exists(filepath):
            with open(filepath, "r") as f:
                return json.load(f)
        return {}

    def _save_json(self, filepath, data):
        with open(filepath, "w") as f:
            json.dump(data, f, indent=2)

    def is_invoice_request(self, text):
        text_lower = text.lower()
        keywords = [
            "invoice", "bill", "billing", "payment", "paid", "overdue",
            "revenue", "earnings", "receivable", "accounts receivable"
        ]
        return any(k in text_lower for k in keywords)

    def handle(self, text):
        text_lower = text.lower().strip()

        add_match = re.search(
            r"add\s+invoice\s*(?::)?\s*(.*)", text_lower
        )
        if add_match:
            return self.add_invoice_from_text(add_match.group(1).strip())

        mark_match = re.search(
            r"mark\s+invoice\s+([\w-]+)\s+(paid|pending|overdue)", text_lower
        )
        if mark_match:
            return self.mark_invoice(mark_match.group(1), mark_match.group(2))

        if any(w in text_lower for w in ["list invoice", "show invoice", "all invoice"]):
            return self.list_invoices()
        if "overdue" in text_lower and ("invoice" in text_lower or "show" in text_lower):
            return self.list_invoices(status="overdue")
        if "paid" in text_lower and ("invoice" in text_lower or "show" in text_lower):
            return self.list_invoices(status="paid")
        if "pending" in text_lower and ("invoice" in text_lower or "show" in text_lower):
            return self.list_invoices(status="pending")
        if "client" in text_lower and ("list" in text_lower or "show" in text_lower):
            return self.list_clients()
        if "revenue" in text_lower or "earnings" in text_lower:
            return self.revenue_report()
        if "remind" in text_lower or "reminder" in text_lower:
            return self.send_reminders()

        return self._help_text()

    def add_invoice_from_text(self, text):
        parts = [p.strip() for p in text.split(",")]
        if len(parts) < 3:
            return (
                "Format: Add invoice: Client Name, Amount, Due Date, Description\n"
                "Example: Add invoice: Acme Corp, $1500, 2026-02-15, Website development"
            )

        client = parts[0]
        amount = parts[1].replace("$", "").replace(",", "")
        due_date = parts[2]
        description = parts[3] if len(parts) > 3 else "Invoice"

        try:
            amount = float(amount)
        except ValueError:
            return "Invalid amount. Please use a number like 1500 or $1,500."

        if client not in self.clients:
            self.clients[client] = {
                "name": client,
                "created": datetime.now().isoformat(),
                "invoices": [],
            }
            self._save_json(self.clients_file, self.clients)

        inv_id = f"INV-{len(self.invoices) + 1:04d}"
        invoice = {
            "id": inv_id,
            "client": client,
            "amount": amount,
            "due_date": due_date,
            "description": description,
            "status": "pending",
            "created": datetime.now().isoformat(),
            "paid_date": None,
        }
        self.invoices[inv_id] = invoice

        self.clients[client]["invoices"].append(inv_id)
        self._save_json(self.invoices_file, self.invoices)
        self._save_json(self.clients_file, self.clients)

        return (
            f"Invoice Created\n"
            f"  ID: {inv_id}\n"
            f"  Client: {client}\n"
            f"  Amount: ${amount:,.2f}\n"
            f"  Due: {due_date}\n"
            f"  Description: {description}"
        )

    def mark_invoice(self, inv_id, status):
        inv_id = inv_id.upper()
        if inv_id not in self.invoices:
            return f"Invoice {inv_id} not found."

        self.invoices[inv_id]["status"] = status
        if status == "paid":
            self.invoices[inv_id]["paid_date"] = datetime.now().isoformat()
        self._save_json(self.invoices_file, self.invoices)

        inv = self.invoices[inv_id]
        return f"Invoice {inv_id} marked as {status.upper()} (${inv['amount']:,.2f} from {inv['client']})"

    def list_invoices(self, status=None):
        if not self.invoices:
            return "No invoices yet."

        lines = ["Invoices:", "=" * 50]
        total = 0
        count = 0

        for inv_id, inv in self.invoices.items():
            if status and inv["status"] != status:
                continue
            status_icon = {"paid": "✅", "pending": "⏳", "overdue": "❌"}.get(inv["status"], "❓")
            lines.append(
                f"  {status_icon} {inv_id} | {inv['client']} | "
                f"${inv['amount']:,.2f} | Due: {inv['due_date']} | "
                f"{inv['status'].upper()}"
            )
            total += inv["amount"]
            count += 1

        lines.append(f"\n  Total: {count} invoice(s) | ${total:,.2f}")
        return "\n".join(lines)

    def send_reminders(self):
        pending = [
            inv for inv in self.invoices.values()
            if inv["status"] in ("pending", "overdue")
        ]
        if not pending:
            return "No pending invoices to remind."

        lines = ["Payment Reminders:", "=" * 50]
        for inv in pending:
            lines.append(
                f"  To: {inv['client']}\n"
                f"  Invoice: {inv['id']} | Amount: ${inv['amount']:,.2f} | "
                f"Due: {inv['due_date']}\n"
            )
        lines.append(f"\nTotal pending: ${sum(i['amount'] for i in pending):,.2f}")
        return "\n".join(lines)

    def revenue_report(self):
        if not self.invoices:
            return "No invoices to report."

        total_revenue = sum(i["amount"] for i in self.invoices.values() if i["status"] == "paid")
        total_pending = sum(i["amount"] for i in self.invoices.values() if i["status"] != "paid")
        total_all = sum(i["amount"] for i in self.invoices.values())

        client_revenue = {}
        for inv in self.invoices.values():
            if inv["status"] == "paid":
                client = inv["client"]
                client_revenue[client] = client_revenue.get(client, 0) + inv["amount"]

        lines = [
            "Revenue Report:",
            "=" * 50,
            f"  Total Revenue (Paid): ${total_revenue:,.2f}",
            f"  Pending: ${total_pending:,.2f}",
            f"  Total All: ${total_all:,.2f}",
            "\n  Top Clients:",
        ]
        for client, rev in sorted(client_revenue.items(), key=lambda x: -x[1])[:5]:
            lines.append(f"    {client}: ${rev:,.2f}")

        return "\n".join(lines)

    def list_clients(self):
        if not self.clients:
            return "No clients yet."

        lines = ["Clients:", "=" * 40]
        for client_id, client in self.clients.items():
            inv_count = len(client.get("invoices", []))
            total = sum(
                self.invoices.get(i, {}).get("amount", 0)
                for i in client.get("invoices", [])
            )
            lines.append(
                f"  {client['name']} | Invoices: {inv_count} | Total: ${total:,.2f}"
            )
        return "\n".join(lines)

    def _help_text(self):
        return (
            "Invoice & Billing Commands:\n"
            "  Add invoice: Client, Amount, Due Date, Description\n"
            "  Mark invoice INV-0001 paid\n"
            "  List invoices / Show pending / Show overdue\n"
            "  Show paid invoices\n"
            "  Revenue report\n"
            "  List clients\n"
            "  Send reminders\n"
            "\nExample: Add invoice: Acme Corp, $1500, 2026-02-15, Website"
        )


import re
