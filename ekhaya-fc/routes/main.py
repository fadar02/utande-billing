from datetime import datetime
from flask import Blueprint, render_template, request, flash, redirect, url_for
from models import db, News, Fixture, Result, LeagueTable, Player, Staff, Gallery, ContactMessage

main_bp = Blueprint('main', __name__)


@main_bp.route('/')
def home():
    latest_news = News.query.filter_by(is_published=True).order_by(News.created_at.desc()).limit(3).all()
    upcoming_fixtures = Fixture.query.filter(
        Fixture.match_date >= datetime.utcnow().date()
    ).order_by(Fixture.match_date.asc()).limit(5).all()
    latest_results = Result.query.order_by(Result.created_at.desc()).limit(5).all()
    featured_players = Player.query.filter_by(is_featured=True).limit(6).all()
    total_players = Player.query.count()
    league_position = LeagueTable.query.filter_by(season=str(datetime.utcnow().year)).order_by(LeagueTable.position.asc()).first()
    return render_template('main/home.html',
                           latest_news=latest_news,
                           upcoming_fixtures=upcoming_fixtures,
                           latest_results=latest_results,
                           featured_players=featured_players,
                           total_players=total_players,
                           league_position=league_position)


@main_bp.route('/about')
def about():
    return render_template('main/about.html')


@main_bp.route('/history')
def history():
    return render_template('main/history.html')


@main_bp.route('/vision')
def vision():
    return render_template('main/vision.html')


@main_bp.route('/news')
def news_list():
    page = request.args.get('page', 1, type=int)
    articles = News.query.filter_by(is_published=True).order_by(News.created_at.desc()).paginate(
        page=page, per_page=9, error_out=False
    )
    return render_template('main/news_list.html', articles=articles)


@main_bp.route('/news/<int:id>')
def news_detail(id):
    article = News.query.get_or_404(id)
    related = News.query.filter(News.id != id, News.is_published == True).order_by(
        News.created_at.desc()
    ).limit(3).all()
    return render_template('main/news_detail.html', article=article, related=related)


@main_bp.route('/fixtures')
def fixtures():
    page = request.args.get('page', 1, type=int)
    fixtures_list = Fixture.query.order_by(Fixture.match_date.desc()).paginate(
        page=page, per_page=12, error_out=False
    )
    return render_template('main/fixtures.html', fixtures=fixtures_list)


@main_bp.route('/results')
def results():
    page = request.args.get('page', 1, type=int)
    results_list = Result.query.order_by(Result.created_at.desc()).paginate(
        page=page, per_page=12, error_out=False
    )
    return render_template('main/results.html', results=results_list)


@main_bp.route('/league-table')
def league_table():
    standings = LeagueTable.query.order_by(
        LeagueTable.points.desc(),
        LeagueTable.goal_difference.desc(),
        LeagueTable.goals_for.desc()
    ).all()
    return render_template('main/league_table.html', standings=standings)


@main_bp.route('/players')
def players():
    position = request.args.get('position', '')
    query = Player.query
    if position:
        query = query.filter_by(position=position)
    players_list = query.order_by(Player.jersey_number.asc()).all()
    positions = db.session.query(Player.position).distinct().all()
    positions = [p[0] for p in positions if p[0]]
    return render_template('main/players.html', players=players_list, positions=positions, current_position=position)


@main_bp.route('/players/<int:id>')
def player_detail(id):
    player = Player.query.get_or_404(id)
    return render_template('main/player_detail.html', player=player)


@main_bp.route('/technical-team')
def technical_team():
    staff_list = Staff.query.order_by(Staff.full_name.asc()).all()
    return render_template('main/technical_team.html', staff=staff_list)


@main_bp.route('/gallery')
def gallery():
    page = request.args.get('page', 1, type=int)
    category = request.args.get('category', '')
    query = Gallery.query
    if category:
        query = query.filter_by(category=category)
    photos = query.order_by(Gallery.created_at.desc()).paginate(
        page=page, per_page=12, error_out=False
    )
    categories = db.session.query(Gallery.category).distinct().all()
    categories = [c[0].value if hasattr(c[0], 'value') else c[0] for c in categories if c[0]]
    return render_template('main/gallery.html', photos=photos, categories=categories, current_category=category)


@main_bp.route('/contact', methods=['GET', 'POST'])
def contact():
    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        email = request.form.get('email', '').strip()
        phone = request.form.get('phone', '').strip()
        subject = request.form.get('subject', '').strip()
        message = request.form.get('message', '').strip()

        if not name or not email or not message:
            flash('Name, email, and message are required.', 'danger')
            return render_template('main/contact.html')

        contact_msg = ContactMessage(
            name=name,
            email=email,
            phone=phone,
            subject=subject,
            message=message
        )
        db.session.add(contact_msg)
        db.session.commit()

        flash('Your message has been sent. We will get back to you shortly!', 'success')
        return redirect(url_for('main.contact'))

    return render_template('main/contact.html')
