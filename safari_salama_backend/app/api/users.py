from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID
from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdate
from app.core.security import get_current_user

router = APIRouter(prefix="/api/users", tags=["Users"])

@router.get("/{user_id}", response_model=UserResponse)
def get_user_profile(
    user_id: str,
    db: Session = Depends(get_db)
):
    """
    Get user profile by ID
    """
    try:
        uuid_id = UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format"
        )
    
    user = db.query(User).filter(User.id == uuid_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return user

@router.patch("/{user_id}/profile", response_model=UserResponse)
def update_user_profile(
    user_id: str,
    user_update: UserUpdate,
    db: Session = Depends(get_db)
):
    """
    Update user profile (name, email, profile photo)
    """
    try:
        uuid_id = UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format"
        )
    
    user = db.query(User).filter(User.id == uuid_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check if email is already taken by another user
    if user_update.email and user_update.email != user.email:
        existing_email = db.query(User).filter(
            User.email == user_update.email,
            User.id != uuid_id
        ).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already in use"
            )
    
    # Update only provided fields
    if user_update.name:
        user.name = user_update.name
    if user_update.email:
        user.email = user_update.email
    if user_update.profile_photo_url:
        user.profile_photo_url = user_update.profile_photo_url
    
    db.commit()
    db.refresh(user)
    
    return user

@router.get("/{user_id}/profile-summary", response_model=UserResponse)
def get_user_summary(
    user_id: str,
    db: Session = Depends(get_db)
):
    """
    Get user profile summary with limited information
    """
    try:
        uuid_id = UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format"
        )
    
    user = db.query(User).filter(User.id == uuid_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return user
