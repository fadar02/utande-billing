from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required
from models import db, Video

videos_bp = Blueprint('videos', __name__, url_prefix='/videos')


@videos_bp.route('/')
def list_videos():
    page = request.args.get('page', 1, type=int)
    videos = Video.query.filter_by(is_published=True).order_by(Video.created_at.desc()).paginate(page=page, per_page=12)
    return render_template('main/videos.html', videos=videos)


@videos_bp.route('/<int:id>')
def video_detail(id):
    video = Video.query.get_or_404(id)
    related = Video.query.filter(Video.id != video.id, Video.is_published == True).order_by(Video.created_at.desc()).limit(4).all()
    return render_template('main/video_detail.html', video=video, related=related)
