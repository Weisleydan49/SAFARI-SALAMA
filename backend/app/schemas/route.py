from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from uuid import UUID
from decimal import Decimal


class StopResponse(BaseModel):
    id: UUID
    name: str

    class Config:
        orm_mode = True


class RouteStopResponse(BaseModel):
    sequence: int
    stop: StopResponse

    class Config:
        orm_mode = True


class RouteBase(BaseModel):
    name: str
    route_number: Optional[str] = None
    origin: str
    destination: str
    description: Optional[str] = None
    estimated_duration_minutes: Optional[int] = None
    distance_km: Optional[Decimal] = None
    fare_amount: Optional[Decimal] = None


class RouteCreate(RouteBase):
    stops: Optional[List[str]] = None


class RouteResponse(RouteBase):
    id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime
    stops: List[RouteStopResponse] = []

    class Config:
        orm_mode = True

