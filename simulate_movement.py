# simulate_movement.py
import asyncio
import random
from sqlalchemy.orm import Session
from app.db import SessionLocal
from app.models import Vehicle

async def simulate_vehicle_movement():
    """Simulate random vehicle movement around Nairobi"""
    
    while True:
        db = SessionLocal()
        try:
            # Get all active vehicles
            vehicles = db.query(Vehicle).filter(Vehicle.is_active == True).all()
            
            for vehicle in vehicles:
                if vehicle.current_latitude and vehicle.current_longitude:
                    # Move vehicle slightly (about 100-200 meters)
                    # 0.001 degrees ≈ 111 meters
                    lat_change = random.uniform(-0.002, 0.002)
                    lon_change = random.uniform(-0.002, 0.002)
                    
                    vehicle.current_latitude = float(vehicle.current_latitude) + lat_change
                    vehicle.current_longitude = float(vehicle.current_longitude) + lon_change
                    
                    # Randomly toggle online status (10% chance)
                    if random.random() < 0.1:
                        vehicle.is_online = not vehicle.is_online
            
            db.commit()
            print(f"✓ Updated {len(vehicles)} vehicles")
            
        except Exception as e:
            print(f"Error: {e}")
            db.rollback()
        finally:
            db.close()
        
        # Wait 3 seconds before next update
        await asyncio.sleep(3)

if __name__ == "__main__":
    print("Starting vehicle movement simulator...")
    asyncio.run(simulate_vehicle_movement())