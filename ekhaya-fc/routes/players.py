import os
from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash, current_app
from flask_login import login_required
from werkzeug.utils import secure_filename

from app import admin_required
from models import db, Player, PlayerStatus

players_bp = Blueprint('players', __name__, url_prefix='/admin/players')


def save_upload(file, subfolder):
    if not file or file.filename == '':
        return None
    filename = secure_filename(file.filename)
    filename = f"{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{filename}"
    upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], subfolder)
    os.makedirs(upload_dir, exist_ok=True)
    file.save(os.path.join(upload_dir, filename))
    return filename


@players_bp.route('/')
@admin_required
def list_players():
    players = Player.query.order_by(Player.jersey_number).all()
    return render_template('admin/players/list.html', players=players)


@players_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_player():
    if request.method == 'POST':
        photo = save_upload(request.files.get('photo'), 'players')
        player = Player(
            full_name=request.form['full_name'],
            jersey_number=int(request.form['jersey_number']),
            position=request.form['position'],
            date_of_birth=datetime.strptime(request.form['date_of_birth'], '%Y-%m-%d').date() if request.form.get('date_of_birth') else None,
            nationality=request.form.get('nationality'),
            height=float(request.form['height']) if request.form.get('height') else None,
            weight=float(request.form['weight']) if request.form.get('weight') else None,
            phone=request.form.get('phone'),
            email=request.form.get('email'),
            emergency_contact=request.form.get('emergency_contact'),
            preferred_foot=request.form.get('preferred_foot'),
            appearances=int(request.form.get('appearances', 0)),
            goals=int(request.form.get('goals', 0)),
            assists=int(request.form.get('assists', 0)),
            yellow_cards=int(request.form.get('yellow_cards', 0)),
            red_cards=int(request.form.get('red_cards', 0)),
            minutes_played=int(request.form.get('minutes_played', 0)),
            photo=photo,
            status=PlayerStatus(request.form.get('status', 'active'))
        )
        db.session.add(player)
        db.session.commit()
        flash('Player added successfully.', 'success')
        return redirect(url_for('players.list_players'))
    return render_template('admin/players/add.html')


@players_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_player(id):
    player = Player.query.get_or_404(id)
    if request.method == 'POST':
        photo = save_upload(request.files.get('photo'), 'players')
        if photo:
            old_photo = os.path.join(current_app.config['UPLOAD_FOLDER'], 'players', player.photo) if player.photo else None
            if old_photo and os.path.exists(old_photo):
                os.remove(old_photo)
            player.photo = photo
        player.full_name = request.form['full_name']
        player.jersey_number = int(request.form['jersey_number'])
        player.position = request.form['position']
        player.date_of_birth = datetime.strptime(request.form['date_of_birth'], '%Y-%m-%d').date() if request.form.get('date_of_birth') else None
        player.nationality = request.form.get('nationality')
        player.height = float(request.form['height']) if request.form.get('height') else None
        player.weight = float(request.form['weight']) if request.form.get('weight') else None
        player.phone = request.form.get('phone')
        player.email = request.form.get('email')
        player.emergency_contact = request.form.get('emergency_contact')
        player.preferred_foot = request.form.get('preferred_foot')
        player.appearances = int(request.form.get('appearances', 0))
        player.goals = int(request.form.get('goals', 0))
        player.assists = int(request.form.get('assists', 0))
        player.yellow_cards = int(request.form.get('yellow_cards', 0))
        player.red_cards = int(request.form.get('red_cards', 0))
        player.minutes_played = int(request.form.get('minutes_played', 0))
        player.status = PlayerStatus(request.form.get('status', player.status.value))
        db.session.commit()
        flash('Player updated successfully.', 'success')
        return redirect(url_for('players.list_players'))
    return render_template('admin/players/edit.html', player=player)


@players_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_player(id):
    player = Player.query.get_or_404(id)
    if player.photo:
        photo_path = os.path.join(current_app.config['UPLOAD_FOLDER'], 'players', player.photo)
        if os.path.exists(photo_path):
            os.remove(photo_path)
    db.session.delete(player)
    db.session.commit()
    flash('Player deleted successfully.', 'success')
    return redirect(url_for('players.list_players'))


@players_bp.route('/<int:id>/toggle-status', methods=['POST'])
@admin_required
def toggle_status(id):
    player = Player.query.get_or_404(id)
    if player.status == PlayerStatus.active:
        player.status = PlayerStatus.inactive
    else:
        player.status = PlayerStatus.active
    db.session.commit()
    flash(f'Player status updated to {player.status.value}.', 'success')
    return redirect(url_for('players.list_players'))
