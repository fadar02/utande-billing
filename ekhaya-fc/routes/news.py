import os
from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash, current_app
from flask_login import login_required
from werkzeug.utils import secure_filename

from app import admin_required
from models import db, News, NewsCategory

news_bp = Blueprint('news', __name__, url_prefix='/admin/news')


def save_upload(file, subfolder):
    if not file or file.filename == '':
        return None
    filename = secure_filename(file.filename)
    filename = f"{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{filename}"
    upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], subfolder)
    os.makedirs(upload_dir, exist_ok=True)
    file.save(os.path.join(upload_dir, filename))
    return filename


@news_bp.route('/')
@admin_required
def list_news():
    articles = News.query.order_by(News.created_at.desc()).all()
    return render_template('admin/news/list.html', articles=articles)


@news_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_article():
    if request.method == 'POST':
        image = save_upload(request.files.get('image'), 'news')
        article = News(
            title=request.form['title'],
            content=request.form['content'],
            author=request.form['author'],
            category=NewsCategory(request.form['category']) if request.form.get('category') else None,
            image=image,
            is_published='is_published' in request.form
        )
        db.session.add(article)
        db.session.commit()
        flash('Article added successfully.', 'success')
        return redirect(url_for('news.list_news'))
    return render_template('admin/news/add.html')


@news_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_article(id):
    article = News.query.get_or_404(id)
    if request.method == 'POST':
        image = save_upload(request.files.get('image'), 'news')
        if image:
            old_image = os.path.join(current_app.config['UPLOAD_FOLDER'], 'news', article.image) if article.image else None
            if old_image and os.path.exists(old_image):
                os.remove(old_image)
            article.image = image
        article.title = request.form['title']
        article.content = request.form['content']
        article.author = request.form['author']
        article.category = NewsCategory(request.form['category']) if request.form.get('category') else None
        article.is_published = 'is_published' in request.form
        db.session.commit()
        flash('Article updated successfully.', 'success')
        return redirect(url_for('news.list_news'))
    return render_template('admin/news/edit.html', article=article)


@news_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_article(id):
    article = News.query.get_or_404(id)
    if article.image:
        image_path = os.path.join(current_app.config['UPLOAD_FOLDER'], 'news', article.image)
        if os.path.exists(image_path):
            os.remove(image_path)
    db.session.delete(article)
    db.session.commit()
    flash('Article deleted successfully.', 'success')
    return redirect(url_for('news.list_news'))


@news_bp.route('/<int:id>/toggle-publish', methods=['POST'])
@admin_required
def toggle_publish(id):
    article = News.query.get_or_404(id)
    article.is_published = not article.is_published
    db.session.commit()
    status = 'published' if article.is_published else 'unpublished'
    flash(f'Article {status}.', 'success')
    return redirect(url_for('news.list_news'))
