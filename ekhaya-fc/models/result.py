from datetime import datetime, timezone

from models import db


class Result(db.Model):
    __tablename__ = "results"

    id = db.Column(db.Integer, primary_key=True)
    match_id = db.Column(db.Integer, db.ForeignKey("matches.id"), nullable=False)
    home_score = db.Column(db.Integer, nullable=False, default=0)
    away_score = db.Column(db.Integer, nullable=False, default=0)
    goal_scorers = db.Column(db.Text, nullable=True)
    yellow_cards = db.Column(db.Text, nullable=True)
    red_cards = db.Column(db.Text, nullable=True)
    match_summary = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<Result {self.home_score} - {self.away_score}>"
