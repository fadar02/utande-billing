from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_required

from app import admin_required
from models import db, LeagueTable, Match, Result, MatchStatus

league_bp = Blueprint('league', __name__, url_prefix='/admin/league')


def calculate_stats(entry):
    entry.goal_difference = entry.goals_for - entry.goals_against
    entry.points = (entry.wins * 3) + entry.draws
    entry.played = entry.wins + entry.draws + entry.losses


@league_bp.route('/')
@admin_required
def list_league():
    season = request.args.get('season', '')
    query = LeagueTable.query
    if season:
        query = query.filter_by(season=season)
    entries = query.order_by(LeagueTable.position).all()
    seasons = db.session.query(LeagueTable.season).distinct().all()
    seasons = [s[0] for s in seasons]
    return render_template('admin/league/list.html', entries=entries, seasons=seasons, current_season=season)


@league_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_entry():
    if request.method == 'POST':
        entry = LeagueTable(
            club_name=request.form['club_name'],
            played=int(request.form.get('played', 0)),
            wins=int(request.form.get('wins', 0)),
            draws=int(request.form.get('draws', 0)),
            losses=int(request.form.get('losses', 0)),
            goals_for=int(request.form.get('goals_for', 0)),
            goals_against=int(request.form.get('goals_against', 0)),
            position=int(request.form['position']),
            season=request.form['season']
        )
        calculate_stats(entry)
        db.session.add(entry)
        db.session.commit()
        flash('League entry added successfully.', 'success')
        return redirect(url_for('league.list_league'))
    return render_template('admin/league/add.html')


@league_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_entry(id):
    entry = LeagueTable.query.get_or_404(id)
    if request.method == 'POST':
        entry.club_name = request.form['club_name']
        entry.wins = int(request.form.get('wins', 0))
        entry.draws = int(request.form.get('draws', 0))
        entry.losses = int(request.form.get('losses', 0))
        entry.goals_for = int(request.form.get('goals_for', 0))
        entry.goals_against = int(request.form.get('goals_against', 0))
        entry.position = int(request.form['position'])
        entry.season = request.form['season']
        calculate_stats(entry)
        db.session.commit()
        flash('League entry updated successfully.', 'success')
        return redirect(url_for('league.list_league'))
    return render_template('admin/league/edit.html', entry=entry)


@league_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_entry(id):
    entry = LeagueTable.query.get_or_404(id)
    db.session.delete(entry)
    db.session.commit()
    flash('League entry deleted successfully.', 'success')
    return redirect(url_for('league.list_league'))


@league_bp.route('/auto-calculate', methods=['POST'])
@admin_required
def auto_calculate():
    season = request.form.get('season', '')
    if not season:
        flash('Please select a season.', 'danger')
        return redirect(url_for('league.list_league'))

    completed_matches = Match.query.filter_by(status=MatchStatus.completed).all()

    club_stats = {}
    for match in completed_matches:
        result = Result.query.filter_by(match_id=match.id).first()
        if not result:
            continue

        if match.home_away.value == 'home':
            ekhaya_goals = result.home_score
            opponent_goals = result.away_score
            opponent_name = match.opponent
        else:
            ekhaya_goals = result.away_score
            opponent_goals = result.home_score
            opponent_name = match.opponent

        if opponent_name not in club_stats:
            club_stats[opponent_name] = {'played': 0, 'wins': 0, 'draws': 0, 'losses': 0, 'gf': 0, 'ga': 0}

        club_stats[opponent_name]['played'] += 1
        club_stats[opponent_name]['gf'] += ekhaya_goals
        club_stats[opponent_name]['ga'] += opponent_goals

        if ekhaya_goals > opponent_goals:
            club_stats[opponent_name]['wins'] += 1
        elif ekhaya_goals == opponent_goals:
            club_stats[opponent_name]['draws'] += 1
        else:
            club_stats[opponent_name]['losses'] += 1

    LeagueTable.query.filter_by(season=season).delete()

    all_clubs = ['Ekhaya FC'] + list(club_stats.keys())
    entries = []
    for club in all_clubs:
        if club == 'Ekhaya FC':
            played = sum(s['played'] for s in club_stats.values())
            wins = sum(s['wins'] for s in club_stats.values())
            draws = sum(s['draws'] for s in club_stats.values())
            losses = sum(s['losses'] for s in club_stats.values())
            gf = sum(s['gf'] for s in club_stats.values())
            ga = sum(s['ga'] for s in club_stats.values())
        else:
            stats = club_stats[club]
            played = stats['played']
            wins = stats['wins']
            draws = stats['draws']
            losses = stats['losses']
            gf = stats['gf']
            ga = stats['ga']

        gd = gf - ga
        points = (wins * 3) + draws

        entry = LeagueTable(
            club_name=club,
            played=played,
            wins=wins,
            draws=draws,
            losses=losses,
            goals_for=gf,
            goals_against=ga,
            goal_difference=gd,
            points=points,
            position=0,
            season=season
        )
        entries.append(entry)

    entries.sort(key=lambda e: (-e.points, -e.goal_difference, -e.goals_for))
    for i, entry in enumerate(entries, 1):
        entry.position = i

    db.session.add_all(entries)
    db.session.commit()
    flash(f'League table auto-calculated for {season} season with {len(entries)} teams.', 'success')
    return redirect(url_for('league.list_league'))
