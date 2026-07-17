import enum
from datetime import datetime, timezone

from models import db


class FixtureStatus(enum.Enum):
    upcoming = "upcoming"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"


class Fixture(db.Model):
    __tablename__ = "fixtures"

    id = db.Column(db.Integer, primary_key=True)
    match_id = db.Column(db.Integer, db.ForeignKey("matches.id"), nullable=False)
    competition = db.Column(db.String(150), nullable=False)
    match_date = db.Column(db.Date, nullable=False)
    kick_off_time = db.Column(db.Time, nullable=True)
    venue = db.Column(db.String(200), nullable=True)
    home_away = db.Column(db.String(10), nullable=False)
    opponent = db.Column(db.String(150), nullable=False)
    match_status = db.Column(db.Enum(FixtureStatus), nullable=False, default=FixtureStatus.upcoming)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<Fixture {self.opponent} - {self.match_date}>"
