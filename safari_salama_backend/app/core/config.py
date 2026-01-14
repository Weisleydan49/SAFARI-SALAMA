from pydantic_settings import BaseSettings
from pathlib import Path
from urllib.parse import quote_plus
from typing import Optional

BASE_DIR = Path(__file__).resolve().parent.parent.parent

class Settings(BaseSettings):
    # Option 1: Render provides this directly (production)
    DATABASE_URL: Optional[str] = None
<<<<<<< HEAD

=======
    
>>>>>>> c452060976ca1659cd3eeb2c4f263a4e3ddbf61c
    # Option 2: Build from components (local development)
    DB_USER: Optional[str] = None
    DB_PASSWORD: Optional[str] = None
    DB_HOST: Optional[str] = None
    DB_PORT: Optional[str] = None
    DB_NAME: Optional[str] = None
<<<<<<< HEAD

    SECRET_KEY: str
    PROJECT_NAME: str = "Safari Salama API"

=======
    
    SECRET_KEY: str
    PROJECT_NAME: str = "Safari Salama API"
    
>>>>>>> c452060976ca1659cd3eeb2c4f263a4e3ddbf61c
    @property
    def database_url(self) -> str:
        """
        Returns DATABASE_URL if provided (Render/production).
        Otherwise builds it from components (local development).
        """
        # If DATABASE_URL exists, use it (Render)
        if self.DATABASE_URL:
            return self.DATABASE_URL
<<<<<<< HEAD

=======
        
>>>>>>> c452060976ca1659cd3eeb2c4f263a4e3ddbf61c
        # Otherwise build from components (local)
        if not all([self.DB_USER, self.DB_PASSWORD, self.DB_HOST, self.DB_PORT, self.DB_NAME]):
            raise ValueError(
                "Either DATABASE_URL or all DB_* variables must be set. "
                "Check your .env file."
            )
<<<<<<< HEAD

=======
        
>>>>>>> c452060976ca1659cd3eeb2c4f263a4e3ddbf61c
        encoded_password = quote_plus(self.DB_PASSWORD)
        return f"postgresql://{self.DB_USER}:{encoded_password}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"

    class Config:
        env_file = BASE_DIR / ".env"

settings = Settings()
