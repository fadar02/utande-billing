from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_required, current_user

from app import admin_required
from models import db, Notification, NotificationType

notifications_bp = Blueprint('notifications', __name__, url_prefix='/admin/notifications')


@notifications_bp.route('/')
@admin_required
def list_notifications():
    notifications = Notification.query.order_by(Notification.created_at.desc()).all()
    unread_count = Notification.query.filter_by(is_read=False).count()
    return render_template('admin/notifications/list.html', notifications=notifications, unread_count=unread_count)


@notifications_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_notification():
    if request.method == 'POST':
        notification = Notification(
            title=request.form['title'],
            message=request.form['message'],
            type=NotificationType(request.form['type']),
            link=request.form.get('link')
        )
        db.session.add(notification)
        db.session.commit()
        flash('Notification created successfully.', 'success')
        return redirect(url_for('notifications.list_notifications'))
    return render_template('admin/notifications/add.html')


@notifications_bp.route('/<int:id>/read', methods=['POST'])
@admin_required
def mark_read(id):
    notification = Notification.query.get_or_404(id)
    notification.is_read = True
    db.session.commit()
    flash('Notification marked as read.', 'success')
    return redirect(url_for('notifications.list_notifications'))


@notifications_bp.route('/read-all', methods=['POST'])
@admin_required
def mark_all_read():
    Notification.query.filter_by(is_read=False).update({'is_read': True})
    db.session.commit()
    flash('All notifications marked as read.', 'success')
    return redirect(url_for('notifications.list_notifications'))


@notifications_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_notification(id):
    notification = Notification.query.get_or_404(id)
    db.session.delete(notification)
    db.session.commit()
    flash('Notification deleted.', 'success')
    return redirect(url_for('notifications.list_notifications'))
