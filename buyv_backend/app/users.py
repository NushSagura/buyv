from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from .database import get_db
from . import models
from .schemas import UserOut, UserUpdate
import json

router = APIRouter(prefix="/users", tags=["users"])


def user_to_out(user: models.User) -> UserOut:
    try:
        interests = json.loads(user.interests) if user.interests else []
    except Exception:
        interests = []
    try:
        settings = json.loads(user.settings) if user.settings else None
    except Exception:
        settings = None

    # Pass in fields by name (snake_case) or alias (CamelModel handles both if populate_by_name=True)
    # Since UserOut fields are snake_case (display_name), we can pass display_name=...
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

@router.get("/search", response_model=List[UserOut])
def search_users(
    q: str = Query(..., min_length=1, description="Search query"),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db)
):
    """Search users by username or display name with pagination"""
    search_pattern = f"%{q}%"
    
    users = (
        db.query(models.User)
        .filter(
            (models.User.username.ilike(search_pattern)) |
            (models.User.display_name.ilike(search_pattern))
        )
        .offset(offset)
        .limit(limit)
        .all()
    )
    
    return [user_to_out(user) for user in users]


@router.get("/{uid}", response_model=UserOut)
def get_user(uid: str, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user_to_out(user)

@router.put("/{uid}", response_model=UserOut)
def update_user(uid: str, payload: UserUpdate, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Payload fields are snake_case in struct (display_name), but input was CamelCase (displayName)
    if payload.display_name is not None:
        user.display_name = payload.display_name
    if payload.profile_image_url is not None:
        user.profile_image_url = payload.profile_image_url
    if payload.bio is not None:
        user.bio = payload.bio
    if payload.interests is not None:
        user.interests = json.dumps(payload.interests)
    if payload.settings is not None:
        user.settings = json.dumps(payload.settings)

    db.add(user)
    db.commit()
    db.refresh(user)

    return user_to_out(user)