from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from uuid import UUID
from datetime import datetime
from app.db.database import get_db
from app.models.rating import Rating
from app.models.trip import Trip
from app.models.user import User
from pydantic import BaseModel, Field
from typing import Optional, List

router = APIRouter(prefix="/api/ratings", tags=["Ratings"])


class RatingCreate(BaseModel):
    trip_id: str
    driver_id: str
    score: int = Field(..., ge=1, le=5, description="Rating score from 1 to 5")
    feedback: Optional[str] = Field(None, max_length=500)


class RatingResponse(BaseModel):
    id: str
    trip_id: str
    passenger_id: str
    driver_id: str
    score: int
    feedback: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


@router.post("/", response_model=RatingResponse, status_code=status.HTTP_201_CREATED)
def create_rating(
    rating_data: RatingCreate,
    passenger_id: str,
    db: Session = Depends(get_db)
):
    """Create a rating for a trip"""
    
    try:
        trip_uuid = UUID(rating_data.trip_id)
        driver_uuid = UUID(rating_data.driver_id)
        passenger_uuid = UUID(passenger_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid ID format"
        )
    
    # Check trip exists and belongs to passenger
    trip = db.query(Trip).filter(Trip.id == trip_uuid).first()
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    if trip.user_id != passenger_uuid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only rate your own trips"
        )
    
    # Check if rating already exists
    existing_rating = db.query(Rating).filter(
        Rating.trip_id == trip_uuid
    ).first()
    
    if existing_rating:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating already exists for this trip"
        )
    
    # Create rating
    rating = Rating(
        trip_id=trip_uuid,
        passenger_id=passenger_uuid,
        driver_id=driver_uuid,
        score=rating_data.score,
        feedback=rating_data.feedback
    )
    
    db.add(rating)
    db.commit()
    db.refresh(rating)
    
    return {
        "id": str(rating.id),
        "trip_id": str(rating.trip_id),
        "passenger_id": str(rating.passenger_id),
        "driver_id": str(rating.driver_id),
        "score": rating.score,
        "feedback": rating.feedback,
        "created_at": rating.created_at
    }


@router.get("/driver/{driver_id}")
def get_driver_ratings(
    driver_id: str,
    db: Session = Depends(get_db)
):
    """Get all ratings for a driver"""
    
    try:
        driver_uuid = UUID(driver_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid driver ID format"
        )
    
    ratings = db.query(Rating).filter(
        Rating.driver_id == driver_uuid
    ).order_by(Rating.created_at.desc()).all()
    
    if not ratings:
        return {
            "driver_id": driver_id,
            "average_score": 0.0,
            "total_ratings": 0,
            "ratings": []
        }
    
    total_score = sum(r.score for r in ratings)
    average_score = total_score / len(ratings)
    
    return {
        "driver_id": driver_id,
        "average_score": round(average_score, 1),
        "total_ratings": len(ratings),
        "ratings": [
            {
                "id": str(r.id),
                "trip_id": str(r.trip_id),
                "passenger_id": str(r.passenger_id),
                "score": r.score,
                "feedback": r.feedback,
                "created_at": r.created_at
            }
            for r in ratings
        ]
    }


@router.get("/trip/{trip_id}")
def get_trip_rating(
    trip_id: str,
    db: Session = Depends(get_db)
):
    """Get rating for a specific trip"""
    
    try:
        trip_uuid = UUID(trip_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid trip ID format"
        )
    
    rating = db.query(Rating).filter(Rating.trip_id == trip_uuid).first()
    
    if not rating:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No rating found for this trip"
        )
    
    return {
        "id": str(rating.id),
        "trip_id": str(rating.trip_id),
        "passenger_id": str(rating.passenger_id),
        "driver_id": str(rating.driver_id),
        "score": rating.score,
        "feedback": rating.feedback,
        "created_at": rating.created_at
    }


@router.patch("/{rating_id}")
def update_rating(
    rating_id: str,
    score: Optional[int] = None,
    feedback: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Update a rating"""
    
    try:
        rating_uuid = UUID(rating_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid rating ID format"
        )
    
    if score is not None and (score < 1 or score > 5):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Score must be between 1 and 5"
        )
    
    rating = db.query(Rating).filter(Rating.id == rating_uuid).first()
    
    if not rating:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Rating not found"
        )
    
    if score is not None:
        rating.score = score
    if feedback is not None:
        rating.feedback = feedback
    
    db.commit()
    db.refresh(rating)
    
    return {
        "id": str(rating.id),
        "trip_id": str(rating.trip_id),
        "passenger_id": str(rating.passenger_id),
        "driver_id": str(rating.driver_id),
        "score": rating.score,
        "feedback": rating.feedback,
        "created_at": rating.created_at
    }
