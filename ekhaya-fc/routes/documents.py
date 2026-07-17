import os
from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash, current_app, send_from_directory
from flask_login import login_required
from werkzeug.utils import secure_filename

from app import admin_required
from models import db, Document, DocumentCategory

documents_bp = Blueprint('documents', __name__, url_prefix='/admin/documents')


def save_upload(file, subfolder):
    if not file or file.filename == '':
        return None
    filename = secure_filename(file.filename)
    filename = f"{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{filename}"
    upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], subfolder)
    os.makedirs(upload_dir, exist_ok=True)
    file.save(os.path.join(upload_dir, filename))
    return filename


@documents_bp.route('/')
@admin_required
def list_documents():
    category = request.args.get('category', '')
    query = Document.query
    if category:
        query = query.filter_by(category=DocumentCategory(category))
    documents = query.order_by(Document.created_at.desc()).all()
    categories = [c.value for c in DocumentCategory]
    return render_template('admin/documents/list.html', documents=documents, categories=categories, current_category=category)


@documents_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_document():
    if request.method == 'POST':
        file = save_upload(request.files.get('file'), 'documents')
        if not file:
            flash('Please select a file to upload.', 'danger')
            return redirect(url_for('documents.add_document'))
        original_name = request.files.get('file').filename
        doc = Document(
            title=request.form['title'],
            description=request.form.get('description'),
            category=DocumentCategory(request.form.get('category', 'other')),
            file_path=file,
            file_type=original_name.rsplit('.', 1)[-1].upper() if '.' in original_name else 'Unknown',
            uploaded_by=request.form.get('uploaded_by', 'Admin')
        )
        db.session.add(doc)
        db.session.commit()
        flash('Document uploaded successfully.', 'success')
        return redirect(url_for('documents.list_documents'))
    return render_template('admin/documents/add.html')


@documents_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_document(id):
    doc = Document.query.get_or_404(id)
    if request.method == 'POST':
        file = save_upload(request.files.get('file'), 'documents')
        if file:
            old_file = os.path.join(current_app.config['UPLOAD_FOLDER'], 'documents', doc.file_path) if doc.file_path else None
            if old_file and os.path.exists(old_file):
                os.remove(old_file)
            doc.file_path = file
            original_name = request.files.get('file').filename
            doc.file_type = original_name.rsplit('.', 1)[-1].upper() if '.' in original_name else doc.file_type
        doc.title = request.form['title']
        doc.description = request.form.get('description')
        doc.category = DocumentCategory(request.form.get('category', 'other'))
        db.session.commit()
        flash('Document updated successfully.', 'success')
        return redirect(url_for('documents.list_documents'))
    return render_template('admin/documents/edit.html', document=doc)


@documents_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_document(id):
    doc = Document.query.get_or_404(id)
    if doc.file_path:
        file_path = os.path.join(current_app.config['UPLOAD_FOLDER'], 'documents', doc.file_path)
        if os.path.exists(file_path):
            os.remove(file_path)
    db.session.delete(doc)
    db.session.commit()
    flash('Document deleted successfully.', 'success')
    return redirect(url_for('documents.list_documents'))


@documents_bp.route('/download/<int:id>')
@admin_required
def download_document(id):
    doc = Document.query.get_or_404(id)
    return send_from_directory(
        os.path.join(current_app.config['UPLOAD_FOLDER'], 'documents'),
        doc.file_path,
        as_attachment=True,
        download_name=doc.title + ('.' + doc.file_type.lower() if doc.file_type else '')
    )
