import enum
from datetime import datetime, timezone

from models import db


class MatchStatus(enum.Enum):
    scheduled = "scheduled"
    live = "live"
    completed = "completed"
    cancelled = "cancelled"


class HomeAway(enum.Enum):
    home = "home"
    away = "away"


class Match(db.Model):
    __tablename__ = "matches"

    id = db.Column(db.Integer, primary_key=True)
    opponent = db.Column(db.String(150), nullable=False)
    opponent_logo = db.Column(db.String(255), nullable=True)
    competition = db.Column(db.String(150), nullable=False)
    match_date = db.Column(db.Date, nullable=False)
    kick_off_time = db.Column(db.Time, nullable=True)
    venue = db.Column(db.String(200), nullable=True)
    home_away = db.Column(db.Enum(HomeAway), nullable=False)
    match_officials = db.Column(db.String(300), nullable=True)
    match_report = db.Column(db.Text, nullable=True)
    status = db.Column(db.Enum(MatchStatus), nullable=False, default=MatchStatus.scheduled)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    fixture = db.relationship("Fixture", backref="match", uselist=False, lazy=True)
    result = db.relationship("Result", backref="match", uselist=False, lazy=True)

    def __repr__(self):
        return f"<Match {self.opponent} - {self.match_date}>"
