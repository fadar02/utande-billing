"""
Proposals & Quotes Module
Generate business proposals, create quotes, client tracking
"""
import json
import os
from datetime import datetime, timedelta


class ProposalManager:
    def __init__(self, data_dir=".business"):
        self.data_dir = data_dir
        os.makedirs(data_dir, exist_ok=True)
        self.proposals_file = os.path.join(data_dir, "proposals.json")
        self.quotes_file = os.path.join(data_dir, "quotes.json")
        self.proposals = self._load_json(self.proposals_file)
        self.quotes = self._load_json(self.quotes_file)

    def _load_json(self, filepath):
        if os.path.exists(filepath):
            with open(filepath, "r") as f:
                return json.load(f)
        return {}

    def _save_json(self, filepath, data):
        with open(filepath, "w") as f:
            json.dump(data, f, indent=2)

    def is_proposal_request(self, text):
        text_lower = text.lower()
        keywords = [
            "proposal", "quote", "estimate", "bid", "pricing",
            "offer", "contract", "statement of work"
        ]
        return any(k in text_lower for k in keywords)

    def handle(self, text):
        text_lower = text.lower().strip()

        if "proposal" in text_lower and ("list" in text_lower or "show" in text_lower):
            return self.list_proposals()
        if "quote" in text_lower and ("list" in text_lower or "show" in text_lower):
            return self.list_quotes()
        if "generate proposal" in text_lower or "create proposal" in text_lower:
            return self.generate_proposal(text_lower)
        if "create quote" in text_lower or "generate quote" in text_lower:
            return self.generate_quote(text_lower)
        if "accept" in text_lower and ("proposal" in text_lower or "quote" in text_lower):
            return self.accept_item(text_lower)
        if "decline" in text_lower and ("proposal" in text_lower or "quote" in text_lower):
            return self.decline_item(text_lower)

        return self._help_text()

    def generate_proposal(self, text):
        match = re.search(
            r"(?:generate|create)\s+proposal\s*(?::)?\s*(.*)", text
        )
        if not match:
            return (
                "Format: Generate proposal: Client Name, Project Description, Amount, Timeline\n"
                "Example: Generate proposal: Acme Corp, Website redesign, $5000, 2 months"
            )

        parts = [p.strip() for p in match.group(1).split(",")]
        if len(parts) < 3:
            return "Please provide at least: Client, Description, Amount"

        client = parts[0]
        description = parts[1]
        amount = parts[2].replace("$", "").replace(",", "")
        timeline = parts[3] if len(parts) > 3 else "TBD"

        try:
            amount = float(amount)
        except ValueError:
            return "Invalid amount."

        prop_id = f"PROP-{len(self.proposals) + 1:04d}"
        proposal = {
            "id": prop_id,
            "client": client,
            "description": description,
            "amount": amount,
            "timeline": timeline,
            "status": "draft",
            "created": datetime.now().isoformat(),
        }
        self.proposals[prop_id] = proposal
        self._save_json(self.proposals_file, self.proposals)

        return (
            f"Proposal Generated\n"
            f"  ID: {prop_id}\n"
            f"  Client: {client}\n"
            f"  Project: {description}\n"
            f"  Amount: ${amount:,.2f}\n"
            f"  Timeline: {timeline}\n"
            f"  Status: DRAFT"
        )

    def generate_quote(self, text):
        match = re.search(
            r"(?:generate|create)\s+quote\s*(?::)?\s*(.*)", text
        )
        if not match:
            return (
                "Format: Generate quote: Client Name, Items, Amount\n"
                "Example: Generate quote: John Smith, Logo design + Business cards, $800"
            )

        parts = [p.strip() for p in match.group(1).split(",")]
        if len(parts) < 2:
            return "Please provide: Client, Items/Description, Amount"

        client = parts[0]
        items = parts[1]
        amount = parts[2].replace("$", "").replace(",", "") if len(parts) > 2 else "0"

        try:
            amount = float(amount)
        except ValueError:
            return "Invalid amount."

        quote_id = f"QTE-{len(self.quotes) + 1:04d}"
        quote = {
            "id": quote_id,
            "client": client,
            "items": items,
            "amount": amount,
            "status": "pending",
            "created": datetime.now().isoformat(),
            "valid_until": (datetime.now() + timedelta(days=30)).strftime("%Y-%m-%d"),
        }
        self.quotes[quote_id] = quote
        self._save_json(self.quotes_file, self.quotes)

        return (
            f"Quote Generated\n"
            f"  ID: {quote_id}\n"
            f"  Client: {client}\n"
            f"  Items: {items}\n"
            f"  Amount: ${amount:,.2f}\n"
            f"  Valid Until: {quote['valid_until']}"
        )

    def list_proposals(self):
        if not self.proposals:
            return "No proposals yet."

        lines = ["Proposals:", "=" * 50]
        for pid, prop in self.proposals.items():
            status_icon = {
                "draft": "📝", "sent": "📤", "accepted": "✅", "declined": "❌"
            }.get(prop["status"], "❓")
            lines.append(
                f"  {status_icon} {pid} | {prop['client']} | "
                f"${prop['amount']:,.2f} | {prop['status'].upper()}"
            )
        return "\n".join(lines)

    def list_quotes(self):
        if not self.quotes:
            return "No quotes yet."

        lines = ["Quotes:", "=" * 50]
        for qid, quote in self.quotes.items():
            status_icon = {"pending": "⏳", "accepted": "✅", "declined": "❌"}.get(quote["status"], "❓")
            lines.append(
                f"  {status_icon} {qid} | {quote['client']} | "
                f"${quote['amount']:,.2f} | {quote['status'].upper()}"
            )
        return "\n".join(lines)

    def accept_item(self, text):
        match = re.search(r"accept\s+(proposal|quote)\s+([\w-]+)", text)
        if not match:
            return "Format: Accept proposal PROP-0001 or Accept quote QTE-0001"

        item_type = match.group(1)
        item_id = match.group(2).upper()

        if item_type == "proposal" and item_id in self.proposals:
            self.proposals[item_id]["status"] = "accepted"
            self._save_json(self.proposals_file, self.proposals)
            return f"Proposal {item_id} accepted!"
        elif item_type == "quote" and item_id in self.quotes:
            self.quotes[item_id]["status"] = "accepted"
            self._save_json(self.quotes_file, self.quotes)
            return f"Quote {item_id} accepted!"
        return f"{item_type.title()} {item_id} not found."

    def decline_item(self, text):
        match = re.search(r"decline\s+(proposal|quote)\s+([\w-]+)", text)
        if not match:
            return "Format: Decline proposal PROP-0001 or Decline quote QTE-0001"

        item_type = match.group(1)
        item_id = match.group(2).upper()

        if item_type == "proposal" and item_id in self.proposals:
            self.proposals[item_id]["status"] = "declined"
            self._save_json(self.proposals_file, self.proposals)
            return f"Proposal {item_id} declined."
        elif item_type == "quote" and item_id in self.quotes:
            self.quotes[item_id]["status"] = "declined"
            self._save_json(self.quotes_file, self.quotes)
            return f"Quote {item_id} declined."
        return f"{item_type.title()} {item_id} not found."

    def _help_text(self):
        return (
            "Proposals & Quotes Commands:\n"
            "  Generate proposal: Client, Description, Amount, Timeline\n"
            "  Generate quote: Client, Items, Amount\n"
            "  List proposals / Show proposals\n"
            "  List quotes / Show quotes\n"
            "  Accept proposal PROP-0001\n"
            "  Decline quote QTE-0001"
        )


import re
