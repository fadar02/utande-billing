import enum
from datetime import datetime, timezone

from models import db


class StaffRole(enum.Enum):
    head_coach = "head_coach"
    assistant_coach = "assistant_coach"
    goalkeeper_coach = "goalkeeper_coach"
    fitness_coach = "fitness_coach"
    team_doctor = "team_doctor"
    physio = "physio"
    kit_manager = "kit_manager"
    club_secretary = "club_secretary"
    media_officer = "media_officer"


class Staff(db.Model):
    __tablename__ = "staff"

    id = db.Column(db.Integer, primary_key=True)
    photo = db.Column(db.String(255), nullable=True)
    full_name = db.Column(db.String(150), nullable=False)
    role = db.Column(db.Enum(StaffRole), nullable=False)
    phone = db.Column(db.String(20), nullable=True)
    email = db.Column(db.String(120), nullable=True)
    bio = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<Staff {self.full_name} - {self.role.value}>"
