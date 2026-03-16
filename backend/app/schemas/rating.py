from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID

class RatingCreate(BaseModel):
    trip_id: UUID
    driver_id: UUID
    score: int = Field(..., ge=1, le=5, description="Rating score from 1 to 5")
    feedback: Optional[str] = Field(None, max_length=500)

class RatingResponse(BaseModel):
    id: UUID
    trip_id: UUID
    passenger_id: UUID
    driver_id: UUID
    score: int
    feedback: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
