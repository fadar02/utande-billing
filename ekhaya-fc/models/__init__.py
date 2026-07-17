from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

from models.user import User, UserRole
from models.player import Player, PlayerStatus
from models.staff import Staff, StaffRole
from models.match import Match, MatchStatus, HomeAway
from models.fixture import Fixture, FixtureStatus
from models.result import Result
from models.league_table import LeagueTable
from models.product import Product, ProductCategory
from models.order import Order, OrderStatus
from models.gallery import Gallery, MediaType, GalleryCategory
from models.news import News, NewsCategory
from models.contact import ContactMessage
from models.document import Document, DocumentCategory
from models.transaction import Transaction, TransactionType
from models.notification import Notification, NotificationType
from models.video import Video
