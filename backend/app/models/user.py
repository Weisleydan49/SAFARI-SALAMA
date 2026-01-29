from sqlalchemy import Column, String, Boolean, DateTime, Enum, true
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.database import Base
import enum

class UserType(str, enum.Enum):
    passenger = "passenger"
    driver = "driver"
    admin = "admin"
    sacco_admin = "sacco_admin"

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key = True, default = uuid.uuid4)
    phone = Column(String(15), unique = True, nullable = False, index = True)
    name = Column(String(100), nullable = False)
    email = Column(String(255), unique = True, index = True)
    password_hash = Column(String(255), nullable = False)
    user_type = Column(Enum(UserType), nullable = False)
    profile_photo_url = Column(String(500))
    is_verified = Column(Boolean, default = False, server_default = 'false')
    is_active = Column(Boolean, default = True, server_default = 'true')
    created_at = Column(DateTime, default = datetime.utcnow)
    updated_at = Column(DateTime, default = datetime.utcnow, onupdate = datetime.utcnow)
    last_login = Column(DateTime)
