from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List
from uuid import UUID
from datetime import datetime, timedelta
from app.db.database import get_db
from app.models.trip import Trip, TripStatus
from app.models.vehicle import Vehicle
from app.models.user import User
from app.schemas.trip import TripResponse

router = APIRouter(prefix="/api/drivers", tags=["Driver Dashboard"])

@router.get("/{driver_id}/dashboard")
def get_driver_dashboard(
    driver_id: str,
    db: Session = Depends(get_db)
):
    """
    Get driver dashboard with active trips, earnings, and vehicle info
    """
    try:
        driver_uuid = UUID(driver_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid driver ID format"
        )
    
    # Get driver user info
    driver = db.query(User).filter(User.id == driver_uuid).first()
    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver not found"
        )
    
    # Get active trip
    active_trip = db.query(Trip).filter(
        Trip.user_id == driver_uuid,
        Trip.trip_status == "ongoing"
    ).first()
    
    # Calculate today's earnings
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)
    
    today_trips = db.query(Trip).filter(
        Trip.user_id == driver_uuid,
        Trip.trip_status == "completed",
        Trip.end_time >= today_start,
        Trip.end_time < today_end
    ).all()
    
    today_earnings = sum(float(trip.fare_amount or 0) for trip in today_trips)
    today_trips_count = len(today_trips)
    
    # Calculate total earnings (all time)
    all_completed_trips = db.query(Trip).filter(
        Trip.user_id == driver_uuid,
        Trip.trip_status == "completed"
    ).all()
    
    total_earnings = sum(float(trip.fare_amount or 0) for trip in all_completed_trips)
    total_trips = len(all_completed_trips)
    
    # Calculate average rating (placeholder - would require rating model)
    average_rating = 4.5  # Placeholder
    
    # Get vehicle info
    vehicle = None
    if active_trip and active_trip.vehicle_id:
        vehicle = db.query(Vehicle).filter(Vehicle.id == active_trip.vehicle_id).first()
    
    return {
        "driver": {
            "id": str(driver.id),
            "name": driver.name,
            "phone": driver.phone,
            "rating": average_rating,
        },
        "active_trip": {
            "id": str(active_trip.id) if active_trip else None,
            "vehicle_id": str(active_trip.vehicle_id) if active_trip else None,
            "route_id": str(active_trip.route_id) if active_trip else None,
            "start_time": active_trip.start_time.isoformat() if active_trip else None,
            "fare_amount": float(active_trip.fare_amount or 0) if active_trip else None,
        } if active_trip else None,
        "vehicle": {
            "id": str(vehicle.id),
            "registration": vehicle.registration_number,
            "type": vehicle.vehicle_type,
            "capacity": vehicle.capacity,
        } if vehicle else None,
        "earnings": {
            "today": today_earnings,
            "today_trips": today_trips_count,
            "total": total_earnings,
            "total_trips": total_trips,
            "average_per_trip": total_earnings / total_trips if total_trips > 0 else 0,
        },
        "stats": {
            "total_trips": total_trips,
            "completed_today": today_trips_count,
            "average_rating": average_rating,
        }
    }

@router.get("/{driver_id}/active-trips", response_model=List[TripResponse])
def get_driver_active_trips(
    driver_id: str,
    db: Session = Depends(get_db)
):
    """
    Get all active trips for a driver
    """
    try:
        driver_uuid = UUID(driver_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid driver ID format"
        )
    
    active_trips = db.query(Trip).filter(
        Trip.user_id == driver_uuid,
        Trip.trip_status == "ongoing"
    ).order_by(Trip.start_time.desc()).all()
    
    return active_trips

@router.get("/{driver_id}/earnings")
def get_driver_earnings(
    driver_id: str,
    days: int = 7,
    db: Session = Depends(get_db)
):
    """
    Get driver earnings summary for the past N days
    """
    try:
        driver_uuid = UUID(driver_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid driver ID format"
        )
    
    start_date = datetime.utcnow() - timedelta(days=days)
    
    # Get completed trips for the period
    trips = db.query(Trip).filter(
        Trip.user_id == driver_uuid,
        Trip.trip_status == "completed",
        Trip.end_time >= start_date
    ).order_by(Trip.end_time.desc()).all()
    
    # Group by day
    daily_earnings = {}
    for trip in trips:
        day = trip.end_time.date()
        if day not in daily_earnings:
            daily_earnings[day] = {"amount": 0.0, "trips": 0}
        daily_earnings[day]["amount"] += float(trip.fare_amount or 0)
        daily_earnings[day]["trips"] += 1
    
    # Format response
    earnings_data = [
        {
            "date": str(day),
            "earnings": data["amount"],
            "trips": data["trips"],
            "average": data["amount"] / data["trips"] if data["trips"] > 0 else 0,
        }
        for day, data in sorted(daily_earnings.items(), reverse=True)
    ]
    
    total_earnings = sum(float(trip.fare_amount or 0) for trip in trips)
    
    return {
        "period_days": days,
        "total_earnings": total_earnings,
        "total_trips": len(trips),
        "average_per_trip": total_earnings / len(trips) if trips else 0,
        "daily_breakdown": earnings_data,
    }

@router.get("/{driver_id}/rating")
def get_driver_rating(
    driver_id: str,
    db: Session = Depends(get_db)
):
    """
    Get driver rating (placeholder - would require rating model)
    """
    try:
        driver_uuid = UUID(driver_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid driver ID format"
        )
    
    driver = db.query(User).filter(User.id == driver_uuid).first()
    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver not found"
        )
    
    # Placeholder - in production would query ratings from a Rating model
    return {
        "driver_id": str(driver.id),
        "driver_name": driver.name,
        "average_rating": 4.5,
        "total_ratings": 23,
        "rating_breakdown": {
            "5_stars": 15,
            "4_stars": 5,
            "3_stars": 2,
            "2_stars": 1,
            "1_star": 0,
        }
    }
