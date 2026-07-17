from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_required

from app import admin_required
from models import db, Match, MatchStatus, HomeAway

matches_bp = Blueprint('matches', __name__, url_prefix='/admin/matches')


@matches_bp.route('/')
@admin_required
def list_matches():
    matches = Match.query.order_by(Match.match_date.desc()).all()
    return render_template('admin/matches/list.html', matches=matches)


@matches_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_match():
    if request.method == 'POST':
        match = Match(
            opponent=request.form['opponent'],
            competition=request.form['competition'],
            match_date=datetime.strptime(request.form['match_date'], '%Y-%m-%d').date(),
            kick_off_time=datetime.strptime(request.form['kick_off_time'], '%H:%M').time() if request.form.get('kick_off_time') else None,
            venue=request.form.get('venue'),
            home_away=HomeAway(request.form['home_away']),
            match_officials=request.form.get('match_officials'),
            match_report=request.form.get('match_report'),
            status=MatchStatus(request.form.get('status', 'scheduled'))
        )
        db.session.add(match)
        db.session.commit()
        flash('Match added successfully.', 'success')
        return redirect(url_for('matches.list_matches'))
    return render_template('admin/matches/add.html')


@matches_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_match(id):
    match = Match.query.get_or_404(id)
    if request.method == 'POST':
        match.opponent = request.form['opponent']
        match.competition = request.form['competition']
        match.match_date = datetime.strptime(request.form['match_date'], '%Y-%m-%d').date()
        match.kick_off_time = datetime.strptime(request.form['kick_off_time'], '%H:%M').time() if request.form.get('kick_off_time') else None
        match.venue = request.form.get('venue')
        match.home_away = HomeAway(request.form['home_away'])
        match.match_officials = request.form.get('match_officials')
        match.match_report = request.form.get('match_report')
        match.status = MatchStatus(request.form.get('status', match.status.value))
        db.session.commit()
        flash('Match updated successfully.', 'success')
        return redirect(url_for('matches.list_matches'))
    return render_template('admin/matches/edit.html', match=match)


@matches_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_match(id):
    match = Match.query.get_or_404(id)
    db.session.delete(match)
    db.session.commit()
    flash('Match deleted successfully.', 'success')
    return redirect(url_for('matches.list_matches'))


@matches_bp.route('/<int:id>/toggle-status', methods=['POST'])
@admin_required
def toggle_status(id):
    match = Match.query.get_or_404(id)
    if match.status == MatchStatus.scheduled:
        match.status = MatchStatus.live
    elif match.status == MatchStatus.live:
        match.status = MatchStatus.completed
    else:
        match.status = MatchStatus.scheduled
    db.session.commit()
    flash(f'Match status updated to {match.status.value}.', 'success')
    return redirect(url_for('matches.list_matches'))
