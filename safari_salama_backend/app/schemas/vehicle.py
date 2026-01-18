from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from uuid import UUID
from decimal import Decimal

class VehicleBase(BaseModel):
    registration_number: str
    sacco_id: Optional[UUID] = None
    route_id: Optional[UUID] = None
    capacity: int = 14
    vehicle_type: str = 'minibus'
    make: Optional[str] = None
    model: Optional[str] = None
    year_of_manufacture: Optional[int] = None

class VehicleCreate(VehicleBase):
    pass

class VehicleLocationUpdate(BaseModel):
    currenr_latitude: Decimal
    current_longitude: Decimal

class VehicleResponse(VehicleBase):
    id: UUID
    current_latitude: Optional[Decimal]
    current_longitude: Optional[Decimal]
    last_location_update: Optional[datetime]
    is_active: bool
    is_online: bool
    created_at: datetime

class Config:
    from_attributes = True
