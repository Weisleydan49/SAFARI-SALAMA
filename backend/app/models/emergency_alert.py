from sqlalchemy import Column, String, Boolean, DateTime, Enum, ForeignKey, Numeric
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.database import Base
import enum

class AlertType(str, enum.Enum):
    general = "general"
    accident = "accident"
    harrassment = "harassment"
    theft = "theft"
    medical = "medical"

class AlertStatus(str, enum.Enum):
    active = "active"
    acknowledged = "acknowledged"
    resolved = "resolved"
    false_alarm = "false_alarm"

class EmergencyAlert(Base):
    __tablename__ = "emergency_alerts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=False)
    trip_id = Column(UUID(as_uuid = True), ForeignKey('trips.id'))
    vehicle_id = Column(UUID(as_uuid = True), ForeignKey('vehicles.id'))
    alert_type = Column(Enum(AlertType), default = AlertType.general)
    latitude = Column(Numeric(10, 8), nullable=False)
    longitude = Column(Numeric(11, 8), nullable=False)
    description = Column(String)
    status = Column(Enum(AlertStatus), default=AlertStatus.active,)
    acknowledged_by = Column(UUID(as_uuid=True), ForeignKey('users.id'))
    acknowledged_at = Column(DateTime)
    resolved_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow, server_default = 'now()')
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default = 'now()')