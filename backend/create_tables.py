from app.db.database import engine, Base
from app.models import User, Route, Vehicle, Trip, EmergencyAlert, Sacco, Rating, GpsPoint

# Import all models here as you create them

print("Creating tables...")
Base.metadata.create_all(bind=engine)
print("Tables created successfully!")