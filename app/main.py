from fastapi import FastAPI
from app.core.config import settings
from app.api import auth, routes, vehicles, emergency, trips, users, drivers
from app.api.routes import router as routes_router

# DEBUG - Show which database we're connecting to
print("=" * 60)
print(f"DATABASE_URL: {settings.database_url}")
print(f"Using Render DATABASE_URL: {settings.DATABASE_URL is not None}")
print(f"Using Local DB Components: {settings.DATABASE_URL is None}")
print("=" * 60)

app = FastAPI(title=settings.PROJECT_NAME)

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://safarisalama.netlify.app",
        "http://localhost:3000",
        "http://192.168.*.*:3000",  # Allow any local network IP
        "http://10.*.*.*:3000",     # Allow common local network ranges
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(routes.router)
app.include_router(routes_router)
app.include_router(vehicles.router)
app.include_router(emergency.router)
app.include_router(trips.router)
app.include_router(drivers.router)

@app.get("/")
def root():
    return {"message": "Safari Salama API", "status": "running"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "database": "connected"}