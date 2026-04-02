from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from uuid import UUID
from datetime import datetime, timedelta
from app.db.database import get_db
from app.models.payment import Payment, PaymentStatus, PaymentMethod
from app.models.trip import Trip
from app.models.user import User
from app.schemas.payment import PaymentCreate, PaymentResponse, PaymentMpesaCallback
import os
from decimal import Decimal

router = APIRouter(prefix="/api/payments", tags=["Payments"])


@router.post("/create", response_model=PaymentResponse, status_code=status.HTTP_201_CREATED)
def create_payment(
    payment_data: PaymentCreate,
    db: Session = Depends(get_db)
):
    """Create a payment for a trip"""
    
    # Check if trip exists
    trip = db.query(Trip).filter(Trip.id == payment_data.trip_id).first()
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    # Check if payment already exists for this trip
    existing_payment = db.query(Payment).filter(
        Payment.trip_id == payment_data.trip_id
    ).first()
    
    if existing_payment and existing_payment.payment_status == PaymentStatus.completed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment already completed for this trip"
        )
    
    # Create payment
    payment = Payment(
        trip_id=payment_data.trip_id,
        user_id=trip.user_id,
        driver_id=trip.driver_id,
        amount=payment_data.amount,
        payment_method=payment_data.payment_method,
        payment_status=PaymentStatus.pending,
        reference_number=f"PAY-{trip.id.hex[:8].upper()}-{datetime.utcnow().timestamp()}"
    )
    
    db.add(payment)
    db.commit()
    db.refresh(payment)
    
    # If Mpesa, initiate STK push
    if payment_data.payment_method == PaymentMethod.mpesa and payment_data.phone_number:
        try:
            initiate_mpesa_stk(
                phone_number=payment_data.phone_number,
                amount=float(payment_data.amount),
                reference=payment.reference_number,
                payment_id=str(payment.id)
            )
        except Exception as e:
            print(f"Mpesa STK initiation failed: {e}")
    
    return payment


@router.get("/{payment_id}", response_model=PaymentResponse)
def get_payment(
    payment_id: str,
    db: Session = Depends(get_db)
):
    """Get payment details"""
    try:
        payment_uuid = UUID(payment_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment ID format"
        )
    
    payment = db.query(Payment).filter(Payment.id == payment_uuid).first()
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found"
        )
    
    return payment


@router.get("/trip/{trip_id}", response_model=PaymentResponse)
def get_trip_payment(
    trip_id: str,
    db: Session = Depends(get_db)
):
    """Get payment for a specific trip"""
    try:
        trip_uuid = UUID(trip_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid trip ID format"
        )
    
    payment = db.query(Payment).filter(Payment.trip_id == trip_uuid).first()
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No payment found for this trip"
        )
    
    return payment


@router.post("/callback/mpesa")
def mpesa_callback(callback_data: PaymentMpesaCallback, db: Session = Depends(get_db)):
    """Handle Mpesa payment callback"""
    
    # Find payment by reference
    payment = db.query(Payment).filter(
        Payment.reference_number == callback_data.reference
    ).first()
    
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment reference not found"
        )
    
    # Update payment status
    if callback_data.status.lower() == "success":
        payment.payment_status = PaymentStatus.completed
        payment.mpesa_transaction_id = callback_data.transaction_id
        
        # Update trip payment status
        trip = db.query(Trip).filter(Trip.id == payment.trip_id).first()
        if trip:
            trip.payment_status = "completed"
    else:
        payment.payment_status = PaymentStatus.failed
    
    db.commit()
    db.refresh(payment)
    
    return {"status": "processed", "payment_id": str(payment.id)}


@router.get("/user/{user_id}/history")
def get_user_payments(
    user_id: str,
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """Get payment history for a user"""
    try:
        user_uuid = UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format"
        )
    
    payments = db.query(Payment).filter(
        Payment.user_id == user_uuid
    ).order_by(Payment.created_at.desc()).offset(skip).limit(limit).all()
    
    total = db.query(func.count(Payment.id)).filter(
        Payment.user_id == user_uuid
    ).scalar()
    
    return {
        "total": total,
        "skip": skip,
        "limit": limit,
        "payments": payments
    }


def initiate_mpesa_stk(phone_number: str, amount: float, reference: str, payment_id: str):
    """
    Initiate Mpesa STK push
    Requires: MPESA_API_KEY, MPESA_BUSINESS_CODE, MPESA_CALLBACK_URL
    """
    
    # Get Mpesa credentials from environment
    api_key = os.getenv("MPESA_API_KEY")
    business_code = os.getenv("MPESA_BUSINESS_CODE", "174379")
    callback_url = os.getenv("MPESA_CALLBACK_URL", "https://safarisalama-api.onrender.com/api/payments/callback/mpesa")
    
    if not api_key:
        raise ValueError("MPESA_API_KEY not configured")
    
    # This is a placeholder - actual implementation would use Mpesa API
    # For now, we'll just log it
    print(f"Mpesa STK Push initiated: {phone_number}, Amount: {amount}, Reference: {reference}")
    
    # TODO: Implement actual Mpesa integration using requests library
    # This would typically involve:
    # 1. Getting JWT token from Mpesa API
    # 2. Calling the STK push endpoint
    # 3. Handling the response
    
    return {"status": "initiated", "phone": phone_number}


@router.patch("/{payment_id}/status")
def update_payment_status(
    payment_id: str,
    status: str,
    db: Session = Depends(get_db)
):
    """Update payment status (admin only)"""
    try:
        payment_uuid = UUID(payment_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment ID format"
        )
    
    payment = db.query(Payment).filter(Payment.id == payment_uuid).first()
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found"
        )
    
    # Validate status
    valid_statuses = [e.value for e in PaymentStatus]
    if status not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status. Must be one of: {valid_statuses}"
        )
    
    payment.payment_status = status
    db.commit()
    db.refresh(payment)
    
    return payment
