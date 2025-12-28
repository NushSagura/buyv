"""
Migration Script: SQLite to PostgreSQL
Migrates all data from local SQLite database to Railway PostgreSQL
"""

import os
from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
import sys

# Set default DATABASE_URL to avoid import errors
if 'DATABASE_URL' not in os.environ:
    os.environ['DATABASE_URL'] = 'sqlite:///./temp.db'

# Add backend to path
backend_path = os.path.join(os.path.dirname(__file__), 'buyv_backend')
sys.path.append(backend_path)

from app import models

def migrate_data(sqlite_url, postgres_url):
    """
    Migrate all data from SQLite to PostgreSQL
    
    Args:
        sqlite_url: SQLite connection string (e.g., 'sqlite:///./buyv_backend/buyv.db')
        postgres_url: PostgreSQL connection string from Railway
    """
    
    print("=" * 70)
    print("🚀 Starting Database Migration: SQLite → PostgreSQL")
    print("=" * 70)
    
    # Fix Railway's postgres:// URL
    if postgres_url.startswith("postgres://"):
        postgres_url = postgres_url.replace("postgres://", "postgresql://", 1)
    
    # Create engines
    print("\n📊 Connecting to databases...")
    sqlite_engine = create_engine(sqlite_url, connect_args={"check_same_thread": False})
    postgres_engine = create_engine(postgres_url, pool_pre_ping=True)
    
    # Create sessions
    SQLiteSession = sessionmaker(bind=sqlite_engine)
    PostgresSession = sessionmaker(bind=postgres_engine)
    
    sqlite_session = SQLiteSession()
    postgres_session = PostgresSession()
    
    try:
        # Create all tables in PostgreSQL
        print("\n🔨 Creating tables in PostgreSQL...")
        models.Base.metadata.create_all(bind=postgres_engine)
        print("✅ Tables created successfully")
        
        # List of models to migrate (in order due to foreign keys)
        model_classes = [
            ('Users', models.User),
            ('Posts', models.Post),
            ('Comments', models.Comment),
            ('PostLikes', models.PostLike),
            ('Follows', models.Follow),
            ('Orders', models.Order),
            ('OrderItems', models.OrderItem),
            ('Commissions', models.Commission),
            ('Notifications', models.Notification),
        ]
        
        total_migrated = 0
        
        print("\n📦 Migrating data...")
        print("-" * 70)
        
        for model_name, model_class in model_classes:
            try:
                # Get all records from SQLite
                records = sqlite_session.query(model_class).all()
                count = len(records)
                
                if count == 0:
                    print(f"⚪ {model_name:20} - No data to migrate")
                    continue
                
                # Insert into PostgreSQL
                for record in records:
                    # Convert to dict and remove SQLAlchemy state
                    record_dict = {
                        column.name: getattr(record, column.name)
                        for column in model_class.__table__.columns
                    }
                    
                    # Create new instance for PostgreSQL
                    new_record = model_class(**record_dict)
                    postgres_session.add(new_record)
                
                postgres_session.commit()
                total_migrated += count
                print(f"✅ {model_name:20} - {count:5} records migrated")
                
            except Exception as e:
                postgres_session.rollback()
                print(f"❌ {model_name:20} - Error: {str(e)}")
                continue
        
        print("-" * 70)
        print(f"\n🎉 Migration completed successfully!")
        print(f"📊 Total records migrated: {total_migrated}")
        print("=" * 70)
        
    except Exception as e:
        print(f"\n❌ Migration failed: {str(e)}")
        postgres_session.rollback()
        raise
    
    finally:
        sqlite_session.close()
        postgres_session.close()


if __name__ == "__main__":
    print("\n" + "=" * 70)
    print("🔄 Database Migration Tool")
    print("=" * 70)
    
    # SQLite path
    sqlite_path = os.path.join(os.path.dirname(__file__), 'buyv_backend', 'buyv.db')
    sqlite_url = f'sqlite:///{sqlite_path}'
    
    # Check if SQLite database exists
    if not os.path.exists(sqlite_path):
        print(f"\n❌ Error: SQLite database not found at {sqlite_path}")
        sys.exit(1)
    
    print(f"\n📍 SQLite database found: {sqlite_path}")
    
    # Get PostgreSQL URL from environment or user input
    postgres_url = os.getenv('DATABASE_URL')
    
    if not postgres_url:
        print("\n⚠️  DATABASE_URL not found in environment variables")
        print("\n📝 Please enter your Railway PostgreSQL connection string:")
        print("   (Format: postgresql://user:password@host:port/database)")
        postgres_url = input("\nPostgreSQL URL: ").strip()
        
        if not postgres_url:
            print("\n❌ Error: PostgreSQL URL is required")
            sys.exit(1)
    else:
        print(f"\n✅ Using DATABASE_URL from environment")
    
    # Confirm migration
    print("\n⚠️  WARNING: This will copy all data to PostgreSQL")
    print("   Existing data in PostgreSQL will be kept (duplicates may occur)")
    
    confirm = input("\n❓ Continue with migration? (yes/no): ").strip().lower()
    
    if confirm not in ['yes', 'y']:
        print("\n❌ Migration cancelled")
        sys.exit(0)
    
    # Run migration
    try:
        migrate_data(sqlite_url, postgres_url)
        print("\n✅ You can now deploy your backend and admin panel to Railway!")
        print("   Don't forget to set DATABASE_URL in Railway environment variables")
        
    except Exception as e:
        print(f"\n❌ Migration failed: {str(e)}")
        sys.exit(1)
