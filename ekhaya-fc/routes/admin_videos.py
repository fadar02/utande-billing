from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required
from models import db, Video

admin_videos_bp = Blueprint('admin_videos', __name__, url_prefix='/admin/videos')


@admin_videos_bp.route('/')
@login_required
def list_videos():
    videos = Video.query.order_by(Video.created_at.desc()).all()
    return render_template('admin/videos/list.html', videos=videos)


@admin_videos_bp.route('/add', methods=['GET', 'POST'])
@login_required
def add_video():
    if request.method == 'POST':
        video = Video(
            title=request.form.get('title'),
            description=request.form.get('description'),
            video_url=request.form.get('video_url'),
            category=request.form.get('category', 'match_highlight'),
            is_published=bool(request.form.get('is_published')),
        )
        db.session.add(video)
        db.session.commit()
        flash('Video added successfully.', 'success')
        return redirect(url_for('admin_videos.list_videos'))
    return render_template('admin/videos/add.html')


@admin_videos_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@login_required
def edit_video(id):
    video = Video.query.get_or_404(id)
    if request.method == 'POST':
        video.title = request.form.get('title')
        video.description = request.form.get('description')
        video.video_url = request.form.get('video_url')
        video.category = request.form.get('category', 'match_highlight')
        video.is_published = bool(request.form.get('is_published'))
        db.session.commit()
        flash('Video updated successfully.', 'success')
        return redirect(url_for('admin_videos.list_videos'))
    return render_template('admin/videos/edit.html', video=video)


@admin_videos_bp.route('/<int:id>/delete', methods=['POST'])
@login_required
def delete_video(id):
    video = Video.query.get_or_404(id)
    db.session.delete(video)
    db.session.commit()
    flash('Video deleted successfully.', 'success')
    return redirect(url_for('admin_videos.list_videos'))
