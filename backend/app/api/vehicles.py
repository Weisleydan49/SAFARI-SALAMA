from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from app.db.database import get_db
from app.models.vehicle import Vehicle
from app.schemas.vehicle import VehicleResponse, VehicleCreate, VehicleLocationUpdate

router = APIRouter(prefix="/api/vehicles", tags=["Vehicles"])

@router.get("/location", response_model=List[VehicleResponse])
def get_vehicle_locations(
    route_id: Optional[str] = Query(None, description="Filter by route ID"),
    is_online: Optional[bool] = Query(None, description="Filter by online status"),
    db: Session = Depends(get_db)
):
    """Get all vehicle locations with optional filters"""
    query = db.query(Vehicle).filter(Vehicle.is_active == True)
    
    if route_id:
        query = query.filter(Vehicle.route_id == route_id)
    
    if is_online is not None:
        query = query.filter(Vehicle.is_online == is_online)
    
    vehicles = query.all()
    return vehicles

@router.get("/{vehicle_id}", response_model=VehicleResponse)
def get_vehicle(vehicle_id: str, db: Session = Depends(get_db)):
    """Get a specific vehicle by ID"""
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found"
        )
    return vehicle

@router.post("", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
def create_vehicle(vehicle_data: VehicleCreate, db: Session = Depends(get_db)):
    """Create a new vehicle (admin only for now)"""
    # Check if registration number already exists
    existing = db.query(Vehicle).filter(
        Vehicle.registration_number == vehicle_data.registration_number
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vehicle with this registration number already exists"
        )
    
    new_vehicle = Vehicle(**vehicle_data.model_dump())
    db.add(new_vehicle)
    db.commit()
    db.refresh(new_vehicle)
    return new_vehicle

@router.patch("/{vehicle_id}/location", response_model=VehicleResponse)
def update_vehicle_location(
    vehicle_id: str,
    location_data: VehicleLocationUpdate,
    db: Session = Depends(get_db)
):
    """Update vehicle location (for GPS tracking)"""
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found"
        )
    
    vehicle.current_latitude = location_data.current_latitude
    vehicle.current_longitude = location_data.current_longitude
    vehicle.last_location_update = datetime.utcnow()
    vehicle.is_online = True
    
    db.commit()
    db.refresh(vehicle)
    return vehicle