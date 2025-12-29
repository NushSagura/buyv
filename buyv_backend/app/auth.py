from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from jose import jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from .database import get_db
from .config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES
from . import models
from .schemas import UserCreate, LoginRequest, AuthResponse, UserOut, RefreshTokenRequest

router = APIRouter(prefix="/auth", tags=["auth"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt, int((expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)).total_seconds())


def create_refresh_token(data: dict):
    """Create a refresh token with longer expiry (7 days)"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=7)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def user_to_out(user: models.User) -> UserOut:
    import json
    interests = []
    settings = None
    try:
        interests = json.loads(user.interests) if user.interests else []
    except Exception:
        interests = []
    try:
        settings = json.loads(user.settings) if user.settings else None
    except Exception:
        settings = None

    return UserOut(
        id=user.uid,
        email=user.email,
        username=user.username,
        display_name=user.display_name,
        profile_image_url=user.profile_image_url,
        bio=user.bio,
        followers_count=user.followers_count,
        following_count=user.following_count,
        reels_count=user.reels_count,
        is_verified=user.is_verified,
        created_at=user.created_at,
        updated_at=user.updated_at,
        interests=interests,
        settings=settings,
    )

@router.post("/register", response_model=AuthResponse)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    # Check if email or username exists
    if db.query(models.User).filter(models.User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    if db.query(models.User).filter(models.User.username == payload.username).first():
        raise HTTPException(status_code=400, detail="Username already taken")

    try:
        user = models.User(
            email=payload.email,
            username=payload.username,
            display_name=payload.display_name, # Accessed via snake_case attribute on model
            password_hash=pwd_context.hash(payload.password),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    except IntegrityError as e:
        db.rollback()
        # Handle database constraint violations
        error_msg = str(e.orig)
        if "users_email_key" in error_msg or "email" in error_msg.lower():
            raise HTTPException(status_code=400, detail="Email already registered")
        elif "users_username_key" in error_msg or "username" in error_msg.lower():
            raise HTTPException(status_code=400, detail="Username already taken")
        elif "users_pkey" in error_msg or "duplicate key" in error_msg.lower():
            raise HTTPException(
                status_code=500, 
                detail="Database configuration error. Please contact support."
            )
        else:
            raise HTTPException(status_code=500, detail="Registration failed. Please try again.")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")

    token, expires_in = create_access_token({"sub": user.uid})
    refresh_token = create_refresh_token({"sub": user.uid})
    return AuthResponse(access_token=token, expires_in=expires_in, user=user_to_out(user), refresh_token=refresh_token)

@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == payload.email).first()
    if not user or not pwd_context.verify(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    token, expires_in = create_access_token({"sub": user.uid})
    refresh_token = create_refresh_token({"sub": user.uid})
    return AuthResponse(access_token=token, expires_in=expires_in, user=user_to_out(user), refresh_token=refresh_token)

from fastapi import Header
from jose import JWTError

@router.get("/me", response_model=UserOut)
def me(authorization: str | None = Header(default=None), db: Session = Depends(get_db)):
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization.split(" ", 1)[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        uid = payload.get("sub")
        if not uid:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(models.User).filter(models.User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user_to_out(user)

# Dependency to get the current authenticated user (for protected routes)
def get_current_user(authorization: str | None = Header(default=None), db: Session = Depends(get_db)) -> models.User:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = authorization.split(" ", 1)[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        uid = payload.get("sub")
        if not uid:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(models.User).filter(models.User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.post("/refresh", response_model=AuthResponse)
def refresh_token(payload: RefreshTokenRequest, db: Session = Depends(get_db)):
    """Refresh access token using refresh token"""
    try:
        decoded = jwt.decode(payload.refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        token_type = decoded.get("type")
        
        # Verify it's a refresh token
        if token_type != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        
        uid = decoded.get("sub")
        if not uid:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        # Get user
        user = db.query(models.User).filter(models.User.uid == uid).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Generate new tokens
        new_access_token, expires_in = create_access_token({"sub": user.uid})
        new_refresh_token = create_refresh_token({"sub": user.uid})
        
        return AuthResponse(
            access_token=new_access_token,
            expires_in=expires_in,
            user=user_to_out(user),
            refresh_token=new_refresh_token
        )
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")


# Dependency to get the current authenticated user (optional, for routes that work with or without auth)
def get_current_user_optional(authorization: str | None = Header(default=None), db: Session = Depends(get_db)) -> models.User | None:
    try:
        if not authorization or not authorization.lower().startswith("bearer "):
            return None
        token = authorization.split(" ", 1)[1]
        if not token:
            return None
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        uid = payload.get("sub")
        if not uid:
            return None
        user = db.query(models.User).filter(models.User.uid == uid).first()
        return user
    except (JWTError, Exception):
        # Silently return None if token is invalid or missing
        return None