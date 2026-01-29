from app.db.database import engine, Base
from app.models.user import User

# Import all models here as you create them

print("Creating tables...")
Base.metadata.create_all(bind=engine)
print("Tables created successfully!")