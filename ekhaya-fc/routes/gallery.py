import os
from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash, current_app
from flask_login import login_required
from werkzeug.utils import secure_filename

from app import admin_required
from models import db, Gallery, MediaType, GalleryCategory

gallery_bp = Blueprint('gallery', __name__, url_prefix='/admin/gallery')


def save_upload(file, subfolder):
    if not file or file.filename == '':
        return None
    filename = secure_filename(file.filename)
    filename = f"{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{filename}"
    upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], subfolder)
    os.makedirs(upload_dir, exist_ok=True)
    file.save(os.path.join(upload_dir, filename))
    return filename


@gallery_bp.route('/')
@admin_required
def list_gallery():
    items = Gallery.query.order_by(Gallery.created_at.desc()).all()
    return render_template('admin/gallery/list.html', items=items)


@gallery_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_item():
    if request.method == 'POST':
        media_type = MediaType(request.form['media_type'])
        subfolder = 'gallery/photos' if media_type == MediaType.photo else 'gallery/videos'
        file_path = save_upload(request.files.get('file_path'), subfolder)
        item = Gallery(
            title=request.form['title'],
            caption=request.form.get('caption'),
            media_type=media_type,
            file_path=file_path,
            category=GalleryCategory(request.form['category'])
        )
        db.session.add(item)
        db.session.commit()
        flash('Gallery item added successfully.', 'success')
        return redirect(url_for('gallery.list_gallery'))
    return render_template('admin/gallery/add.html')


@gallery_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_item(id):
    item = Gallery.query.get_or_404(id)
    if request.method == 'POST':
        media_type = MediaType(request.form['media_type'])
        subfolder = 'gallery/photos' if media_type == MediaType.photo else 'gallery/videos'
        file_upload = save_upload(request.files.get('file_path'), subfolder)
        if file_upload:
            old_path = os.path.join(current_app.config['UPLOAD_FOLDER'], item.file_path) if item.file_path else None
            if old_path and os.path.exists(old_path):
                os.remove(old_path)
            item.file_path = file_upload
        item.title = request.form['title']
        item.caption = request.form.get('caption')
        item.media_type = media_type
        item.category = GalleryCategory(request.form['category'])
        db.session.commit()
        flash('Gallery item updated successfully.', 'success')
        return redirect(url_for('gallery.list_gallery'))
    return render_template('admin/gallery/edit.html', item=item)


@gallery_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_item(id):
    item = Gallery.query.get_or_404(id)
    if item.file_path:
        file_path = os.path.join(current_app.config['UPLOAD_FOLDER'], item.file_path)
        if os.path.exists(file_path):
            os.remove(file_path)
    db.session.delete(item)
    db.session.commit()
    flash('Gallery item deleted successfully.', 'success')
    return redirect(url_for('gallery.list_gallery'))
