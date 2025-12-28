"""
Buyv Admin Panel - Flask-Admin Application
Provides web-based administration interface for the Buyv e-commerce platform
"""

from flask import Flask, redirect, url_for, request, flash
from flask_admin import Admin, AdminIndexView, expose
from flask_admin.contrib.sqla import ModelView
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from flask_babel import Babel
from werkzeug.security import check_password_hash, generate_password_hash
import sys
import os
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add parent directory to path to import backend modules
backend_path = os.path.join(os.path.dirname(__file__), '..', 'buyv_backend')
sys.path.append(backend_path)

# Database configuration - supports PostgreSQL (production) and SQLite (local dev)
DATABASE_URL = os.getenv('DATABASE_URL')

if not DATABASE_URL:
    # Local development: use SQLite
    db_path = os.path.join(backend_path, 'buyv.db')
    DATABASE_URL = f'sqlite:///{db_path}'
else:
    # Production: use PostgreSQL from Railway
    # Fix Railway's postgres:// URL to postgresql://
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# Create database engine
if DATABASE_URL.startswith('sqlite'):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    # PostgreSQL doesn't need check_same_thread
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

import models
from views import (
    UserAdminView, PostAdminView, OrderAdminView, CommissionAdminView,
    CommentAdminView, NotificationAdminView, FollowAdminView, PostLikeAdminView,
    PaymentAdminView
)

# Flask app configuration
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-super-secret-key-change-in-production')
app.config['FLASK_ADMIN_SWATCH'] = 'cerulean'
app.config['BABEL_DEFAULT_LOCALE'] = 'en'
app.config['BABEL_TRANSLATION_DIRECTORIES'] = 'translations'
# Fix for serving static files in production
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0
app.config['TEMPLATES_AUTO_RELOAD'] = True

# Initialize Babel for internationalization
babel = Babel(app)

# Login manager setup
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'admin.login'

# Remove root redirect - Flask-Admin handles it
# @app.route('/')
# def index():
#     if current_user.is_authenticated:
#         return redirect('/admin')
#     return redirect('/login')


class AdminUser(UserMixin):
    """Admin user model for Flask-Login"""
    def __init__(self, id, username):
        self.id = id
        self.username = username


# Hardcoded admin credentials (in production, use database)
ADMIN_USERS = {
    'admin': generate_password_hash('admin123'),  # Change this password!
    'buyv_admin': generate_password_hash('Buyv2024Admin!')
}


@login_manager.user_loader
def load_user(user_id):
    """Load user for Flask-Login"""
    if user_id in ADMIN_USERS:
        return AdminUser(user_id, user_id)
    return None


class SecureAdminIndexView(AdminIndexView):
    """Custom admin index view with authentication and dashboard"""
    
    @expose('/')
    def index(self):
        if not current_user.is_authenticated:
            return redirect(url_for('.login'))
        
        # Get database session
        db = SessionLocal()
        
        try:
            # Calculate statistics
            total_users = db.query(models.User).count()
            verified_users = db.query(models.User).filter_by(is_verified=True).count()
            total_posts = db.query(models.Post).count()
            total_reels = db.query(models.Post).filter_by(type='reel').count()
            total_products = db.query(models.Post).filter_by(type='product').count()
            total_orders = db.query(models.Order).count()
            pending_orders = db.query(models.Order).filter_by(status='pending').count()
            total_commissions = db.query(models.Commission).count()
            pending_commissions = db.query(models.Commission).filter_by(status='pending').count()
            total_comments = db.query(models.Comment).count()
            total_likes = db.query(models.PostLike).count()
            total_follows = db.query(models.Follow).count()
            
            # Calculate revenue (sum of paid commissions)
            paid_commissions = db.query(models.Commission).filter_by(status='paid').all()
            total_revenue = sum(c.amount for c in paid_commissions if c.amount)
            
            # Recent activity
            recent_users = db.query(models.User).order_by(models.User.created_at.desc()).limit(5).all()
            recent_orders = db.query(models.Order).order_by(models.Order.created_at.desc()).limit(5).all()
            
            stats = {
                'users': {
                    'total': total_users,
                    'verified': verified_users,
                    'unverified': total_users - verified_users
                },
                'content': {
                    'total_posts': total_posts,
                    'reels': total_reels,
                    'products': total_products,
                    'comments': total_comments,
                    'likes': total_likes
                },
                'social': {
                    'follows': total_follows
                },
                'commerce': {
                    'total_orders': total_orders,
                    'pending_orders': pending_orders,
                    'total_commissions': total_commissions,
                    'pending_commissions': pending_commissions,
                    'total_revenue': total_revenue
                },
                'recent_users': recent_users,
                'recent_orders': recent_orders
            }
            
            return self.render('admin/index.html', stats=stats)
            
        finally:
            db.close()
    
    @expose('/login', methods=['GET', 'POST'])
    def login(self):
        if current_user.is_authenticated:
            return redirect(url_for('.index'))
        
        if request.method == 'POST':
            username = request.form.get('username')
            password = request.form.get('password')
            
            if username in ADMIN_USERS and check_password_hash(ADMIN_USERS[username], password):
                user = AdminUser(username, username)
                login_user(user)
                flash('Login successful!', 'success')
                return redirect(url_for('.index'))
            else:
                flash('Invalid username or password', 'error')
        
        return self.render('admin/login.html')
    
    @expose('/logout')
    @login_required
    def logout(self):
        logout_user()
        flash('You have been logged out.', 'info')
        return redirect(url_for('.login'))


class SecureModelView(ModelView):
    """Base ModelView with authentication"""
    def is_accessible(self):
        return current_user.is_authenticated
    
    def inaccessible_callback(self, name, **kwargs):
        return redirect(url_for('admin.login'))


# Initialize Flask-Admin at root URL
admin = Admin(
    app,
    name='Buyv Admin',
    index_view=SecureAdminIndexView(name='Dashboard', url='/'),
    base_template='admin/master.html',
    template_mode='bootstrap4',
    url='/'
)

# Get database session
db_session = SessionLocal()

# Add model views to admin
admin.add_view(UserAdminView(models.User, db_session, name='Users', category='User Management'))
admin.add_view(FollowAdminView(models.Follow, db_session, name='Follows', category='User Management'))

admin.add_view(PostAdminView(models.Post, db_session, name='Posts', category='Content'))
admin.add_view(CommentAdminView(models.Comment, db_session, name='Comments', category='Content'))
admin.add_view(PostLikeAdminView(models.PostLike, db_session, name='Likes', category='Content'))

admin.add_view(SecureModelView(models.Order, db_session, name='Orders', category='Commerce'))
admin.add_view(SecureModelView(models.Commission, db_session, name='Commissions', category='Commerce'))

admin.add_view(NotificationAdminView(models.Notification, db_session, name='Notifications', category='System'))


if __name__ == '__main__':
    print("=" * 60)
    print("🚀 Buyv Admin Panel Starting...")
    print("=" * 60)
    print("📊 Dashboard: http://localhost:5000/admin/")
    print("🔐 Login credentials:")
    print("   Username: admin")
    print("   Password: admin123")
    print("=" * 60)
    print("⚠️  IMPORTANT: Change default passwords in production!")
    print("=" * 60)
    
    app.run(debug=True, host='0.0.0.0', port=5000)
