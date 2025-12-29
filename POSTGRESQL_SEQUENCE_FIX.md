# PostgreSQL Sequence Fix Guide

## Problem
After deploying to Railway, user registration fails with:
- **Client Error**: `FormatException: Unexpected character (at character 1) Internal server Error`
- **Server Error**: `psycopg2.errors.UniqueViolation: duplicate key value violates unique constraint "users_pkey"`

## Root Cause
When data is migrated to PostgreSQL, the auto-increment sequences are not automatically updated. The database tries to assign IDs that already exist (1, 2, etc.), causing duplicate key violations.

## Solution

### Option 1: Run Fix Script via Railway CLI (Recommended)

1. **Install Railway CLI** (if not already installed):
   ```bash
   # Windows (PowerShell as Administrator)
   iwr https://railway.app/install.ps1 | iex
   
   # Or using npm
   npm install -g @railway/cli
   ```

2. **Login to Railway**:
   ```bash
   railway login
   ```

3. **Link to your project**:
   ```bash
   cd buyv_backend
   railway link
   ```

4. **Run the fix script**:
   ```bash
   railway run python fix_sequences.py
   ```

### Option 2: Direct Database Access via Railway Dashboard

1. Go to your Railway project dashboard
2. Click on your PostgreSQL database service
3. Go to the "Data" tab or "Connect" tab
4. Use the provided database URL or connect button
5. Run this SQL command:

```sql
-- Fix users table sequence
SELECT setval(
    pg_get_serial_sequence('users', 'id'),
    COALESCE((SELECT MAX(id) FROM users), 0) + 1,
    false
);

-- Fix other tables if they exist
SELECT setval(pg_get_serial_sequence('reels', 'id'), COALESCE((SELECT MAX(id) FROM reels), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('products', 'id'), COALESCE((SELECT MAX(id) FROM products), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('orders', 'id'), COALESCE((SELECT MAX(id) FROM orders), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('categories', 'id'), COALESCE((SELECT MAX(id) FROM categories), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('notifications', 'id'), COALESCE((SELECT MAX(id) FROM notifications), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('follows', 'id'), COALESCE((SELECT MAX(id) FROM follows), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('likes', 'id'), COALESCE((SELECT MAX(id) FROM likes), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('comments', 'id'), COALESCE((SELECT MAX(id) FROM comments), 0) + 1, false);
```

### Option 3: Add Script to Railway Deployment

1. **Update your Railway deployment to run the fix automatically**:

   Add to your `Procfile` or create a startup script:
   ```
   release: python fix_sequences.py
   web: uvicorn app.main:app --host 0.0.0.0 --port $PORT
   ```

2. **Commit and push**:
   ```bash
   cd buyv_backend
   git add fix_sequences.py Procfile
   git commit -m "Add sequence fix script"
   git push
   ```

3. Railway will run the fix script before starting your app

## Verification

After running the fix:

1. **Check the Railway logs** to confirm the script ran successfully
2. **Test user registration** from your Flutter app
3. You should be able to create new accounts without errors

## What Was Changed

### 1. Created `fix_sequences.py`
- Automatically detects and fixes all table sequences
- Safe to run multiple times (idempotent)
- Handles missing tables gracefully

### 2. Improved Error Handling in `auth.py`
- Added proper `IntegrityError` handling
- Returns JSON error responses instead of HTML
- Better error messages for debugging

## Prevention

To prevent this issue in the future:

1. **Always reset sequences after manual data imports**:
   ```sql
   SELECT setval(pg_get_serial_sequence('table_name', 'id'), 
                 COALESCE((SELECT MAX(id) FROM table_name), 0) + 1, false);
   ```

2. **Use proper migration tools** like Alembic that handle sequences automatically

3. **Test after deployment** to catch these issues early

## Troubleshooting

### If the fix script fails:

1. **Check DATABASE_URL environment variable**:
   ```bash
   railway variables
   ```

2. **Manually connect to database**:
   ```bash
   railway connect postgres
   ```
   Then run the SQL commands directly

3. **Check Railway logs**:
   ```bash
   railway logs
   ```

### If registration still fails:

1. Check for other database constraints
2. Verify the error message in Railway logs
3. Ensure the backend is using the updated code with improved error handling

## Support

If you continue to have issues:
1. Share the full error message from Railway logs
2. Check if the sequence values are correct:
   ```sql
   SELECT last_value FROM users_id_seq;
   SELECT MAX(id) FROM users;
   ```
3. The last_value should be greater than MAX(id)
