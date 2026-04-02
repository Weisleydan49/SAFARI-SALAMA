from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID
from decimal import Decimal
from enum import Enum


class PaymentMethod(str, Enum):
    mpesa = "mpesa"
    credit_card = "credit_card"
    cash = "cash"
    wallet = "wallet"


class PaymentStatus(str, Enum):
    pending = "pending"
    processing = "processing"
    completed = "completed"
    failed = "failed"
    refunded = "refunded"


class PaymentCreate(BaseModel):
    trip_id: UUID
    amount: Decimal = Field(..., gt=0, description="Payment amount")
    payment_method: PaymentMethod = PaymentMethod.mpesa
    phone_number: Optional[str] = None  # For Mpesa


class PaymentMpesaCallback(BaseModel):
    transaction_id: str
    status: str  # "success" or "failed"
    amount: Decimal
    reference: str


class PaymentResponse(BaseModel):
    id: UUID
    trip_id: UUID
    user_id: UUID
    driver_id: Optional[UUID]
    amount: Decimal
    payment_method: PaymentMethod
    payment_status: PaymentStatus
    reference_number: Optional[str]
    mpesa_transaction_id: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
