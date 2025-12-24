from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from .database import get_db
from .models import User, Follow
from .auth import get_current_user

router = APIRouter(prefix="/follows", tags=["follows"])


@router.post("/{target_uid}")
def follow_user(target_uid: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    target = db.query(User).filter(User.uid == target_uid).first()
    if not target:
        raise HTTPException(status_code=404, detail="Target user not found")
    if target.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")

    existing = db.query(Follow).filter(Follow.follower_id == current_user.id, Follow.followed_id == target.id).first()
    if existing:
        return {"status": "already_following"}

    follow = Follow(follower_id=current_user.id, followed_id=target.id)
    db.add(follow)
    # update counters
    current_user.following_count = (current_user.following_count or 0) + 1
    target.followers_count = (target.followers_count or 0) + 1
    db.commit()
    return {"status": "followed"}


@router.delete("/{target_uid}")
def unfollow_user(target_uid: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    target = db.query(User).filter(User.uid == target_uid).first()
    if not target:
        raise HTTPException(status_code=404, detail="Target user not found")
    if target.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot unfollow yourself")

    existing = db.query(Follow).filter(Follow.follower_id == current_user.id, Follow.followed_id == target.id).first()
    if not existing:
        return {"status": "not_following"}

    db.delete(existing)
    # update counters
    current_user.following_count = max((current_user.following_count or 0) - 1, 0)
    target.followers_count = max((target.followers_count or 0) - 1, 0)
    db.commit()
    return {"status": "unfollowed"}


@router.get("/is_following/{target_uid}")
def is_following(target_uid: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    target = db.query(User).filter(User.uid == target_uid).first()
    if not target:
        raise HTTPException(status_code=404, detail="Target user not found")
    existing = db.query(Follow).filter(Follow.follower_id == current_user.id, Follow.followed_id == target.id).first()
    return {"isFollowing": existing is not None}


@router.get("/{uid}/followers")
def get_followers(uid: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    rows = db.query(Follow).filter(Follow.followed_id == user.id).all()
    follower_uids = []
    for row in rows:
        follower = db.query(User).filter(User.id == row.follower_id).first()
        if follower:
            follower_uids.append(follower.uid)
    return {"followers": follower_uids}


@router.get("/{uid}/following")
def get_following(uid: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    rows = db.query(Follow).filter(Follow.follower_id == user.id).all()
    following_uids = []
    for row in rows:
        followed = db.query(User).filter(User.id == row.followed_id).first()
        if followed:
            following_uids.append(followed.uid)
    return {"following": following_uids}


@router.get("/{uid}/counts")
def get_counts(uid: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    followers = db.query(Follow).filter(Follow.followed_id == user.id).count()
    following = db.query(Follow).filter(Follow.follower_id == user.id).count()
    return {"followers": followers, "following": following}


@router.get("/suggested")
def get_suggested_users(
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Build exclusion set: self + already-followed users
    followed_rows = db.query(Follow).filter(Follow.follower_id == current_user.id).all()
    exclude_ids = {current_user.id}
    exclude_ids.update(row.followed_id for row in followed_rows)

    # Query top users not followed by current user, ordered by popularity
    query = (
        db.query(User)
        .filter(~User.id.in_(exclude_ids))
        .order_by(User.followers_count.desc(), User.created_at.desc())
        .limit(limit)
    )
    users = query.all()
    return {"suggested": [u.uid for u in users]}