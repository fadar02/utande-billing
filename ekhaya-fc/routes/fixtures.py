from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_required

from app import admin_required
from models import db, Fixture, Match, FixtureStatus

fixtures_bp = Blueprint('fixtures', __name__, url_prefix='/admin/fixtures')


@fixtures_bp.route('/')
@admin_required
def list_fixtures():
    fixtures = Fixture.query.order_by(Fixture.match_date.desc()).all()
    return render_template('admin/fixtures/list.html', fixtures=fixtures)


@fixtures_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_fixture():
    if request.method == 'POST':
        fixture = Fixture(
            match_id=int(request.form['match_id']),
            competition=request.form['competition'],
            match_date=datetime.strptime(request.form['match_date'], '%Y-%m-%d').date(),
            kick_off_time=datetime.strptime(request.form['kick_off_time'], '%H:%M').time() if request.form.get('kick_off_time') else None,
            venue=request.form.get('venue'),
            home_away=request.form['home_away'],
            opponent=request.form['opponent'],
            match_status=FixtureStatus(request.form.get('match_status', 'upcoming'))
        )
        db.session.add(fixture)
        db.session.commit()
        flash('Fixture added successfully.', 'success')
        return redirect(url_for('fixtures.list_fixtures'))
    matches = Match.query.order_by(Match.match_date.desc()).all()
    return render_template('admin/fixtures/add.html', matches=matches)


@fixtures_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_fixture(id):
    fixture = Fixture.query.get_or_404(id)
    if request.method == 'POST':
        fixture.match_id = int(request.form['match_id'])
        fixture.competition = request.form['competition']
        fixture.match_date = datetime.strptime(request.form['match_date'], '%Y-%m-%d').date()
        fixture.kick_off_time = datetime.strptime(request.form['kick_off_time'], '%H:%M').time() if request.form.get('kick_off_time') else None
        fixture.venue = request.form.get('venue')
        fixture.home_away = request.form['home_away']
        fixture.opponent = request.form['opponent']
        fixture.match_status = FixtureStatus(request.form.get('match_status', fixture.match_status.value))
        db.session.commit()
        flash('Fixture updated successfully.', 'success')
        return redirect(url_for('fixtures.list_fixtures'))
    matches = Match.query.order_by(Match.match_date.desc()).all()
    return render_template('admin/fixtures/edit.html', fixture=fixture, matches=matches)


@fixtures_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_fixture(id):
    fixture = Fixture.query.get_or_404(id)
    db.session.delete(fixture)
    db.session.commit()
    flash('Fixture deleted successfully.', 'success')
    return redirect(url_for('fixtures.list_fixtures'))


@fixtures_bp.route('/<int:id>/toggle-status', methods=['POST'])
@admin_required
def toggle_status(id):
    fixture = Fixture.query.get_or_404(id)
    if fixture.match_status == FixtureStatus.upcoming:
        fixture.match_status = FixtureStatus.in_progress
    elif fixture.match_status == FixtureStatus.in_progress:
        fixture.match_status = FixtureStatus.completed
    else:
        fixture.match_status = FixtureStatus.upcoming
    db.session.commit()
    flash(f'Fixture status updated to {fixture.match_status.value}.', 'success')
    return redirect(url_for('fixtures.list_fixtures'))
