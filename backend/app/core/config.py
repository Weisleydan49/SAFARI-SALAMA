from pydantic_settings import BaseSettings
from pathlib import Path
from urllib.parse import quote_plus
from typing import Optional

BASE_DIR = Path(__file__).resolve().parent.parent.parent


class Settings(BaseSettings):
    # Option 1: Render provides this directly (production)
    DATABASE_URL: Optional[str] = None

    # Option 2: Build from components (local development)
    DB_USER: Optional[str] = None
    DB_PASSWORD: Optional[str] = None
    DB_HOST: Optional[str] = None
    DB_PORT: Optional[str] = None
    DB_NAME: Optional[str] = None

    SECRET_KEY: str
    PROJECT_NAME: str = "Safari Salama API"

    @property
    def database_url(self) -> str:
        """
        Returns DATABASE_URL if provided (Render/production).
        Otherwise builds it from components (local development).
        """
        # Render / production
        if self.DATABASE_URL:
            return self.DATABASE_URL

        # Local development
        if not all([
            self.DB_USER,
            self.DB_PASSWORD,
            self.DB_HOST,
            self.DB_PORT,
            self.DB_NAME,
        ]):
            raise ValueError(
                "Either DATABASE_URL or all DB_* variables must be set. "
                "Check your .env file."
            )

        encoded_password = quote_plus(self.DB_PASSWORD)
        return (
            f"postgresql://{self.DB_USER}:{encoded_password}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
        )

    class Config:
        env_file = BASE_DIR / ".env"
        extra = "ignore"


settings = Settings()
