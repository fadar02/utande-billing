import enum
from datetime import datetime, timezone

from models import db


class NewsCategory(enum.Enum):
    match_preview = "match_preview"
    match_report = "match_report"
    player_interview = "player_interview"
    club_announcement = "club_announcement"


class News(db.Model):
    __tablename__ = "news"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    content = db.Column(db.Text, nullable=False)
    author = db.Column(db.String(150), nullable=False)
    category = db.Column(db.Enum(NewsCategory), nullable=True)
    image = db.Column(db.String(255), nullable=True)
    is_published = db.Column(db.Boolean, nullable=False, default=False)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<News {self.title}>"
