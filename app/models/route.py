from sqlalchemy import Column, String, Integer, Numeric, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.database import Base
from sqlalchemy.orm import relationship

class Route(Base):
    __tablename__ = "routes"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    route_number = Column(String(20))
    origin = Column(String(200), nullable=False)
    destination = Column(String(200), nullable=False)
    description = Column(String)
    estimated_duration_minutes = Column(Integer)
    distance_km = Column(Numeric(10, 2))
    fare_amount = Column(Numeric(10, 2))
    is_active = Column(Boolean, default=True, server_default='true')
    created_at = Column(DateTime, default=datetime.utcnow, server_default='now()')
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default='now()')

    route_stops = relationship(
        "RouteStop",
        cascade="all, delete-orphan",
        passive_deletes=True,
        order_by="RouteStop.sequence",
    )