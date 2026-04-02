from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from uuid import UUID
from app.db.database import get_db
from app.models.sacco import Sacco
from app.models.vehicle import Vehicle
from app.models.user import User
from app.models.trip import Trip
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta

router = APIRouter(prefix="/api/admin", tags=["Admin/Sacco"])


class SaccoCreate(BaseModel):
    name: str
    registration_number: str
    phone: str
    email: Optional[str] = None
    address: Optional[str] = None


class SaccoUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None


class SaccoResponse(BaseModel):
    id: str
    name: str
    registration_number: str
    phone: str
    email: Optional[str]
    address: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


@router.post("/saccos", response_model=SaccoResponse, status_code=status.HTTP_201_CREATED)
def create_sacco(
    sacco_data: SaccoCreate,
    db: Session = Depends(get_db)
):
    """Create a new Sacco (admin only)"""
    
    # Check if registration number already exists
    existing = db.query(Sacco).filter(
        Sacco.registration_number == sacco_data.registration_number
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Sacco with this registration number already exists"
        )
    
    sacco = Sacco(
        name=sacco_data.name,
        registration_number=sacco_data.registration_number,
        phone=sacco_data.phone,
        email=sacco_data.email,
        address=sacco_data.address
    )
    
    db.add(sacco)
    db.commit()
    db.refresh(sacco)
    
    return {
        "id": str(sacco.id),
        "name": sacco.name,
        "registration_number": sacco.registration_number,
        "phone": sacco.phone,
        "email": sacco.email,
        "address": sacco.address,
        "created_at": sacco.created_at
    }


@router.get("/saccos")
def list_saccos(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db)
):
    """List all Saccos"""
    
    saccos = db.query(Sacco).offset(skip).limit(limit).all()
    total = db.query(func.count(Sacco.id)).scalar()
    
    return {
        "total": total,
        "skip": skip,
        "limit": limit,
        "saccos": [
            {
                "id": str(s.id),
                "name": s.name,
                "registration_number": s.registration_number,
                "phone": s.phone,
                "email": s.email,
                "address": s.address,
                "created_at": s.created_at
            }
            for s in saccos
        ]
    }


@router.get("/saccos/{sacco_id}", response_model=SaccoResponse)
def get_sacco(
    sacco_id: str,
    db: Session = Depends(get_db)
):
    """Get Sacco details"""
    
    try:
        sacco_uuid = UUID(sacco_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sacco ID format"
        )
    
    sacco = db.query(Sacco).filter(Sacco.id == sacco_uuid).first()
    
    if not sacco:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sacco not found"
        )
    
    return {
        "id": str(sacco.id),
        "name": sacco.name,
        "registration_number": sacco.registration_number,
        "phone": sacco.phone,
        "email": sacco.email,
        "address": sacco.address,
        "created_at": sacco.created_at
    }


@router.patch("/saccos/{sacco_id}", response_model=SaccoResponse)
def update_sacco(
    sacco_id: str,
    sacco_update: SaccoUpdate,
    db: Session = Depends(get_db)
):
    """Update Sacco details"""
    
    try:
        sacco_uuid = UUID(sacco_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sacco ID format"
        )
    
    sacco = db.query(Sacco).filter(Sacco.id == sacco_uuid).first()
    
    if not sacco:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sacco not found"
        )
    
    if sacco_update.name:
        sacco.name = sacco_update.name
    if sacco_update.phone:
        sacco.phone = sacco_update.phone
    if sacco_update.email:
        sacco.email = sacco_update.email
    if sacco_update.address:
        sacco.address = sacco_update.address
    
    db.commit()
    db.refresh(sacco)
    
    return {
        "id": str(sacco.id),
        "name": sacco.name,
        "registration_number": sacco.registration_number,
        "phone": sacco.phone,
        "email": sacco.email,
        "address": sacco.address,
        "created_at": sacco.created_at
    }


@router.get("/saccos/{sacco_id}/vehicles")
def get_sacco_vehicles(
    sacco_id: str,
    db: Session = Depends(get_db)
):
    """Get all vehicles for a Sacco"""
    
    try:
        sacco_uuid = UUID(sacco_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sacco ID format"
        )
    
    vehicles = db.query(Vehicle).filter(
        Vehicle.sacco_id == sacco_uuid
    ).all()
    
    return {
        "sacco_id": sacco_id,
        "total_vehicles": len(vehicles),
        "vehicles": [
            {
                "id": str(v.id),
                "registration_number": v.registration_number,
                "vehicle_type": v.vehicle_type,
                "capacity": v.capacity,
                "is_online": v.is_online,
                "is_active": v.is_active
            }
            for v in vehicles
        ]
    }


@router.get("/saccos/{sacco_id}/drivers")
def get_sacco_drivers(
    sacco_id: str,
    db: Session = Depends(get_db)
):
    """Get all drivers for a Sacco"""
    
    try:
        sacco_uuid = UUID(sacco_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sacco ID format"
        )
    
    # Get drivers (users with user_type='driver' who drive vehicles belonging to this sacco)
    drivers = db.query(User).join(
        Vehicle, Vehicle.driver_id == User.id
    ).filter(
        Vehicle.sacco_id == sacco_uuid,
        User.user_type == 'driver'
    ).distinct().all()
    
    return {
        "sacco_id": sacco_id,
        "total_drivers": len(drivers),
        "drivers": [
            {
                "id": str(d.id),
                "name": d.name,
                "phone": d.phone,
                "email": d.email,
                "is_active": d.is_active
            }
            for d in drivers
        ]
    }


@router.get("/saccos/{sacco_id}/analytics")
def get_sacco_analytics(
    sacco_id: str,
    days: int = 30,
    db: Session = Depends(get_db)
):
    """Get Sacco analytics for a period"""
    
    try:
        sacco_uuid = UUID(sacco_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid sacco ID format"
        )
    
    # Get vehicles for this sacco
    vehicles = db.query(Vehicle.id).filter(
        Vehicle.sacco_id == sacco_uuid
    ).all()
    
    vehicle_ids = [v.id for v in vehicles]
    
    if not vehicle_ids:
        return {
            "sacco_id": sacco_id,
            "period_days": days,
            "total_trips": 0,
            "total_earnings": 0.0,
            "average_trip_value": 0.0
        }
    
    # Get trips for these vehicles in the period
    start_date = datetime.utcnow() - timedelta(days=days)
    
    trips = db.query(Trip).filter(
        Trip.vehicle_id.in_(vehicle_ids),
        Trip.trip_status == "completed",
        Trip.end_time >= start_date
    ).all()
    
    total_earnings = sum(float(trip.fare_amount or 0) for trip in trips)
    
    return {
        "sacco_id": sacco_id,
        "period_days": days,
        "total_trips": len(trips),
        "total_earnings": total_earnings,
        "average_trip_value": total_earnings / len(trips) if trips else 0.0,
        "total_vehicles": len(vehicle_ids)
    }


@router.post("/users/{user_id}/set-role")
def set_user_role(
    user_id: str,
    role: str,
    db: Session = Depends(get_db)
):
    """Set user role (admin only)"""
    
    try:
        user_uuid = UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format"
        )
    
    valid_roles = ["passenger", "driver", "admin", "sacco_admin"]
    if role not in valid_roles:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid role. Must be one of: {valid_roles}"
        )
    
    user = db.query(User).filter(User.id == user_uuid).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.user_type = role
    db.commit()
    db.refresh(user)
    
    return {
        "id": str(user.id),
        "name": user.name,
        "user_type": user.user_type
    }
