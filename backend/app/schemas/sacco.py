from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from uuid import UUID

class SaccoBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    registration_number: str = Field(..., min_length=2, max_length=50)
    contact_email: Optional[EmailStr] = None
    contact_phone: Optional[str] = Field(None, min_length=10, max_length=15)

class SaccoCreate(SaccoBase):
    pass

class SaccoResponse(SaccoBase):
    id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class SaccoUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    contact_email: Optional[EmailStr] = None
    contact_phone: Optional[str] = Field(None, min_length=10, max_length=15)
    is_active: Optional[bool] = None
