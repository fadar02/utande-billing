from datetime import datetime
from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user
from app import admin_required
from models import db, User, Player, Staff, Match, Fixture, Result, LeagueTable, Product, Order, Gallery, News, ContactMessage, Transaction, TransactionType, Notification, PlayerStatus

admin_bp = Blueprint('admin', __name__)


@admin_bp.before_request
@login_required
def before_request():
    pass


@admin_bp.route('/')
@admin_required
def dashboard():
    total_players = Player.query.count()
    injured_players = Player.query.filter_by(status=PlayerStatus.injured).count()
    total_staff = Staff.query.count()
    upcoming_matches = Fixture.query.filter(Fixture.match_date >= datetime.utcnow().date()).count()
    total_fixtures = Fixture.query.count()
    total_results = Result.query.count()
    total_news = News.query.count()
    total_products = Product.query.count()
    total_orders = Order.query.count()
    unread_messages = ContactMessage.query.filter_by(is_read=False).count()
    recent_orders = Order.query.order_by(Order.created_at.desc()).limit(5).all()
    recent_messages = ContactMessage.query.order_by(ContactMessage.created_at.desc()).limit(5).all()

    total_income = db.session.query(db.func.sum(Transaction.amount)).filter_by(type=TransactionType.income).scalar() or 0
    total_expenses = db.session.query(db.func.sum(Transaction.amount)).filter_by(type=TransactionType.expense).scalar() or 0
    club_balance = total_income - total_expenses
    monthly_income = db.session.query(db.func.sum(Transaction.amount)).filter(
        Transaction.type == TransactionType.income,
        db.extract('month', Transaction.transaction_date) == datetime.utcnow().month,
        db.extract('year', Transaction.transaction_date) == datetime.utcnow().year
    ).scalar() or 0
    monthly_expenses = db.session.query(db.func.sum(Transaction.amount)).filter(
        Transaction.type == TransactionType.expense,
        db.extract('month', Transaction.transaction_date) == datetime.utcnow().month,
        db.extract('year', Transaction.transaction_date) == datetime.utcnow().year
    ).scalar() or 0

    latest_news = News.query.filter_by(is_published=True).order_by(News.created_at.desc()).limit(3).all()
    recent_transactions = Transaction.query.order_by(Transaction.transaction_date.desc()).limit(5).all()

    next_match = Fixture.query.filter(Fixture.match_date >= datetime.utcnow().date()).order_by(Fixture.match_date.asc()).first()
    unread_notifications = Notification.query.filter_by(is_read=False).count()

    league_position = LeagueTable.query.filter_by(season=str(datetime.utcnow().year)).order_by(LeagueTable.position.asc()).first()

    return render_template('admin/dashboard.html',
                           total_players=total_players,
                           injured_players=injured_players,
                           total_staff=total_staff,
                           upcoming_matches=upcoming_matches,
                           total_fixtures=total_fixtures,
                           total_results=total_results,
                           total_news=total_news,
                           total_products=total_products,
                           total_orders=total_orders,
                           unread_messages=unread_messages,
                           recent_orders=recent_orders,
                           recent_messages=recent_messages,
                           club_balance=club_balance,
                           monthly_income=monthly_income,
                           monthly_expenses=monthly_expenses,
                           latest_news=latest_news,
                           recent_transactions=recent_transactions,
                           next_match=next_match,
                           unread_notifications=unread_notifications,
                           league_position=league_position)
