
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime
from enum import Enum
from uuid import UUID

class UserType(str, Enum):
    passenger = "passenger"
    driver = "driver"
    admin = "admin"
    sacco_admin = "sacco_admin"

class UserRegister(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15)
    name: str = Field(..., min_length=2, max_length=100)
    email: Optional[EmailStr] = None
    password: str = Field(..., min_length=6, max_length=72)
    user_type: UserType = UserType.passenger

class UserLogin(BaseModel):
    phone: str
    password: str

class UserResponse(BaseModel):
    id: UUID
    phone: str
    name: str
    email: Optional[str]
    user_type: UserType
    is_verified: bool
    is_active: bool
    created_at: datetime
    
    @field_validator('id', mode='before')
    def convert_uuid_to_str(cls, v):
        if isinstance(v, UUID):
            return str(v)
        return v
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    email: Optional[EmailStr] = None
    profile_photo_url: Optional[str] = None
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse