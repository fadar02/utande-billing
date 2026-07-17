import enum
from datetime import datetime, timezone

from models import db


class PlayerStatus(enum.Enum):
    active = "active"
    injured = "injured"
    suspended = "suspended"
    inactive = "inactive"


class Player(db.Model):
    __tablename__ = "players"

    id = db.Column(db.Integer, primary_key=True)
    photo = db.Column(db.String(255), nullable=True)
    full_name = db.Column(db.String(150), nullable=False)
    jersey_number = db.Column(db.Integer, nullable=False)
    position = db.Column(db.String(50), nullable=False)
    date_of_birth = db.Column(db.Date, nullable=True)
    nationality = db.Column(db.String(100), nullable=True)
    height = db.Column(db.Float, nullable=True)
    weight = db.Column(db.Float, nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    email = db.Column(db.String(120), nullable=True)
    emergency_contact = db.Column(db.String(200), nullable=True)
    preferred_foot = db.Column(db.String(10), nullable=True)
    appearances = db.Column(db.Integer, nullable=False, default=0)
    goals = db.Column(db.Integer, nullable=False, default=0)
    assists = db.Column(db.Integer, nullable=False, default=0)
    yellow_cards = db.Column(db.Integer, nullable=False, default=0)
    red_cards = db.Column(db.Integer, nullable=False, default=0)
    minutes_played = db.Column(db.Integer, nullable=False, default=0)
    is_featured = db.Column(db.Boolean, nullable=False, default=False)
    status = db.Column(db.Enum(PlayerStatus), nullable=False, default=PlayerStatus.active)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<Player {self.full_name} #{self.jersey_number}>"
