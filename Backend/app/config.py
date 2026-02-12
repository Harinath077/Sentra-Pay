"""
Configuration module for Fraud Detection Backend.
Loads environment variables and provides application settings.
"""

from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Database Configuration
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 10
    
    # Redis Configuration
    REDIS_URL: str
    REDIS_TTL_USER_PROFILE: int = 300  # 5 minutes
    REDIS_TTL_RECEIVER_REPUTATION: int = 600  # 10 minutes
    
    # JWT Configuration
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    
    # Application Configuration
    APP_NAME: str = "Fraud Detection Backend"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"
    
    # CORS Configuration
    CORS_ORIGINS: List[str] = ["*"]
    
    # ML Model Configuration
    ML_MODEL_PATH: str = "app/ml/fraud_model.cbm"
    ML_MODEL_VERSION: str = "v1.1"
    
    # Rate Limiting
    RATE_LIMIT_PAYMENTS: int = 10
    RATE_LIMIT_WINDOW: int = 60  # seconds
    
    # Performance Targets
    API_RESPONSE_TIMEOUT: int = 200  # milliseconds
    ML_INFERENCE_TIMEOUT: int = 50   # milliseconds
    
    # Trust Score Configuration
    TRUST_SCORE_SUCCESSFUL_TXN: int = 1
    TRUST_SCORE_FRAUD_REPORTED: int = -10
    TRUST_SCORE_HIGH_RISK: int = -2
    TRUST_SCORE_OTP_FAILED: int = -1
    TRUST_SCORE_KYC_VERIFIED: int = 5
    
    # Risk Thresholds
    RISK_THRESHOLD_LOW: float = 0.30
    RISK_THRESHOLD_MODERATE: float = 0.60
    RISK_THRESHOLD_HIGH: float = 0.80
    
    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "logs/app.log"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Global settings instance
settings = Settings()


# Utility functions
def get_database_url() -> str:
    """Get database URL for SQLAlchemy."""
    return settings.DATABASE_URL


def get_redis_url() -> str:
    """Get Redis URL."""
    return settings.REDIS_URL


def is_production() -> bool:
    """Check if running in production environment."""
    return settings.ENVIRONMENT.lower() == "production"


def get_cors_origins() -> List[str]:
    """Get CORS origins."""
    if isinstance(settings.CORS_ORIGINS, str):
        return [origin.strip() for origin in settings.CORS_ORIGINS.split(",")]
    return settings.CORS_ORIGINS
