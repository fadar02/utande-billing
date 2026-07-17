import os
from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash, current_app
from flask_login import login_required
from werkzeug.utils import secure_filename

from app import admin_required
from models import db, Staff, StaffRole

staff_bp = Blueprint('staff', __name__, url_prefix='/admin/staff')


def save_upload(file, subfolder):
    if not file or file.filename == '':
        return None
    filename = secure_filename(file.filename)
    filename = f"{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{filename}"
    upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], subfolder)
    os.makedirs(upload_dir, exist_ok=True)
    file.save(os.path.join(upload_dir, filename))
    return filename


@staff_bp.route('/')
@admin_required
def list_staff():
    staff_members = Staff.query.order_by(Staff.full_name).all()
    return render_template('admin/staff/list.html', staff_members=staff_members)


@staff_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_staff():
    if request.method == 'POST':
        photo = save_upload(request.files.get('photo'), 'staff')
        staff = Staff(
            full_name=request.form['full_name'],
            role=StaffRole(request.form['role']),
            phone=request.form.get('phone'),
            email=request.form.get('email'),
            bio=request.form.get('bio'),
            photo=photo
        )
        db.session.add(staff)
        db.session.commit()
        flash('Staff member added successfully.', 'success')
        return redirect(url_for('staff.list_staff'))
    return render_template('admin/staff/add.html')


@staff_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_staff(id):
    staff = Staff.query.get_or_404(id)
    if request.method == 'POST':
        photo = save_upload(request.files.get('photo'), 'staff')
        if photo:
            old_photo = os.path.join(current_app.config['UPLOAD_FOLDER'], 'staff', staff.photo) if staff.photo else None
            if old_photo and os.path.exists(old_photo):
                os.remove(old_photo)
            staff.photo = photo
        staff.full_name = request.form['full_name']
        staff.role = StaffRole(request.form['role'])
        staff.phone = request.form.get('phone')
        staff.email = request.form.get('email')
        staff.bio = request.form.get('bio')
        db.session.commit()
        flash('Staff member updated successfully.', 'success')
        return redirect(url_for('staff.list_staff'))
    return render_template('admin/staff/edit.html', staff=staff)


@staff_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_staff(id):
    staff = Staff.query.get_or_404(id)
    if staff.photo:
        photo_path = os.path.join(current_app.config['UPLOAD_FOLDER'], 'staff', staff.photo)
        if os.path.exists(photo_path):
            os.remove(photo_path)
    db.session.delete(staff)
    db.session.commit()
    flash('Staff member deleted successfully.', 'success')
    return redirect(url_for('staff.list_staff'))


@staff_bp.route('/<int:id>/toggle-status', methods=['POST'])
@admin_required
def toggle_status(id):
    staff = Staff.query.get_or_404(id)
    db.session.commit()
    flash('Staff status updated.', 'success')
    return redirect(url_for('staff.list_staff'))
