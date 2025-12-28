# Buyv Admin Panel

Administration web interface for the Buyv e-commerce platform built with Flask-Admin.

## 🚀 Features

### Dashboard
- 📊 Real-time statistics (users, posts, orders, revenue)
- 📈 Recent activity monitoring
- 💰 Commission tracking
- 📦 Order management

### User Management
- 👥 View all users
- ✅ Verify/unverify users
- 🔍 Search and filter users
- 📊 User statistics (followers, posts, etc.)
- 🗑️ Delete accounts

### Content Management
- 📝 Manage posts (reels, products)
- 💬 Moderate comments
- ❤️ View likes and engagement
- 🔖 Monitor bookmarks

### Commerce Management
- 📦 Order tracking and management
- 💰 Commission approval and payment
- 💳 Payment processing
- 📊 Revenue analytics

### System Management
- 🔔 Notification monitoring
- 👥 Follow relationships
- 🔐 Secure authentication

## 📦 Installation

### Quick Start (Windows)
Double-click `start_admin.bat`

### Manual Installation
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the admin panel
python app.py
```

## 🔐 Login Credentials

**Default Admin:**
- Username: `admin`
- Password: `admin123`

**Alternative Admin:**
- Username: `buyv_admin`
- Password: `Buyv2024Admin!`

⚠️ **IMPORTANT**: Change these passwords in production!

## 🌐 Access

Once started, access the admin panel at:
- **URL**: http://localhost:5000/admin/
- **Dashboard**: http://localhost:5000/admin/
- **Login**: http://localhost:5000/admin/login

## 📂 Structure

```
buyv_admin/
├── app.py              # Main Flask application
├── views.py            # Custom ModelView classes
├── requirements.txt    # Python dependencies
├── start_admin.bat     # Windows startup script
├── templates/
│   └── admin/
│       ├── index.html    # Dashboard template
│       ├── login.html    # Login page
│       └── master.html   # Base template
└── venv/               # Virtual environment (auto-created)
```

## 🔧 Configuration

### Database
The admin panel uses the **same database** as the main backend (`buyv.db`).
No additional database setup required!

### Security
Edit `app.py` to change admin credentials:
```python
ADMIN_USERS = {
    'your_username': generate_password_hash('your_secure_password')
}
```

### Port Configuration
Default port is `5000`. To change, edit `app.py`:
```python
app.run(debug=True, host='0.0.0.0', port=YOUR_PORT)
```

## 📊 Available Models

- **Users** - User account management
- **Posts** - Content (reels, products, posts)
- **Comments** - Comment moderation
- **Likes** - Engagement tracking
- **Bookmarks** - Saved content
- **Follows** - Social connections
- **Orders** - E-commerce orders
- **Commissions** - Influencer commissions
- **Payments** - Payment processing
- **Notifications** - System notifications

## 🎯 Common Tasks

### Verify a User
1. Go to **User Management → Users**
2. Select user(s)
3. Click **Actions → Verify Users**

### Mark Commission as Paid
1. Go to **Commerce → Commissions**
2. Select commission(s)
3. Click **Actions → Mark as Paid**

### Delete Content
1. Navigate to the appropriate section
2. Find the item
3. Click delete (trash icon)

## 🔒 Security Notes

- Admin panel requires authentication
- All routes are protected
- Session-based security with Flask-Login
- Only authenticated admins can access data
- Passwords are hashed with Werkzeug

## 🛠️ Troubleshooting

### "Module not found" error
```bash
pip install -r requirements.txt
```

### Database not found
Make sure you're in the correct directory and `buyv.db` exists in `../buyv_backend/`

### Port already in use
Change the port in `app.py` or stop the process using port 5000

## 📝 Notes

- The admin panel runs **separately** from the FastAPI backend
- Backend (FastAPI) runs on port **8000**
- Admin panel (Flask) runs on port **5000**
- Both can run simultaneously

## 🚀 Production Deployment

For production:
1. Change default passwords
2. Set `app.config['SECRET_KEY']` to a secure random value
3. Set `debug=False` in `app.run()`
4. Use a production WSGI server (gunicorn, uWSGI)
5. Add HTTPS/SSL
6. Configure firewall rules
7. Use environment variables for credentials

---

**Built with ❤️ for Buyv E-commerce Platform**
