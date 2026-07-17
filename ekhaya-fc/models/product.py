import enum
from datetime import datetime, timezone

from models import db


class ProductCategory(enum.Enum):
    jersey = "jersey"
    tshirt = "tshirt"
    cap = "cap"
    scarf = "scarf"
    ticket = "ticket"


class Product(db.Model):
    __tablename__ = "products"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    category = db.Column(db.Enum(ProductCategory), nullable=False)
    price = db.Column(db.Float, nullable=False)
    stock_quantity = db.Column(db.Integer, nullable=False, default=0)
    image = db.Column(db.String(255), nullable=True)
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    orders = db.relationship("Order", backref="product", lazy=True)

    def __repr__(self):
        return f"<Product {self.name}>"
