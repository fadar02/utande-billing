from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_required

from app import admin_required
from models import db, Result, Match

results_bp = Blueprint('results', __name__, url_prefix='/admin/results')


@results_bp.route('/')
@admin_required
def list_results():
    results = Result.query.order_by(Result.created_at.desc()).all()
    return render_template('admin/results/list.html', results=results)


@results_bp.route('/add', methods=['GET', 'POST'])
@admin_required
def add_result():
    if request.method == 'POST':
        result = Result(
            match_id=int(request.form['match_id']),
            home_score=int(request.form['home_score']),
            away_score=int(request.form['away_score']),
            goal_scorers=request.form.get('goal_scorers'),
            yellow_cards=request.form.get('yellow_cards'),
            red_cards=request.form.get('red_cards'),
            match_summary=request.form.get('match_summary')
        )
        db.session.add(result)
        db.session.commit()
        flash('Result added successfully.', 'success')
        return redirect(url_for('results.list_results'))
    matches = Match.query.order_by(Match.match_date.desc()).all()
    return render_template('admin/results/add.html', matches=matches)


@results_bp.route('/<int:id>/edit', methods=['GET', 'POST'])
@admin_required
def edit_result(id):
    result = Result.query.get_or_404(id)
    if request.method == 'POST':
        result.match_id = int(request.form['match_id'])
        result.home_score = int(request.form['home_score'])
        result.away_score = int(request.form['away_score'])
        result.goal_scorers = request.form.get('goal_scorers')
        result.yellow_cards = request.form.get('yellow_cards')
        result.red_cards = request.form.get('red_cards')
        result.match_summary = request.form.get('match_summary')
        db.session.commit()
        flash('Result updated successfully.', 'success')
        return redirect(url_for('results.list_results'))
    matches = Match.query.order_by(Match.match_date.desc()).all()
    return render_template('admin/results/edit.html', result=result, matches=matches)


@results_bp.route('/<int:id>/delete', methods=['POST'])
@admin_required
def delete_result(id):
    result = Result.query.get_or_404(id)
    db.session.delete(result)
    db.session.commit()
    flash('Result deleted successfully.', 'success')
    return redirect(url_for('results.list_results'))
