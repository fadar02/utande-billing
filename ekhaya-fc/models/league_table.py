from datetime import datetime, timezone

from models import db


class LeagueTable(db.Model):
    __tablename__ = "league_table"

    id = db.Column(db.Integer, primary_key=True)
    club_name = db.Column(db.String(150), nullable=False)
    logo = db.Column(db.String(255), nullable=True)
    played = db.Column(db.Integer, nullable=False, default=0)
    wins = db.Column(db.Integer, nullable=False, default=0)
    draws = db.Column(db.Integer, nullable=False, default=0)
    losses = db.Column(db.Integer, nullable=False, default=0)
    goals_for = db.Column(db.Integer, nullable=False, default=0)
    goals_against = db.Column(db.Integer, nullable=False, default=0)
    goal_difference = db.Column(db.Integer, nullable=False, default=0)
    points = db.Column(db.Integer, nullable=False, default=0)
    position = db.Column(db.Integer, nullable=False)
    season = db.Column(db.String(20), nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<LeagueTable {self.club_name} - Pos {self.position}>"
