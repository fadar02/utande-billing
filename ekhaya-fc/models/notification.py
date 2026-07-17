import enum
from datetime import datetime, timezone

from models import db


class NotificationType(enum.Enum):
    match_tomorrow = "match_tomorrow"
    training_today = "training_today"
    club_announcement = "club_announcement"
    player_birthday = "player_birthday"


class Notification(db.Model):
    __tablename__ = "notifications"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    message = db.Column(db.Text, nullable=False)
    type = db.Column(db.Enum(NotificationType), nullable=False)
    is_read = db.Column(db.Boolean, nullable=False, default=False)
    link = db.Column(db.String(300), nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<Notification {self.title}>"
