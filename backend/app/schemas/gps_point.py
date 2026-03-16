from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID
from decimal import Decimal

class GpsPointCreate(BaseModel):
    vehicle_id: UUID
    trip_id: Optional[UUID] = None
    latitude: Decimal = Field(..., description="Latitude")
    longitude: Decimal = Field(..., description="Longitude")
    speed_kmh: Optional[Decimal] = None
    heading: Optional[Decimal] = None
    timestamp: Optional[datetime] = None

class GpsPointResponse(BaseModel):
    id: UUID
    vehicle_id: UUID
    trip_id: Optional[UUID]
    latitude: Decimal
    longitude: Decimal
    speed_kmh: Optional[Decimal]
    heading: Optional[Decimal]
    timestamp: datetime
    created_at: datetime

    class Config:
        from_attributes = True
