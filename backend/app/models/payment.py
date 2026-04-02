from sqlalchemy import Column, String, DateTime, Numeric, ForeignKey, Enum
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from app.db.database import Base
import enum


class PaymentMethod(str, enum.Enum):
    mpesa = "mpesa"
    credit_card = "credit_card"
    cash = "cash"
    wallet = "wallet"


class PaymentStatus(str, enum.Enum):
    pending = "pending"
    processing = "processing"
    completed = "completed"
    failed = "failed"
    refunded = "refunded"


class Payment(Base):
    __tablename__ = "payments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    driver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    amount = Column(Numeric(10, 2), nullable=False)
    payment_method = Column(Enum(PaymentMethod), nullable=False, default=PaymentMethod.mpesa)
    payment_status = Column(Enum(PaymentStatus), default=PaymentStatus.pending)
    reference_number = Column(String(100), index=True)
    mpesa_transaction_id = Column(String(100), unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, server_default='now()')
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default='now()')
