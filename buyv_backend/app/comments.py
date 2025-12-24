from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from .database import get_db
from .models import User, Post, Comment
from .auth import get_current_user
from .schemas import CommentCreate, CommentOut

router = APIRouter(prefix="/comments", tags=["comments"])


def _map_comment_out(comment: Comment, user: User, post_uid: str) -> CommentOut:
    """Map Comment model to CommentOut schema"""
    return CommentOut(
        id=comment.id,
        user_id=user.uid,
        username=user.username,
        display_name=user.display_name,
        user_profile_image=user.profile_image_url,
        post_id=post_uid,
        content=comment.content,
        created_at=comment.created_at,
        updated_at=comment.updated_at,
    )


@router.post("/{post_uid}", response_model=CommentOut)
def add_comment(
    post_uid: str,
    payload: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Add a comment to a post"""
    # Find the post
    post = db.query(Post).filter(Post.uid == post_uid).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    # Create the comment
    comment = Comment(
        user_id=current_user.id,
        post_id=post.id,
        content=payload.content,
    )
    db.add(comment)
    
    # Increment the post's comments count
    post.comments_count = (post.comments_count or 0) + 1
    
    db.commit()
    db.refresh(comment)
    
    return _map_comment_out(comment, current_user, post_uid)


@router.get("/{post_uid}", response_model=List[CommentOut])
def get_comments(
    post_uid: str,
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    """Fetch comments for a post with pagination"""
    # Find the post
    post = db.query(Post).filter(Post.uid == post_uid).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    # Fetch comments with pagination, ordered by newest first
    comments = (
        db.query(Comment)
        .filter(Comment.post_id == post.id)
        .order_by(Comment.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    
    if not comments:
        return []
    
    # Fetch all users who created these comments
    user_ids = list({c.user_id for c in comments})
    users = db.query(User).filter(User.id.in_(user_ids)).all()
    user_map = {u.id: u for u in users}
    
    # Map comments to output schema
    result = []
    for comment in comments:
        user = user_map.get(comment.user_id)
        if user:
            result.append(_map_comment_out(comment, user, post_uid))
    
    return result
