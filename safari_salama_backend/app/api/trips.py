from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from app.db.database import get_db
from app.models.trip import Trip
from app.schemas.trip import TripStart, TripEnd, TripResponse

router = APIRouter(prefix="/api/trips", tags=["Trips"])

@router.post("/start", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
def start_trip(
    trip_data: TripStart,
    user_id: str,  # In production, this would come from JWT token
    db: Session = Depends(get_db)
):
    """
    Start a new trip
    NOTE: In production, user_id should come from authenticated JWT token
    For now, pass it as a query parameter for testing
    """
    # Check if user has an active trip
    active_trip = db.query(Trip).filter(
        Trip.user_id == user_id,
        Trip.trip_status == "ongoing"
    ).first()
    
    if active_trip:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already have an active trip. Please end it before starting a new one."
        )
    
    # Create new trip
    new_trip = Trip(
        user_id=user_id,
        vehicle_id=trip_data.vehicle_id,
        route_id=trip_data.route_id,
        start_latitude=trip_data.start_latitude,
        start_longitude=trip_data.start_longitude,
        fare_amount=trip_data.fare_amount,
        start_time=datetime.utcnow(),
        trip_status="ongoing"
    )
    
    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)
    
    return new_trip

@router.patch("/{trip_id}/end", response_model=TripResponse)
def end_trip(
    trip_id: str,
    trip_end: TripEnd,
    db: Session = Depends(get_db)
):
    """End an ongoing trip"""
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    if trip.trip_status != "ongoing":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Trip is not ongoing"
        )
    
    # Update trip with end details
    trip.end_latitude = trip_end.end_latitude
    trip.end_longitude = trip_end.end_longitude
    trip.end_time = datetime.utcnow()
    trip.trip_status = "completed"
    
    # Calculate duration in minutes
    if trip.start_time and trip.end_time:
        duration = trip.end_time - trip.start_time
        trip.duration_minutes = int(duration.total_seconds() / 60)
    
    db.commit()
    db.refresh(trip)
    
    return trip

@router.get("", response_model=List[TripResponse])
def get_trips(
    user_id: str = None,
    status: str = None,
    db: Session = Depends(get_db)
):
    """Get all trips with optional filters"""
    query = db.query(Trip)
    
    if user_id:
        query = query.filter(Trip.user_id == user_id)
    
    if status:
        query = query.filter(Trip.trip_status == status)
    
    trips = query.order_by(Trip.start_time.desc()).all()
    return trips

@router.get("/{trip_id}", response_model=TripResponse)
def get_trip(trip_id: str, db: Session = Depends(get_db)):
    """Get a specific trip by ID"""
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    return trip

@router.get("/user/{user_id}/active", response_model=TripResponse)
def get_active_trip(user_id: str, db: Session = Depends(get_db)):
    """Get user's active trip if any"""
    active_trip = db.query(Trip).filter(
        Trip.user_id == user_id,
        Trip.trip_status == "ongoing"
    ).first()
    
    if not active_trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active trip found"
        )
    
    return active_trip

@router.get("/user/{user_id}/history", response_model=List[TripResponse])
def get_trip_history(user_id: str, skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    """
    Get user's trip history (completed trips only)
    Paginated: skip and limit parameters for pagination
    """
    try:
        from uuid import UUID
        user_uuid = UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format"
        )
    
    # Fetch completed trips for the user, ordered by most recent first
    trips = db.query(Trip).filter(
        Trip.user_id == user_uuid,
        Trip.trip_status == "completed"
    ).order_by(
        Trip.end_time.desc()
    ).offset(skip).limit(limit).all()
    
    return trips


@router.post("/{trip_id}/sync-locations", response_model=TripResponse)
def sync_trip_locations(
    trip_id: str,
    locations_data: dict,
    db: Session = Depends(get_db)
):
    """
    Sync queued location updates from offline trip
    Accepts batch location updates and processes them
    """
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    # Get locations from request
    locations = locations_data.get('locations', [])
    
    if not locations:
        return trip
    
    # Process offline locations
    # In production, you would:
    # 1. Store locations in a TripLocation table for analytics
    # 2. Recalculate trip distance based on all locations
    # 3. Update trip statistics
    
    total_distance = 0.0
    for i in range(len(locations) - 1):
        loc1 = locations[i]
        loc2 = locations[i + 1]
        
        # Calculate distance between consecutive points
        from math import radians, cos, sin, asin, sqrt
        
        lat1 = radians(float(loc1.get('latitude', 0)))
        lon1 = radians(float(loc1.get('longitude', 0)))
        lat2 = radians(float(loc2.get('latitude', 0)))
        lon2 = radians(float(loc2.get('longitude', 0)))
        
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * asin(sqrt(a))
        r = 6371  # Radius of earth in kilometers
        distance_km = c * r
        
        total_distance += distance_km
    
    # Update trip with synced distance if currently ongoing
    if trip.trip_status == "ongoing" and trip.distance_km:
        trip.distance_km = trip.distance_km + total_distance
    
    db.commit()
    db.refresh(trip)
    
    return trip