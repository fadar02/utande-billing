import re
from datetime import datetime, timezone

from models import db


class Video(db.Model):
    __tablename__ = "videos"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    video_url = db.Column(db.String(500), nullable=False)
    thumbnail = db.Column(db.String(255), nullable=True)
    category = db.Column(db.String(100), nullable=True, default='match_highlight')
    is_published = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    def __repr__(self):
        return f"<Video {self.title}>"

    @property
    def embed_url(self):
        """Convert YouTube or Facebook video URL to embed URL."""
        url = self.video_url.strip()

        # YouTube
        yt_match = re.search(r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([a-zA-Z0-9_-]{11})', url)
        if yt_match:
            return f"https://www.youtube.com/embed/{yt_match.group(1)}"

        # Facebook
        if 'facebook.com' in url or 'fb.watch' in url:
            return f"https://www.facebook.com/plugins/video.php?href={url}"

        return url

    @property
    def platform(self):
        url = self.video_url.strip()
        if 'youtube.com' in url or 'youtu.be' in url:
            return 'youtube'
        if 'facebook.com' in url or 'fb.watch' in url:
            return 'facebook'
        return 'other'
