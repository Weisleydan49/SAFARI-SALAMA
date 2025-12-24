from sqlalchemy import Column, String, Integer, Boolean, DateTime, Numeric, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.database import Base

class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(UUID(as_uuid= True), primary_key = True, default = uuid.uuid4)
    registration_number = Column(String(20), unique = True, nullable = False, index = True)
    sacco_id = Column(UUID(as_uuid = True), ForeignKey('saccos.id'))
    route_id = Column(UUID(as_uuid = True), ForeignKey('routes.id'))
    capacity = Column(Integer, default = 14)
    vehicle_type = Column(String(50), default = 'minibus')
    make = Column(String(50))
    model = Column(String(50))
    year_of_manufacture = Column(Integer)
    current_latitude = Column(Numeric(10, 8))
    current_longitude = Column(Numeric(11, 8))
    last_location_update = Column(DateTime)
    is_active = Column(Boolean, default = True, server_default = 'true')
    is_online = Column(Boolean, default = False, server_default = 'false')
    created_at = Column(DateTime, default = datetime.utcnow, server_default = 'now()')
    updated_at = Column(DateTime, default = datetime.utcnow, onupdate = datetime.utcnow, server_default = 'now()')
