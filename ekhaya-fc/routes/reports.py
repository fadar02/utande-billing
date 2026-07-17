from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash, send_file, current_app
from flask_login import login_required

from app import admin_required
from models import db, Player, Match, Fixture, Result, Product, Order, LeagueTable
from utils.pdf_generator import generate_pdf, save_pdf_to_file

reports_bp = Blueprint('reports', __name__, url_prefix='/admin/reports')


@reports_bp.route('/players')
@admin_required
def player_reports():
    players = Player.query.order_by(Player.jersey_number).all()
    return render_template('admin/reports/players.html', players=players)


@reports_bp.route('/matches')
@admin_required
def match_reports():
    matches = Match.query.order_by(Match.match_date.desc()).all()
    return render_template('admin/reports/matches.html', matches=matches)


@reports_bp.route('/fixtures')
@admin_required
def fixture_reports():
    fixtures = Fixture.query.order_by(Fixture.match_date.desc()).all()
    return render_template('admin/reports/fixtures.html', fixtures=fixtures)


@reports_bp.route('/merchandise')
@admin_required
def merchandise_reports():
    products = Product.query.order_by(Product.created_at.desc()).all()
    orders = Order.query.order_by(Order.created_at.desc()).all()
    total_revenue = sum(o.total_amount for o in orders if o.status.value != 'cancelled')
    return render_template('admin/reports/merchandise.html', products=products, orders=orders, total_revenue=total_revenue)


@reports_bp.route('/financial')
@admin_required
def financial_reports():
    orders = Order.query.order_by(Order.created_at.desc()).all()
    total_revenue = sum(o.total_amount for o in orders if o.status.value != 'cancelled')
    pending_revenue = sum(o.total_amount for o in orders if o.status.value == 'pending')
    confirmed_revenue = sum(o.total_amount for o in orders if o.status.value == 'confirmed')
    delivered_revenue = sum(o.total_amount for o in orders if o.status.value == 'delivered')
    cancelled_revenue = sum(o.total_amount for o in orders if o.status.value == 'cancelled')
    return render_template('admin/reports/financial.html',
                           orders=orders,
                           total_revenue=total_revenue,
                           pending_revenue=pending_revenue,
                           confirmed_revenue=confirmed_revenue,
                           delivered_revenue=delivered_revenue,
                           cancelled_revenue=cancelled_revenue)


@reports_bp.route('/pdf/<report_type>')
@admin_required
def generate_report_pdf(report_type):
    timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')

    if report_type == 'players':
        players = Player.query.order_by(Player.jersey_number).all()
        headers = ['#', 'Name', 'Position', 'Nationality', 'Status']
        rows = [[p.jersey_number, p.full_name, p.position, p.nationality or '-', p.status.value] for p in players]
        buffer = generate_pdf('Ekhaya FC - Player Report', headers, rows)
        filename = f'player_report_{timestamp}.pdf'

    elif report_type == 'matches':
        matches = Match.query.order_by(Match.match_date.desc()).all()
        headers = ['Date', 'Opponent', 'Competition', 'Venue', 'H/A', 'Status']
        rows = [[str(m.match_date), m.opponent, m.competition, m.venue or '-', m.home_away.value, m.status.value] for m in matches]
        buffer = generate_pdf('Ekhaya FC - Match Report', headers, rows)
        filename = f'match_report_{timestamp}.pdf'

    elif report_type == 'fixtures':
        fixtures = Fixture.query.order_by(Fixture.match_date.desc()).all()
        headers = ['Date', 'Opponent', 'Competition', 'Venue', 'H/A', 'Status']
        rows = [[str(f.match_date), f.opponent, f.competition, f.venue or '-', f.home_away, f.match_status.value] for f in fixtures]
        buffer = generate_pdf('Ekhaya FC - Fixture Report', headers, rows)
        filename = f'fixture_report_{timestamp}.pdf'

    elif report_type == 'merchandise':
        products = Product.query.order_by(Product.name).all()
        headers = ['Name', 'Category', 'Price', 'Stock', 'Active']
        rows = [[p.name, p.category.value, f'K{p.price:.2f}', str(p.stock_quantity), 'Yes' if p.is_active else 'No'] for p in products]
        buffer = generate_pdf('Ekhaya FC - Merchandise Report', headers, rows)
        filename = f'merchandise_report_{timestamp}.pdf'

    elif report_type == 'financial':
        orders = Order.query.order_by(Order.created_at.desc()).all()
        headers = ['Order ID', 'Customer', 'Product', 'Qty', 'Total', 'Status', 'Date']
        rows = []
        for o in orders:
            rows.append([str(o.id), o.customer_name, o.product.name if o.product else '-', str(o.quantity), f'K{o.total_amount:.2f}', o.status.value, str(o.created_at.date())])
        buffer = generate_pdf('Ekhaya FC - Financial Report', headers, rows)
        filename = f'financial_report_{timestamp}.pdf'

    else:
        flash('Invalid report type.', 'danger')
        return redirect(url_for('reports.player_reports'))

    filepath = save_pdf_to_file(buffer, 'reports', filename)
    buffer.seek(0)
    return send_file(buffer, as_attachment=True, download_name=filename, mimetype='application/pdf')
