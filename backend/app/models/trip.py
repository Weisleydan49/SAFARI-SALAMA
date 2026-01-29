from sqlalchemy import Column, Integer, String, DateTime, Numeric, ForeignKey, Enum
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.database import Base
import enum

class PaymentStatus(str, enum.Enum):
    pending = "pending"
    completed = "completed"
    failed = "failed"
    refunded = "refunded"

class TripStatus(str, enum.Enum):
    scheduled = "scheduled"
    ongoing = "ongoing"
    completed = "completed"
    cancelled = "cancelled"

class Trip(Base):
    __tablename__ = "trips"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    vehicle_id = Column(UUID(as_uuid=True), ForeignKey("vehicles.id"), nullable=False)
    driver_id = Column(UUID(as_uuid=True), ForeignKey("drivers.id"))
    route_id = Column(UUID(as_uuid=True), ForeignKey("routes.id"))
    start_latitude = Column(Numeric(10, 8))
    start_longitude = Column(Numeric(11, 8))
    end_latitude = Column(Numeric(10, 8))
    end_longitude = Column(Numeric(11, 8))
    start_time = Column(DateTime, nullable = False, default=datetime.utcnow)
    end_time = Column(DateTime)
    duration_minutes = Column(Integer)
    distance_km = Column(Numeric(10, 2))
    fare_amount = Column(Numeric(10, 2))
    payment_status = Column(Enum(PaymentStatus), default=PaymentStatus.pending)
    trip_status = Column(Enum(TripStatus), default=TripStatus.ongoing)
    created_at = Column(DateTime, default=datetime.utcnow, server_default = 'now()')
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default = 'now()')
