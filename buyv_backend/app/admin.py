"""
Admin endpoint to fix PostgreSQL sequences
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session
from .database import get_db
from .models import User
from .auth import get_current_user

router = APIRouter(prefix="/admin", tags=["admin"])

@router.post("/fix-sequences-public")
def fix_sequences_public(db: Session = Depends(get_db)):
    """
    Public endpoint to fix PostgreSQL sequences (remove after use!)
    This resets all sequences to MAX(id) + 1 for each table.
    """
    
    # List of tables with auto-increment IDs (only existing tables)
    tables = [
        "users",
        "posts",
        "comments",
        "follows",
        "notifications",
        "orders",
        "order_items",
        "commissions",
        "bookmarks",
    ]
    
    results = {}
    
    for table in tables:
        try:
            # Reset the sequence to the maximum ID
            # Use 'true' to mark sequence as "used", so nextval() returns MAX+1
            query = text(f"""
                SELECT setval(
                    pg_get_serial_sequence('{table}', 'id'),
                    COALESCE((SELECT MAX(id) FROM {table}), 0),
                    true
                );
            """)
            result = db.execute(query)
            db.commit()
            results[table] = "✓ Fixed"
        except Exception as e:
            # Rollback on error to continue with next table
            db.rollback()
            results[table] = f"⚠ Error: {str(e)[:100]}"
            continue
    
    return {
        "message": "Sequence fix completed",
        "results": results
    }

@router.post("/fix-sequences")
def fix_sequences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Fix PostgreSQL auto-increment sequences after data migration.
    This resets all sequences to MAX(id) + 1 for each table.
    """
    
    # List of tables with auto-increment IDs
    tables = [
        "users",
        "posts",  # Changed from reels
        "likes",
        "comments",
        "follows",
        "notifications",
        "orders",
        "order_items",
        "commissions",
        "bookmarks",
    ]
    
    results = {}
    
    for table in tables:
        try:
            # Reset the sequence to the maximum ID
            # Use 'true' to mark sequence as "used", so nextval() returns MAX+1
            query = text(f"""
                SELECT setval(
                    pg_get_serial_sequence('{table}', 'id'),
                    COALESCE((SELECT MAX(id) FROM {table}), 0),
                    true
                );
            """)
            result = db.execute(query)
            db.commit()
            results[table] = "✓ Fixed"
        except Exception as e:
            results[table] = f"⚠ Error: {str(e)[:100]}"
            continue
    
    return {
        "message": "Sequence fix completed",
        "results": results
    }
