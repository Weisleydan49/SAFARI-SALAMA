from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.database import Base

class Sacco(Base):
    __tablename__ = "saccos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    registration_number = Column(String(50), unique=True, nullable=False)
    contact_email = Column(String(255))
    contact_phone = Column(String(15))
    is_active = Column(Boolean, default=True, server_default='true')
    created_at = Column(DateTime, default=datetime.utcnow, server_default='now()')
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default='now()')
