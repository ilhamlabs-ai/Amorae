from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import List


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Firebase
    google_application_credentials: str = ""
    firebase_credentials_path: str = ""  # Alternative field name
    firebase_project_id: str = ""
    firebase_database_id: str = "amorae"  # Database name
    
    # OpenAI
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    openai_vision_model: str = "gpt-4o"
    
    # Database
    database_url: str = "postgresql+asyncpg://localhost:5432/amorae"
    
    # Redis
    redis_url: str = "redis://localhost:6379"
    
    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    backend_host: str = "0.0.0.0"  # Alternative field name
    backend_port: int = 8000  # Alternative field name
    debug: bool = False
    environment: str = "development"  # development, staging, production
    
    # Security
    allowed_origins: str = "http://localhost:3000"
    
    # Rate Limiting
    rate_limit_requests_per_minute: int = 60
    rate_limit_messages_per_day: int = 100
    
    @property
    def cors_origins(self) -> List[str]:
        return [origin.strip() for origin in self.allowed_origins.split(",")]
    
    @property
    def credentials_path(self) -> str:
        """Return the correct credentials path from either field."""
        return self.firebase_credentials_path or self.google_application_credentials
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False
        extra = "allow"  # Allow extra fields without validation errors


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
