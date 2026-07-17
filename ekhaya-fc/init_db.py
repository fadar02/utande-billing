from datetime import datetime, date, time

from app import create_app, db
from models.user import User, UserRole
from models.player import Player, PlayerStatus
from models.staff import Staff, StaffRole
from models.match import Match, MatchStatus, HomeAway
from models.fixture import Fixture, FixtureStatus
from models.result import Result
from models.league_table import LeagueTable
from models.product import Product, ProductCategory
from models.news import News, NewsCategory
from models.gallery import Gallery, GalleryCategory, MediaType
from models.transaction import Transaction, TransactionType
from models.notification import Notification, NotificationType
from models.video import Video


def init_database():
    app = create_app()
    with app.app_context():
        db.create_all()

        if User.query.first():
            print("Database already contains data. Skipping initialization.")
            return

        admin = User(
            username='admin',
            email='admin@ekhayafc.com',
            full_name='System Administrator',
            role=UserRole.super_admin,
        )
        admin.set_password('admin123')
        db.session.add(admin)
        db.session.commit()
        print("Created super admin user: admin@ekhayafc.com / admin123")

        players = [
            Player(
                full_name='Joshua Waka',
                jersey_number=1,
                position='Goalkeeper',
                date_of_birth=date(2005, 3, 15),
                nationality='Malawian',
                height=185.0,
                weight=80.0,
                phone='+265 991 100 001',
                email='joshua.waka@ekhayafc.mw',
                emergency_contact='Mr. Waka - +265 991 100 011',
                preferred_foot='Right',
                appearances=9,
                goals=0,
                assists=0,
                yellow_cards=0,
                red_cards=0,
                minutes_played=810,
                is_featured=True,
                status=PlayerStatus.active,
            ),
            Player(
                full_name='Clever Mkungula',
                jersey_number=22,
                position='Goalkeeper',
                date_of_birth=date(2000, 6, 12),
                nationality='Malawian',
                height=183.0,
                weight=78.0,
                phone='+265 991 100 002',
                email='clever.mkungula@ekhayafc.mw',
                emergency_contact='Mrs. Mkungula - +265 991 100 012',
                preferred_foot='Right',
                appearances=0,
                goals=0,
                assists=0,
                yellow_cards=0,
                red_cards=0,
                minutes_played=0,
                is_featured=False,
                status=PlayerStatus.active,
            ),
            Player(
                full_name='Kerstein Simbi',
                jersey_number=4,
                position='Defender',
                date_of_birth=date(2003, 2, 8),
                nationality='Malawian',
                height=180.0,
                weight=76.0,
                phone='+265 991 100 003',
                email='kerstein.simbi@ekhayafc.mw',
                emergency_contact='Mr. Simbi - +265 991 100 013',
                preferred_foot='Right',
                appearances=9,
                goals=0,
                assists=1,
                yellow_cards=2,
                red_cards=0,
                minutes_played=810,
                is_featured=True,
                status=PlayerStatus.active,
            ),
            Player(
                full_name='Alick Lungu',
                jersey_number=3,
                position='Defender',
                date_of_birth=date(2002, 3, 24),
                nationality='Malawian',
                height=175.0,
                weight=72.0,
                phone='+265 991 100 004',
                email='alick.lungu@ekhayafc.mw',
                emergency_contact='Mrs. Lungu - +265 991 100 014',
                preferred_foot='Left',
                appearances=9,
                goals=1,
                assists=2,
                yellow_cards=1,
                red_cards=0,
                minutes_played=810,
                is_featured=True,
                status=PlayerStatus.active,
            ),
            Player(
                full_name='Fanizo Mwansambo',
                jersey_number=2,
                position='Defender',
                date_of_birth=date(2001, 7, 15),
                nationality='Malawian',
                height=178.0,
                weight=74.0,
                phone='+265 991 100 005',
                email='fanizo.mwansambo@ekhayafc.mw',
                emergency_contact='Mr. Mwansambo - +265 991 100 015',
                preferred_foot='Right',
                appearances=7,
                goals=0,
                assists=1,
                yellow_cards=2,
                red_cards=0,
                minutes_played=630,
                is_featured=False,
                status=PlayerStatus.active,
            ),
            Player(
                full_name='Stanley Billiat',
                jersey_number=8,
                position='Midfielder',
                date_of_birth=date(2003, 5, 20),
                nationality='Malawian',
                height=174.0,
                weight=70.0,
                phone='+265 991 100 006',
                email='stanley.billiat@ekhayafc.mw',
                emergency_contact='Ms. Billiat - +265 991 100 016',
                preferred_foot='Right',
                appearances=9,
                goals=2,
                assists=3,
                yellow_cards=1,
                red_cards=0,
                minutes_played=780,
                is_featured=True,
                status=PlayerStatus.active,
            ),
            Player(
                full_name='Levison Mnyenyembe',
                jersey_number=10,
                position='Midfielder',
                date_of_birth=date(2006, 1, 10),
                nationality='Malawian',
                height=172.0,
                weight=66.0,
                phone='+265 991 100 007',
                email='levison.mnyenyembe@ekhayafc.mw',
                emergency_contact='Mr. Mnyenyembe - +265 991 100 017',
                preferred_foot='Right',
                appearances=9,
                goals=3,
                assists=4,
                yellow_cards=1,
                red_cards=0,
                minutes_played=750,
                is_featured=True,
                status=PlayerStatus.active,
            ),
            Player(
                full_name='Christopher Gototo',
                jersey_number=9,
                position='Forward',
                date_of_birth=date(2002, 8, 5),
                nationality='Malawian',
                height=180.0,
                weight=76.0,
                phone='+265 991 100 008',
                email='christopher.gototo@ekhayafc.mw',
                emergency_contact='Mrs. Gototo - +265 991 100 018',
                preferred_foot='Right',
                appearances=9,
                goals=4,
                assists=1,
                yellow_cards=2,
                red_cards=0,
                minutes_played=790,
                is_featured=True,
                status=PlayerStatus.active,
            ),
            Player(
                full_name='Joseph Saiwa',
                jersey_number=7,
                position='Forward',
                date_of_birth=date(2001, 11, 18),
                nationality='Malawian',
                height=176.0,
                weight=72.0,
                phone='+265 991 100 009',
                email='joseph.saiwa@ekhayafc.mw',
                emergency_contact='Mr. Saiwa - +265 991 100 019',
                preferred_foot='Right',
                appearances=8,
                goals=2,
                assists=2,
                yellow_cards=1,
                red_cards=0,
                minutes_played=680,
                is_featured=True,
                status=PlayerStatus.active,
            ),
            Player(
                full_name='Gomezgani Chirwa',
                jersey_number=6,
                position='Defender',
                date_of_birth=date(1998, 9, 5),
                nationality='Malawian',
                height=182.0,
                weight=78.0,
                phone='+265 991 100 010',
                email='gomezgani.chirwa@ekhayafc.mw',
                emergency_contact='Mr. Chirwa - +265 991 100 020',
                preferred_foot='Right',
                appearances=5,
                goals=0,
                assists=0,
                yellow_cards=3,
                red_cards=1,
                minutes_played=420,
                is_featured=False,
                status=PlayerStatus.injured,
            ),
        ]
        db.session.add_all(players)
        db.session.commit()
        print("Created 5 sample players")

        staff = [
            Staff(
                full_name='John Banda',
                role=StaffRole.head_coach,
                phone='+265 996 789 012',
                email='john.banda@ekhayafc.mw',
                bio='Former Malawi national team player with over 15 years of coaching experience.',
            ),
            Staff(
                full_name='Patrick Mwanza',
                role=StaffRole.assistant_coach,
                phone='+265 997 890 123',
                email='patrick.mwanza@ekhayafc.mw',
                bio='UEFA B licensed coach specializing in tactical development and youth mentorship.',
            ),
            Staff(
                full_name='Charles Mnthukwa',
                role=StaffRole.goalkeeper_coach,
                phone='+265 998 901 234',
                email='charles.mnthukwa@ekhayafc.mw',
                bio='Dedicated goalkeeper coach with expertise in shot-stopping and distribution training.',
            ),
            Staff(
                full_name='Dr. Florence Ngoma',
                role=StaffRole.team_doctor,
                phone='+265 999 012 345',
                email='florence.ngoma@ekhayafc.mw',
                bio='Qualified sports medicine physician responsible for player health and injury prevention.',
            ),
            Staff(
                full_name='Samuel Banda',
                role=StaffRole.physio,
                phone='+265 991 123 456',
                email='samuel.banda@ekhayafc.mw',
                bio='Experienced physiotherapist specializing in sports rehabilitation and recovery.',
            ),
            Staff(
                full_name='Grace Moyo',
                role=StaffRole.kit_manager,
                phone='+265 992 234 567',
                email='grace.moyo@ekhayafc.mw',
                bio='Detail-oriented kit manager ensuring the team is always match-ready.',
            ),
            Staff(
                full_name='Innocent Msowoya',
                role=StaffRole.club_secretary,
                phone='+265 993 345 678',
                email='innocent.msowoya@ekhayafc.mw',
                bio='Club secretary handling administrative duties, correspondence, and compliance.',
            ),
            Staff(
                full_name='Chikondi Kanjere',
                role=StaffRole.media_officer,
                phone='+265 994 456 789',
                email='chikondi.kanjere@ekhayafc.mw',
                bio='Media officer managing club communications, social media, and press relations.',
            ),
        ]
        db.session.add_all(staff)
        db.session.commit()
        print("Created 4 sample staff members")

        completed_matches = [
            Match(
                opponent='Blue Eagles',
                opponent_logo='images/logos/blue-eagles.png',
                competition='TNM Super League',
                match_date=date(2026, 4, 26),
                kick_off_time=time(8, 30),
                venue='Area 47 Ground',
                home_away=HomeAway.away,
                status=MatchStatus.completed,
                match_officials='Referee: TNM Super League',
                match_report='Ekhaya fell to a 2-1 away defeat at Blue Eagles in the opening match of the season.',
            ),
            Match(
                opponent='Red Lions',
                opponent_logo='images/logos/red-lions.png',
                competition='TNM Super League',
                match_date=date(2026, 5, 2),
                kick_off_time=time(8, 30),
                venue='Kamuzu Stadium',
                home_away=HomeAway.home,
                status=MatchStatus.completed,
                match_officials='Referee: TNM Super League',
                match_report='Ekhaya and Red Lions shared the spoils in a 1-1 draw at Kamuzu Stadium.',
            ),
            Match(
                opponent='Civo Utd',
                opponent_logo='images/logos/civo-united.png',
                competition='TNM Super League',
                match_date=date(2026, 5, 9),
                kick_off_time=time(8, 30),
                venue='Civo Stadium',
                home_away=HomeAway.away,
                status=MatchStatus.completed,
                match_officials='Referee: TNM Super League',
                match_report='Ekhaya suffered a narrow 1-0 away loss to Civo Utd.',
            ),
            Match(
                opponent='Moyale Barracks',
                opponent_logo='images/logos/moyale-barracks.png',
                competition='TNM Super League',
                match_date=date(2026, 5, 16),
                kick_off_time=time(8, 30),
                venue='Kamuzu Stadium',
                home_away=HomeAway.home,
                status=MatchStatus.completed,
                match_officials='Referee: TNM Super League',
                match_report='Ekhaya cruised to a convincing 2-0 home victory over Moyale Barracks.',
            ),
            Match(
                opponent='Kamuzu Barracks',
                opponent_logo='images/logos/kamuzu-barracks.png',
                competition='TNM Super League',
                match_date=date(2026, 5, 23),
                kick_off_time=time(8, 30),
                venue='Mzuzu Stadium',
                home_away=HomeAway.away,
                status=MatchStatus.completed,
                match_officials='Referee: TNM Super League',
                match_report='A stunning 4-1 away demolition of Kamuzu Barracks kept Ekhaya in the title hunt.',
            ),
            Match(
                opponent='Masters FC',
                opponent_logo='images/logos/masters-fc.png',
                competition='TNM Super League',
                match_date=date(2026, 5, 30),
                kick_off_time=time(8, 30),
                venue='Kamuzu Stadium',
                home_away=HomeAway.home,
                status=MatchStatus.completed,
                match_officials='Referee: TNM Super League',
                match_report='Ekhaya beat Masters FC 2-0 at home with a solid defensive display.',
            ),
            Match(
                opponent='Mighty Wanderers',
                opponent_logo='images/logos/mighty-wanderers.png',
                competition='TNM Super League',
                match_date=date(2026, 6, 20),
                kick_off_time=time(8, 30),
                venue='Kamuzu Stadium',
                home_away=HomeAway.away,
                status=MatchStatus.completed,
                match_officials='Referee: TNM Super League',
                match_report='A hard-fought 1-1 draw against rivals Mighty Wanderers in a fiery derby.',
            ),
            Match(
                opponent='MAFCO',
                opponent_logo='images/logos/mafco.png',
                competition='TNM Super League',
                match_date=date(2026, 6, 28),
                kick_off_time=time(8, 30),
                venue='Kamuzu Stadium',
                home_away=HomeAway.home,
                status=MatchStatus.completed,
                match_officials='Referee: TNM Super League',
                match_report='Ekhaya edged past MAFCO 1-0 in a tight encounter at Kamuzu Stadium.',
            ),
            Match(
                opponent='Mitundu Baptist',
                opponent_logo='images/logos/mitundu-baptist.png',
                competition='TNM Super League',
                match_date=date(2026, 7, 5),
                kick_off_time=time(8, 30),
                venue='Mitundu Ground',
                home_away=HomeAway.away,
                status=MatchStatus.completed,
                match_officials='Referee: TNM Super League',
                match_report='A goalless draw away at Mitundu Baptist as both teams cancelled each other out.',
            ),
        ]
        db.session.add_all(completed_matches)
        db.session.commit()
        print("Created 9 completed matches")

        upcoming_match_objects = [
            Match(opponent='Big Bullets', opponent_logo='images/logos/big-bullets.png', competition='TNM Super League', match_date=date(2026, 7, 19), kick_off_time=time(8, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='Chitipa United', opponent_logo='images/logos/chitipa-united.png', competition='TNM Super League', match_date=date(2026, 8, 15), kick_off_time=time(8, 30), venue='Chitipa Stadium', home_away=HomeAway.away, status=MatchStatus.scheduled),
            Match(opponent='Dedza Dynamos', opponent_logo='images/logos/dedza-dynamos.png', competition='TNM Super League', match_date=date(2026, 8, 22), kick_off_time=time(8, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='Silver Strikers', opponent_logo='images/logos/silver-strikers.png', competition='TNM Super League', match_date=date(2026, 9, 5), kick_off_time=time(8, 30), venue='Silver Stadium', home_away=HomeAway.away, status=MatchStatus.scheduled),
            Match(opponent='Creck Sporting', opponent_logo='images/logos/creck-sporting.png', competition='TNM Super League', match_date=date(2026, 9, 13), kick_off_time=time(8, 30), venue='Creck Ground', home_away=HomeAway.away, status=MatchStatus.scheduled),
            Match(opponent='Karonga United', opponent_logo='images/logos/karonga-united.png', competition='TNM Super League', match_date=date(2026, 9, 19), kick_off_time=time(8, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='Kamuzu Barracks', opponent_logo='images/logos/kamuzu-barracks.png', competition='TNM Super League', match_date=date(2026, 10, 10), kick_off_time=time(8, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='Red Lions', opponent_logo='images/logos/red-lions.png', competition='TNM Super League', match_date=date(2026, 10, 18), kick_off_time=time(8, 30), venue='Red Lions Ground', home_away=HomeAway.away, status=MatchStatus.scheduled),
            Match(opponent='Blue Eagles', opponent_logo='images/logos/blue-eagles.png', competition='TNM Super League', match_date=date(2026, 10, 25), kick_off_time=time(8, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='MAFCO', opponent_logo='images/logos/mafco.png', competition='TNM Super League', match_date=date(2026, 11, 1), kick_off_time=time(7, 30), venue='MAFCO Ground', home_away=HomeAway.away, status=MatchStatus.scheduled),
            Match(opponent='Civo Utd', opponent_logo='images/logos/civo-united.png', competition='TNM Super League', match_date=date(2026, 11, 21), kick_off_time=time(7, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='Masters FC', opponent_logo='images/logos/masters-fc.png', competition='TNM Super League', match_date=date(2026, 11, 28), kick_off_time=time(7, 30), venue='Masters Ground', home_away=HomeAway.away, status=MatchStatus.scheduled),
            Match(opponent='Mighty Wanderers', opponent_logo='images/logos/mighty-wanderers.png', competition='TNM Super League', match_date=date(2026, 12, 6), kick_off_time=time(7, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='Moyale Barracks', opponent_logo='images/logos/moyale-barracks.png', competition='TNM Super League', match_date=date(2026, 12, 12), kick_off_time=time(7, 30), venue='Moyale Ground', home_away=HomeAway.away, status=MatchStatus.scheduled),
            Match(opponent='Mitundu Baptist', opponent_logo='images/logos/mitundu-baptist.png', competition='TNM Super League', match_date=date(2026, 12, 19), kick_off_time=time(7, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='Big Bullets', opponent_logo='images/logos/big-bullets.png', competition='TNM Super League', match_date=date(2027, 1, 3), kick_off_time=time(8, 30), venue='Kamuzu Stadium', home_away=HomeAway.away, status=MatchStatus.scheduled),
            Match(opponent='Chitipa United', opponent_logo='images/logos/chitipa-united.png', competition='TNM Super League', match_date=date(2027, 1, 16), kick_off_time=time(8, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='Dedza Dynamos', opponent_logo='images/logos/dedza-dynamos.png', competition='TNM Super League', match_date=date(2027, 1, 25), kick_off_time=time(8, 30), venue='Dedza Stadium', home_away=HomeAway.away, status=MatchStatus.scheduled),
            Match(opponent='Silver Strikers', opponent_logo='images/logos/silver-strikers.png', competition='TNM Super League', match_date=date(2027, 1, 31), kick_off_time=time(8, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='Creck Sporting', opponent_logo='images/logos/creck-sporting.png', competition='TNM Super League', match_date=date(2027, 2, 6), kick_off_time=time(8, 30), venue='Kamuzu Stadium', home_away=HomeAway.home, status=MatchStatus.scheduled),
            Match(opponent='Karonga United', opponent_logo='images/logos/karonga-united.png', competition='TNM Super League', match_date=date(2027, 2, 20), kick_off_time=time(8, 30), venue='Karonga Stadium', home_away=HomeAway.away, status=MatchStatus.scheduled),
        ]
        db.session.add_all(upcoming_match_objects)
        db.session.commit()
        print("Created 21 upcoming matches")

        fixtures = []
        for m in upcoming_match_objects:
            fixtures.append(Fixture(
                match_id=m.id,
                competition='TNM Super League',
                match_date=m.match_date,
                kick_off_time=m.kick_off_time,
                venue=m.venue,
                home_away='Home' if m.home_away == HomeAway.home else 'Away',
                opponent=m.opponent,
                match_status=FixtureStatus.upcoming,
            ))
        db.session.add_all(fixtures)
        db.session.commit()
        print("Created 21 fixtures")

        results = [
            Result(match_id=completed_matches[0].id, home_score=2, away_score=1, goal_scorers='Ekhaya scorer (45\')', yellow_cards='', red_cards='', match_summary='Ekhaya fell to a 2-1 away defeat at Blue Eagles.'),
            Result(match_id=completed_matches[1].id, home_score=1, away_score=1, goal_scorers='Ekhaya scorer (62\')', yellow_cards='', red_cards='', match_summary='Ekhaya and Red Lions shared the spoils in a 1-1 draw.'),
            Result(match_id=completed_matches[2].id, home_score=1, away_score=0, goal_scorers='', yellow_cards='', red_cards='', match_summary='Ekhaya suffered a narrow 1-0 away loss to Civo Utd.'),
            Result(match_id=completed_matches[3].id, home_score=2, away_score=0, goal_scorers='Ekhaya scorers (30\'), (75\')', yellow_cards='', red_cards='', match_summary='Ekhaya cruised to a 2-0 home victory over Moyale Barracks.'),
            Result(match_id=completed_matches[4].id, home_score=1, away_score=4, goal_scorers='Ekhaya scorers (12\'), (38\'), (55\'), (82\')', yellow_cards='', red_cards='', match_summary='A stunning 4-1 away demolition of Kamuzu Barracks.'),
            Result(match_id=completed_matches[5].id, home_score=2, away_score=0, goal_scorers='Ekhaya scorers (22\'), (68\')', yellow_cards='', red_cards='', match_summary='Ekhaya beat Masters FC 2-0 at home.'),
            Result(match_id=completed_matches[6].id, home_score=1, away_score=1, goal_scorers='Ekhaya scorer (40\')', yellow_cards='', red_cards='', match_summary='A hard-fought 1-1 draw against Mighty Wanderers.'),
            Result(match_id=completed_matches[7].id, home_score=1, away_score=0, goal_scorers='Ekhaya scorer (55\')', yellow_cards='', red_cards='', match_summary='Ekhaya edged past MAFCO 1-0 at home.'),
            Result(match_id=completed_matches[8].id, home_score=0, away_score=0, goal_scorers='', yellow_cards='', red_cards='', match_summary='A goalless draw away at Mitundu Baptist.'),
        ]
        db.session.add_all(results)
        db.session.commit()
        print("Created 9 results")

        league_entries = [
            LeagueTable(club_name='Blue Eagles', logo='images/logos/blue-eagles.png', played=9, wins=6, draws=1, losses=2, goals_for=12, goals_against=4, goal_difference=8, points=19, position=1, season='2026'),
            LeagueTable(club_name='Big Bullets', logo='images/logos/big-bullets.png', played=9, wins=5, draws=4, losses=0, goals_for=12, goals_against=6, goal_difference=6, points=19, position=2, season='2026'),
            LeagueTable(club_name='Mighty Wanderers', logo='images/logos/mighty-wanderers.png', played=9, wins=5, draws=3, losses=1, goals_for=18, goals_against=6, goal_difference=12, points=18, position=3, season='2026'),
            LeagueTable(club_name='Silver Strikers', logo='images/logos/silver-strikers.png', played=9, wins=5, draws=3, losses=1, goals_for=14, goals_against=3, goal_difference=11, points=18, position=4, season='2026'),
            LeagueTable(club_name='Ekhaya FC', logo='images/logos/ekhaya-fc.png', played=9, wins=4, draws=3, losses=2, goals_for=12, goals_against=6, goal_difference=6, points=15, position=5, season='2026'),
            LeagueTable(club_name='Red Lions', logo='images/logos/red-lions.png', played=9, wins=4, draws=3, losses=2, goals_for=8, goals_against=6, goal_difference=2, points=15, position=6, season='2026'),
            LeagueTable(club_name='Masters FC', logo='images/logos/masters-fc.png', played=9, wins=5, draws=0, losses=4, goals_for=11, goals_against=10, goal_difference=1, points=15, position=7, season='2026'),
            LeagueTable(club_name='Moyale Barracks', logo='images/logos/moyale-barracks.png', played=9, wins=3, draws=3, losses=3, goals_for=8, goals_against=10, goal_difference=-2, points=12, position=8, season='2026'),
            LeagueTable(club_name='Mitundu Baptist', logo='images/logos/mitundu-baptist.png', played=9, wins=3, draws=2, losses=4, goals_for=8, goals_against=10, goal_difference=-2, points=11, position=9, season='2026'),
            LeagueTable(club_name='Civo Utd', logo='images/logos/civo-united.png', played=9, wins=3, draws=2, losses=4, goals_for=6, goals_against=9, goal_difference=-3, points=11, position=10, season='2026'),
            LeagueTable(club_name='Chitipa United', logo='images/logos/chitipa-united.png', played=9, wins=3, draws=1, losses=5, goals_for=6, goals_against=12, goal_difference=-6, points=10, position=11, season='2026'),
            LeagueTable(club_name='MAFCO', logo='images/logos/mafco.png', played=9, wins=2, draws=3, losses=4, goals_for=7, goals_against=8, goal_difference=-1, points=9, position=12, season='2026'),
            LeagueTable(club_name='Karonga United', logo='images/logos/karonga-united.png', played=9, wins=2, draws=3, losses=4, goals_for=9, goals_against=14, goal_difference=-5, points=9, position=13, season='2026'),
            LeagueTable(club_name='Dedza Dynamos', logo='images/logos/dedza-dynamos.png', played=9, wins=2, draws=2, losses=5, goals_for=5, goals_against=15, goal_difference=-10, points=8, position=14, season='2026'),
            LeagueTable(club_name='Creck Sporting', logo='images/logos/creck-sporting.png', played=9, wins=1, draws=2, losses=6, goals_for=6, goals_against=13, goal_difference=-7, points=5, position=15, season='2026'),
            LeagueTable(club_name='Kamuzu Barracks', logo='images/logos/kamuzu-barracks.png', played=9, wins=1, draws=1, losses=7, goals_for=7, goals_against=15, goal_difference=-8, points=4, position=16, season='2026'),
        ]
        db.session.add_all(league_entries)
        db.session.commit()
        print("Created 16 league table entries")

        products = [
            Product(
                name='Ekhaya FC Home Jersey 2026',
                description='Official home jersey in club colours. Premium breathable fabric with embroidered crest.',
                category=ProductCategory.jersey,
                price=25000.0,
                stock_quantity=50,
            ),
            Product(
                name='Ekhaya FC Training T-Shirt',
                description='Lightweight training tee made from moisture-wicking material.',
                category=ProductCategory.tshirt,
                price=8500.0,
                stock_quantity=100,
            ),
            Product(
                name='Ekhaya FC Structured Cap',
                description='Adjustable snapback cap with embroidered club logo.',
                category=ProductCategory.cap,
                price=5000.0,
                stock_quantity=75,
            ),
            Product(
                name='Ekhaya FC Matchday Scarf',
                description='Knitted fan scarf in club colours with woven text.',
                category=ProductCategory.scarf,
                price=6000.0,
                stock_quantity=60,
            ),
            Product(
                name='Matchday Ticket - Ekhaya FC vs Mighty Wanderers',
                description='Entry ticket for the TNM Super League match at Kamuzu Stadium on 19 July 2026.',
                category=ProductCategory.ticket,
                price=2000.0,
                stock_quantity=500,
            ),
        ]
        db.session.add_all(products)
        db.session.commit()
        print("Created 5 sample products")

        articles = [
            News(
                title='Ekhaya FC Maintains Top Spot After Victory',
                content='Ekhaya FC extended their lead at the top of the TNM Super League table with a convincing 3-0 home win over Silver Strikers. Goals from Yamikani Phiri, Hastings Kamanga, and Mphatso Gondwe sealed a memorable afternoon at Kamuzu Stadium. Head Coach John Banda praised the team for their discipline and attacking intent.',
                author='Admin',
                category=NewsCategory.match_report,
                is_published=True,
            ),
            News(
                title='Match Report: Mighty Wanderers FC 1-1 Ekhaya FC',
                content='Ekhaya FC were forced to settle for a share of the spoils after a late equaliser saw them held to a 1-1 draw by Mighty Wanderers in a fiercely contested FDH Bank Premiership encounter. Blessings Malinda had given Ekhaya the lead in the first half, but Wanderers fought back in the closing stages to rescue a point.',
                author='EFC Media',
                category=NewsCategory.match_report,
                is_published=True,
            ),
            News(
                title='Match Report: FCB Nyasa Big Bullets 1-1 Ekhaya FC',
                content='Ekhaya FC delivered a composed and resilient performance away from home to secure a hard-fought 1-1 draw against FCB Nyasa Big Bullets in the first leg of their Airtel Top 8 quarterfinal clash. The result keeps Ekhaya firmly in the tie heading into the second leg at Mpira Stadium.',
                author='EFC Media',
                category=NewsCategory.match_report,
                is_published=True,
            ),
            News(
                title='Match Report: Ekhaya FC 2-0 Masters FC',
                content='Ekhaya FC delivered a statement performance at Mpira Stadium, producing a disciplined and dominant display to defeat Masters FC 2-0 on Saturday afternoon in the FDH Bank Premiership. The victory keeps Ekhaya in the hunt at the top end of the table.',
                author='EFC Media',
                category=NewsCategory.match_report,
                is_published=True,
            ),
            News(
                title='Waka Retains Flames Spot for Ethiopia Friendlies',
                content='Joshua Waka has earned a call-up to the Malawi National Football Team squad for the upcoming international friendlies against Ethiopia national football team. The Flames will face Ethiopia in two friendlies as part of their World Cup qualifying preparation.',
                author='EFC Media',
                category=NewsCategory.club_announcement,
                is_published=True,
            ),
            News(
                title='Ekhaya FC Set for Historic First-Ever Quarter-Final Clash Against FCB Nyasa Big Bullets',
                content='Ekhaya FC are set for a landmark moment in their cup journey as they prepare to face reigning giants FCB Nyasa Big Bullets in the Airtel Top 8 quarter-final first leg at the Bingu National Stadium.',
                author='EFC Media',
                category=NewsCategory.match_preview,
                is_published=True,
            ),
            News(
                title='Medical Update: Blessings Malinda Injury',
                content='Ekhaya FC forward Blessings Malinda sustained a facial injury during the first half of Saturday\'s match against Kamuzu Barracks, following an aerial challenge with an opponent. The medical team is monitoring his recovery closely.',
                author='EFC Media',
                category=NewsCategory.club_announcement,
                is_published=True,
            ),
            News(
                title='Match Report: Kamuzu Barracks 1-4 Ekhaya FC',
                content='Ekhaya FC delivered a statement performance at Champion Stadium on Saturday afternoon, cruising to a 4-1 victory over Kamuzu Barracks to secure their first-ever win at the venue in the FDH Bank Premiership. A stunning away performance from the Cowboys.',
                author='EFC Media',
                category=NewsCategory.match_report,
                is_published=True,
            ),
        ]
        db.session.add_all(articles)
        db.session.commit()
        print("Created 7 real news articles from ekhayafc.com")

        gallery_items = [
            Gallery(
                title='Ekhaya FC vs Silver Strikers - Match Highlights',
                caption='Goals, tackles, and celebrations from the 3-0 home victory.',
                media_type=MediaType.photo,
                file_path='uploads/gallery/match_highlights_01.jpg',
                category=GalleryCategory.match,
            ),
            Gallery(
                title='Pre-Season Training Camp',
                caption='The squad during an intensive training session ahead of the new season.',
                media_type=MediaType.photo,
                file_path='uploads/gallery/training_camp_01.jpg',
                category=GalleryCategory.training,
            ),
            Gallery(
                title='Annual Club Awards Night',
                caption='Players, staff, and fans celebrated at the end-of-season awards ceremony.',
                media_type=MediaType.photo,
                file_path='uploads/gallery/awards_night_01.jpg',
                category=GalleryCategory.event,
            ),
        ]
        db.session.add_all(gallery_items)
        db.session.commit()
        print("Created 3 sample gallery items")

        transactions = [
            Transaction(description='TNM Super League Sponsorship', amount=5000000.0, type=TransactionType.income, category='Sponsorship', reference='Sponsor-2026-001', transaction_date=date(2026, 1, 15)),
            Transaction(description='Gate Revenue - Matchday 14', amount=2500000.0, type=TransactionType.income, category='Gate Revenue', reference='Gate-2026-014', transaction_date=date(2026, 7, 6)),
            Transaction(description='Gate Revenue - Matchday 15', amount=3200000.0, type=TransactionType.income, category='Gate Revenue', reference='Gate-2026-015', transaction_date=date(2026, 7, 13)),
            Transaction(description='Merchandise Sales - July', amount=850000.0, type=TransactionType.income, category='Merchandise', reference='Merch-2026-07', transaction_date=date(2026, 7, 15)),
            Transaction(description='Player Wages - July 2026', amount=3500000.0, type=TransactionType.expense, category='Player Wages', reference='Wages-2026-07', transaction_date=date(2026, 7, 1)),
            Transaction(description='Staff Wages - July 2026', amount=1200000.0, type=TransactionType.expense, category='Staff Wages', reference='Wages-2026-07-S', transaction_date=date(2026, 7, 1)),
            Transaction(description='Travel - Away at Blue Eagles', amount=450000.0, type=TransactionType.expense, category='Travel', reference='Travel-2026-015', transaction_date=date(2026, 7, 12)),
            Transaction(description='Medical Supplies', amount=180000.0, type=TransactionType.expense, category='Medical', reference='Med-2026-07', transaction_date=date(2026, 7, 10)),
            Transaction(description='Training Equipment', amount=320000.0, type=TransactionType.expense, category='Equipment', reference='Equip-2026-07', transaction_date=date(2026, 7, 5)),
        ]
        db.session.add_all(transactions)
        db.session.commit()
        print("Created 9 sample transactions")

        notifications = [
            Notification(title='Match Tomorrow', message='Ekhaya FC vs Kamuzu Barracks at Mzuzu Stadium. Kickoff at 15:00.', type=NotificationType.match_tomorrow, link='/fixtures'),
            Notification(title='Training Today', message='First team training session at 16:00 at Kamuzu Stadium.', type=NotificationType.training_today),
            Notification(title='New Club Announcement', message='New merchandise now available at the club shop!', type=NotificationType.club_announcement, link='/news'),
            Notification(title='Player Birthday', message='Happy Birthday to Yamikani Phiri (#9)!', type=NotificationType.player_birthday),
        ]
        db.session.add_all(notifications)
        db.session.commit()
        print("Created 4 sample notifications")

        videos = [
            Video(title='Ekhaya FC vs FCB Nyasa Big Bullets LIVE - Airtel Top 8', description='LIVE coverage of the Airtel Malawi Top 8 quarterfinal clash between Ekhaya FC and FCB Nyasa Big Bullets at Mpira Stadium.', video_url='https://www.youtube.com/watch?v=tXFgc6nqToA', category='match_highlight', is_published=True),
            Video(title='Ekhaya FC 2-0 Masters FC - FDH Premiership Highlights', description='Highlights from Ekhaya FC dominant 2-0 victory over Masters FC at Mpira Stadium on 30th May 2026.', video_url='https://www.youtube.com/watch?v=_Fe-iNXz2Hc', category='match_highlight', is_published=True),
            Video(title='Ntaja United vs Ekhaya FC - Castel Challenge Cup R32', description='Ekhaya FC in Castel Challenge Cup Round of 32 action against Ntaja United.', video_url='https://www.youtube.com/@EkhayaFC/videos', category='match_highlight', is_published=True),
        ]
        db.session.add_all(videos)
        db.session.commit()
        print("Created 3 sample videos")

        print("\nDatabase initialization complete!")
        print("Login credentials: admin@ekhayafc.com / admin123")


if __name__ == '__main__':
    init_database()
