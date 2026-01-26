from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from app.db.database import get_db
from app.models.emergency_alert import EmergencyAlert
from app.schemas.emergency_alert import EmergencyAlertCreate, EmergencyAlertResponse, EmergencyAlertUpdate
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/api/emergency", tags=["Emergency"])

@router.post("", response_model=EmergencyAlertResponse, status_code=status.HTTP_201_CREATED)
def create_emergency_alert(
    alert_data: EmergencyAlertCreate,
    user_id: str,  # In production, this would come from JWT token
    db: Session = Depends(get_db)
):
    """
    Create an emergency alert
    NOTE: In production, user_id should come from authenticated JWT token
    For now, pass it as a query parameter for testing
    """
    new_alert = EmergencyAlert(
        user_id=user_id,
        trip_id=alert_data.trip_id,
        vehicle_id=alert_data.vehicle_id,
        alert_type=alert_data.alert_type,
        latitude=alert_data.latitude,
        longitude=alert_data.longitude,
        description=alert_data.description
    )
    
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)
    
    # Trigger notifications
    try:
        NotificationService.send_emergency_alert(
            alert_id=str(new_alert.id),
            user_id=user_id,
            latitude=float(alert_data.latitude),
            longitude=float(alert_data.longitude),
            alert_type=alert_data.alert_type,
            # TODO: Fetch these from database based on user profile and location
            emergency_contacts=[],  # User's emergency contacts
            nearby_drivers=[],      # Drivers within 5km radius
            sacco_admin_id=None,    # SACCO admin for this user
        )
    except Exception as e:
        print(f"Failed to send emergency notifications: {str(e)}")
        # Don't fail the alert creation if notifications fail
    
    return new_alert

@router.get("", response_model=List[EmergencyAlertResponse])
def get_emergency_alerts(
    status: str = None,
    db: Session = Depends(get_db)
):
    """Get all emergency alerts with optional status filter"""
    query = db.query(EmergencyAlert)
    
    if status:
        query = query.filter(EmergencyAlert.status == status)
    
    alerts = query.order_by(EmergencyAlert.created_at.desc()).all()
    return alerts

@router.get("/{alert_id}", response_model=EmergencyAlertResponse)
def get_emergency_alert(alert_id: str, db: Session = Depends(get_db)):
    """Get a specific emergency alert by ID"""
    alert = db.query(EmergencyAlert).filter(EmergencyAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency alert not found"
        )
    return alert

@router.patch("/{alert_id}", response_model=EmergencyAlertResponse)
def update_emergency_alert(
    alert_id: str,
    update_data: EmergencyAlertUpdate,
    admin_user_id: str,  # In production, from JWT token
    db: Session = Depends(get_db)
):
    """Update emergency alert status (admin only)"""
    alert = db.query(EmergencyAlert).filter(EmergencyAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency alert not found"
        )
    
    alert.status = update_data.status
    
    if update_data.status == "acknowledged" and not alert.acknowledged_at:
        alert.acknowledged_by = admin_user_id
        alert.acknowledged_at = datetime.utcnow()
    
    if update_data.status == "resolved" and not alert.resolved_at:
        alert.resolved_at = datetime.utcnow()
    
    db.commit()
    db.refresh(alert)
    return alert