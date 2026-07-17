import enum
from datetime import datetime, timezone

from models import db


class DocumentCategory(enum.Enum):
    player_registration = "player_registration"
    club_document = "club_document"
    team_sheet = "team_sheet"
    match_report = "match_report"
    other = "other"


class Document(db.Model):
    __tablename__ = "documents"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    category = db.Column(db.Enum(DocumentCategory), nullable=False, default=DocumentCategory.other)
    file_path = db.Column(db.String(500), nullable=False)
    file_type = db.Column(db.String(50), nullable=True)
    uploaded_by = db.Column(db.String(150), nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<Document {self.title}>"
