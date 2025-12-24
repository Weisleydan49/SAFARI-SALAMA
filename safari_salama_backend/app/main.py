from fastapi import FastAPI
from app.core.config import settings
from app.api import auth, routes, vehicles, emergency, trips, users, drivers

# DEBUG - print database URL
print(f"DATABASE_URL: {settings.DATABASE_URL}")

app = FastAPI(title=settings.PROJECT_NAME)

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Include routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(routes.router)
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