import os
from functools import wraps
from flask import Flask, session, flash, redirect, url_for
from flask_login import LoginManager, current_user
from models import db

login_manager = LoginManager()


def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or current_user.role.value not in ('super_admin', 'club_admin'):
            flash('You do not have permission to access this page.', 'danger')
            return redirect(url_for('main.home'))
        return f(*args, **kwargs)
    return decorated_function


def super_admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or current_user.role.value != 'super_admin':
            flash('Access denied. Super admin only.', 'danger')
            return redirect(url_for('main.home'))
        return f(*args, **kwargs)
    return decorated_function


def create_app():
    app = Flask(__name__)

    base_dir = os.path.abspath(os.path.dirname(__file__))

    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'ekhaya-fc-secret-key-change-in-production')
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(base_dir, 'ekhaya_fc.db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['UPLOAD_FOLDER'] = os.path.join(base_dir, 'static', 'uploads')
    app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024

    db.init_app(app)
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    login_manager.login_message_category = 'warning'

    upload_dirs = ['players', 'staff', 'news', 'gallery', 'products', 'logos', 'reports', 'documents']
    for d in upload_dirs:
        os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], d), exist_ok=True)

    from models import User

    @login_manager.user_loader
    def load_user(user_id):
        return User.query.get(int(user_id))

    from routes.auth import auth_bp
    from routes.main import main_bp
    from routes.admin import admin_bp
    from routes.players import players_bp
    from routes.staff import staff_bp
    from routes.matches import matches_bp
    from routes.fixtures import fixtures_bp
    from routes.results import results_bp
    from routes.league import league_bp
    from routes.merchandise import merchandise_bp
    from routes.gallery import gallery_bp
    from routes.news import news_bp
    from routes.users import users_bp
    from routes.reports import reports_bp
    from routes.documents import documents_bp
    from routes.transactions import transactions_bp
    from routes.notifications import notifications_bp
    from routes.videos import videos_bp
    from routes.admin_videos import admin_videos_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(main_bp)
    app.register_blueprint(admin_bp, url_prefix='/admin')
    app.register_blueprint(players_bp)
    app.register_blueprint(staff_bp)
    app.register_blueprint(matches_bp)
    app.register_blueprint(fixtures_bp)
    app.register_blueprint(results_bp)
    app.register_blueprint(league_bp)
    app.register_blueprint(merchandise_bp)
    app.register_blueprint(gallery_bp)
    app.register_blueprint(news_bp)
    app.register_blueprint(users_bp)
    app.register_blueprint(reports_bp)
    app.register_blueprint(documents_bp)
    app.register_blueprint(transactions_bp)
    app.register_blueprint(notifications_bp)
    app.register_blueprint(videos_bp)
    app.register_blueprint(admin_videos_bp)

    @app.context_processor
    def inject_globals():
        from models import Product
        cart_count = 0
        if 'cart' in session:
            cart_count = len(session['cart'])
        return dict(cart_count=cart_count, club_name='Ekhaya FC')

    return app
