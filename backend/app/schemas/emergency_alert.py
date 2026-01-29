from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID
from decimal import Decimal
from enum import Enum

class AlertType(str, Enum):
    general = "general"
    accident = "accident"
    harassment = "harassment"
    theft = "theft"
    medical = "medical"

class AlertStatus(str, Enum):
    active = "active"
    acknowledged = "acknowledged"
    resolved = "resolved"
    false_alarm = "false_alarm"

class EmergencyAlertCreate(BaseModel):
    trip_id: Optional[UUID] = None
    vehicle_id: Optional[UUID] = None
    alert_type: AlertType = AlertType.general
    latitude: Decimal = Field(..., description="Current latitude")
    longitude: Decimal = Field(..., description="Current longitude")
    description: Optional[str] = None

class EmergencyAlertResponse(BaseModel):
    id: UUID
    user_id: UUID
    trip_id: Optional[UUID]
    vehicle_id: Optional[UUID]
    alert_type: AlertType
    latitude: Decimal
    longitude: Decimal
    description: Optional[str]
    status: AlertStatus
    acknowledged_by: Optional[UUID]
    acknowledged_at: Optional[datetime]
    resolved_at: Optional[datetime]
    created_at: datetime
    
    class Config:
        from_attributes = True

class EmergencyAlertUpdate(BaseModel):
    status: AlertStatus
    resolution_notes: Optional[str] = None