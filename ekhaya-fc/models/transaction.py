import enum
from datetime import datetime, timezone

from models import db


class TransactionType(enum.Enum):
    income = "income"
    expense = "expense"


class Transaction(db.Model):
    __tablename__ = "transactions"

    id = db.Column(db.Integer, primary_key=True)
    description = db.Column(db.String(300), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    type = db.Column(db.Enum(TransactionType), nullable=False)
    category = db.Column(db.String(100), nullable=True)
    reference = db.Column(db.String(100), nullable=True)
    transaction_date = db.Column(db.Date, nullable=False, default=lambda: datetime.now(timezone.utc).date())
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<Transaction {self.description} - {self.amount}>"
