"""
Customer Support Module
Ticket system, FAQ auto-responses, response templates
"""
import json
import os
from datetime import datetime


class SupportManager:
    def __init__(self, data_dir=".business"):
        self.data_dir = data_dir
        os.makedirs(data_dir, exist_ok=True)
        self.tickets_file = os.path.join(data_dir, "tickets.json")
        self.faq_file = os.path.join(data_dir, "faq.json")
        self.templates_file = os.path.join(data_dir, "templates.json")
        self.tickets = self._load_json(self.tickets_file)
        self.faq = self._load_json(self.faq_file)
        self.templates = self._load_json(self.templates_file)

    def _load_json(self, filepath):
        if os.path.exists(filepath):
            with open(filepath, "r") as f:
                return json.load(f)
        return {}

    def _save_json(self, filepath, data):
        with open(filepath, "w") as f:
            json.dump(data, f, indent=2)

    def is_support_request(self, text):
        text_lower = text.lower()
        keywords = [
            "ticket", "support", "customer", "issue", "problem",
            "complaint", "faq", "template", "respond", "reply"
        ]
        return any(k in text_lower for k in keywords)

    def handle(self, text):
        text_lower = text.lower().strip()

        if any(w in text_lower for w in ["list ticket", "show ticket", "open ticket", "all ticket"]):
            return self.list_tickets()
        if "closed ticket" in text_lower:
            return self.list_tickets(status="closed")
        if "faq" in text_lower:
            if "add" in text_lower:
                return self.add_faq(text_lower)
            return self.show_faq()
        if "template" in text_lower:
            if "add" in text_lower:
                return self.add_template(text_lower)
            return self.show_templates()
        if "close" in text_lower and "ticket" in text_lower:
            return self.close_ticket(text_lower)
        if "respond" in text_lower or "reply" in text_lower:
            return self.respond_to_ticket(text_lower)

        add_match = re.search(r"add\s+ticket\s*(?::)?\s*(.*)", text_lower)
        if add_match:
            return self.add_ticket(add_match.group(1).strip())

        return self._help_text()

    def add_ticket(self, text):
        parts = [p.strip() for p in text.split(",")]
        if len(parts) < 2:
            return (
                "Format: Add ticket: Customer Name, Issue Description, Priority (low/medium/high)\n"
                "Example: Add ticket: John Smith, Cannot login to account, high"
            )

        customer = parts[0]
        issue = parts[1]
        priority = parts[2] if len(parts) > 2 else "medium"

        ticket_id = f"TKT-{len(self.tickets) + 1:04d}"
        ticket = {
            "id": ticket_id,
            "customer": customer,
            "issue": issue,
            "priority": priority,
            "status": "open",
            "created": datetime.now().isoformat(),
            "responses": [],
        }
        self.tickets[ticket_id] = ticket
        self._save_json(self.tickets_file, self.tickets)

        return (
            f"Support Ticket Created\n"
            f"  ID: {ticket_id}\n"
            f"  Customer: {customer}\n"
            f"  Issue: {issue}\n"
            f"  Priority: {priority.upper()}"
        )

    def list_tickets(self, status="open"):
        if not self.tickets:
            return "No tickets yet."

        lines = [f"{status.upper()} Tickets:", "=" * 50]
        count = 0
        for tid, ticket in self.tickets.items():
            if ticket["status"] != status:
                continue
            priority_icon = {"high": "🔴", "medium": "🟡", "low": "🟢"}.get(ticket["priority"], "⚪")
            lines.append(
                f"  {priority_icon} {tid} | {ticket['customer']} | "
                f"{ticket['issue'][:40]}... | {ticket['priority'].upper()}"
            )
            count += 1

        lines.append(f"\nTotal: {count} {status} ticket(s)")
        return "\n".join(lines)

    def close_ticket(self, text):
        match = re.search(r"close\s+ticket\s+([\w-]+)", text)
        if not match:
            return "Please specify ticket ID. Example: Close ticket TKT-0001"

        tid = match.group(1).upper()
        if tid not in self.tickets:
            return f"Ticket {tid} not found."

        self.tickets[tid]["status"] = "closed"
        self._save_json(self.tickets_file, self.tickets)
        return f"Ticket {tid} closed successfully."

    def respond_to_ticket(self, text):
        match = re.search(r"(?:respond|reply)\s+(?:to\s+)?ticket\s+([\w-]+)\s*:? (.+)", text)
        if not match:
            return "Format: Respond to ticket TKT-0001: Your response here"

        tid = match.group(1).upper()
        response = match.group(2)

        if tid not in self.tickets:
            return f"Ticket {tid} not found."

        self.tickets[tid]["responses"].append({
            "response": response,
            "time": datetime.now().isoformat(),
        })
        self._save_json(self.tickets_file, self.tickets)
        return f"Response added to {tid}."

    def add_faq(self, text):
        match = re.search(r"add\s+faq\s*(?::)?\s*(.+?)\s*->\s*(.+)", text)
        if not match:
            return "Format: Add FAQ: question -> answer\nExample: Add FAQ: What are your hours? -> We are open 9-5"

        question = match.group(1).strip()
        answer = match.group(2).strip()
        faq_id = f"FAQ-{len(self.faq) + 1:04d}"
        self.faq[faq_id] = {"question": question, "answer": answer}
        self._save_json(self.faq_file, self.faq)
        return f"FAQ added: {question}"

    def show_faq(self):
        if not self.faq:
            return "No FAQ entries yet."

        lines = ["FAQ:", "=" * 50]
        for fid, entry in self.faq.items():
            lines.append(f"  Q: {entry['question']}")
            lines.append(f"  A: {entry['answer']}\n")
        return "\n".join(lines)

    def add_template(self, text):
        match = re.search(r"add\s+template\s*(?::)?\s*(.+?)\s*->\s*(.+)", text)
        if not match:
            return "Format: Add template: name -> content\nExample: Add template: greeting -> Hello {name}, thank you for contacting us."

        name = match.group(1).strip()
        content = match.group(2).strip()
        self.templates[name] = {"content": content}
        self._save_json(self.templates_file, self.templates)
        return f"Template '{name}' added."

    def show_templates(self):
        if not self.templates:
            return "No templates yet."

        lines = ["Templates:", "=" * 50]
        for name, tmpl in self.templates.items():
            lines.append(f"  {name}: {tmpl['content'][:60]}...")
        return "\n".join(lines)

    def _help_text(self):
        return (
            "Customer Support Commands:\n"
            "  Add ticket: Customer, Issue, Priority\n"
            "  List tickets / Show open / Show closed\n"
            "  Close ticket TKT-0001\n"
            "  Respond to ticket TKT-0001: message\n"
            "  Add FAQ: question -> answer\n"
            "  Show FAQ\n"
            "  Add template: name -> content\n"
            "  Show templates"
        )


import re
