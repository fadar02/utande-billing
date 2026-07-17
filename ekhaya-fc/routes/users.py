from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_required, current_user

from app import super_admin_required
from models import db, User, UserRole

users_bp = Blueprint('users', __name__, url_prefix='/admin/users')


@users_bp.route('/')
@super_admin_required
def list_users():
    users = User.query.order_by(User.created_at.desc()).all()
    return render_template('admin/users/list.html', users=users)


@users_bp.route('/add', methods=['GET', 'POST'])
@super_admin_required
def add_user():
    if request.method == 'POST':
        username = request.form['username']
        email = request.form['email']
        if User.query.filter_by(username=username).first():
            flash('Username already exists.', 'danger')
            return redirect(url_for('users.add_user'))
        if User.query.filter_by(email=email).first():
            flash('Email already exists.', 'danger')
            return redirect(url_for('users.add_user'))
        user = User(
            username=username,
            email=email,
            full_name=request.form['full_name'],
            role=UserRole(request.form['role']),
            is_active='is_active' in request.form
        )
        user.set_password(request.form['password'])
        db.session.add(user)
        db.session.commit()
        flash('User added successfully.', 'success')
        return redirect(url_for('users.list_users'))
    return render_template('admin/users/add.html')


@users_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@super_admin_required
def edit_user(id):
    user = User.query.get_or_404(id)
    if request.method == 'POST':
        email = request.form['email']
        existing = User.query.filter_by(email=email).first()
        if existing and existing.id != user.id:
            flash('Email already exists.', 'danger')
            return redirect(url_for('users.edit_user', id=id))
        user.full_name = request.form['full_name']
        user.email = email
        user.role = UserRole(request.form['role'])
        user.is_active = 'is_active' in request.form
        if request.form.get('password'):
            user.set_password(request.form['password'])
        db.session.commit()
        flash('User updated successfully.', 'success')
        return redirect(url_for('users.list_users'))
    return render_template('admin/users/edit.html', user=user)


@users_bp.route('/<int:id>/toggle-active', methods=['POST'])
@super_admin_required
def toggle_active(id):
    user = User.query.get_or_404(id)
    if user.id == current_user.id:
        flash('You cannot deactivate your own account.', 'danger')
        return redirect(url_for('users.list_users'))
    user.is_active = not user.is_active
    db.session.commit()
    status = 'activated' if user.is_active else 'deactivated'
    flash(f'User {status}.', 'success')
    return redirect(url_for('users.list_users'))


@users_bp.route('/<int:id>/delete', methods=['POST'])
@super_admin_required
def delete_user(id):
    user = User.query.get_or_404(id)
    if user.id == current_user.id:
        flash('You cannot delete your own account.', 'danger')
        return redirect(url_for('users.list_users'))
    db.session.delete(user)
    db.session.commit()
    flash('User deleted successfully.', 'success')
    return redirect(url_for('users.list_users'))
