import enum
from datetime import datetime, timezone

from models import db


class MediaType(enum.Enum):
    photo = "photo"
    video = "video"


class GalleryCategory(enum.Enum):
    match = "match"
    training = "training"
    event = "event"


class Gallery(db.Model):
    __tablename__ = "gallery"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    caption = db.Column(db.Text, nullable=True)
    media_type = db.Column(db.Enum(MediaType), nullable=False)
    file_path = db.Column(db.String(255), nullable=False)
    category = db.Column(db.Enum(GalleryCategory), nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<Gallery {self.title}>"
