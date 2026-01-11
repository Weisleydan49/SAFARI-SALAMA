from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID
from decimal import Decimal
from enum import Enum

class PaymentStatus(str, Enum):
    pending = "pending"
    completed = "completed"
    failed = "failed"
    refunded = "refunded"

class TripStatus(str, Enum):
    scheduled = "scheduled"
    ongoing = "ongoing"
    completed = "completed"
    cancelled = "cancelled"

class TripStart(BaseModel):
    vehicle_id: Optional[UUID] = None
    route_id: Optional[UUID] = None
    start_latitude: Decimal = Field(..., description="Starting latitude")
    start_longitude: Decimal = Field(..., description="Starting longitude")
    fare_amount: Optional[Decimal] = None

class TripEnd(BaseModel):
    end_latitude: Decimal = Field(..., description="Ending latitude")
    end_longitude: Decimal = Field(..., description="Ending longitude")

class TripResponse(BaseModel):
    id: UUID
    user_id: UUID
    vehicle_id: UUID
    driver_id: Optional[UUID]
    route_id: Optional[UUID]
    start_latitude: Optional[Decimal]
    start_longitude: Optional[Decimal]
    end_latitude: Optional[Decimal]
    end_longitude: Optional[Decimal]
    start_time: datetime
    end_time: Optional[datetime]
    duration_minutes: Optional[int]
    distance_km: Optional[Decimal]
    fare_amount: Optional[Decimal]
    payment_status: PaymentStatus
    trip_status: TripStatus
    created_at: datetime
    
    class Config:
        from_attributes = True