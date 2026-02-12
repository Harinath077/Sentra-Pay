"""
Authentication Pydantic models for request/response validation.
"""

from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional
from datetime import datetime


class SignupRequest(BaseModel):
    """Request model for user signup."""
    
    email: EmailStr
    phone: str = Field(..., min_length=10, max_length=15)
    password: str = Field(..., min_length=8, max_length=100)
    full_name: str = Field(..., min_length=2, max_length=255)
    
    @validator('password')
    def password_strength(cls, v):
        """Validate password strength."""
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least one digit')
        if not any(char.isalpha() for char in v):
            raise ValueError('Password must contain at least one letter')
        return v
    
    class Config:
        json_schema_extra = {
            "example": {
                "email": "gopal@gmail.com",
                "phone": "+919876543210",
                "password": "SecurePass123",
                "full_name": "Gopal Kumar"
            }
        }


class LoginRequest(BaseModel):
    """Request model for user login."""
    
    email: EmailStr
    password: str
    
    class Config:
        json_schema_extra = {
            "example": {
                "email": "gopal@gmail.com",
                "password": "SecurePass123"
            }
        }


class TokenResponse(BaseModel):
    """Response model for authentication tokens."""
    
    access_token: str
    token_type: str = "bearer"
    expires_in: int = 3600
    
    class Config:
        json_schema_extra = {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
                "expires_in": 3600
            }
        }


class UserResponse(BaseModel):
    """Response model for user data."""
    
    user_id: str
    email: str
    full_name: str
    phone: Optional[str] = None
    trust_score: float
    risk_tier: str
    created_at: datetime
    
    class Config:
        from_attributes = True
        json_schema_extra = {
            "example": {
                "user_id": "USER-12345",
                "email": "gopal@gmail.com",
                "full_name": "Gopal Kumar",
                "phone": "+919876543210",
                "trust_score": 0.0,
                "risk_tier": "BRONZE",
                "created_at": "2026-02-03T10:00:00Z"
            }
        }


class AuthResponse(BaseModel):
    """Complete authentication response with user data and token."""
    
    user_id: str
    email: str
    full_name: str
    trust_score: float
    risk_tier: str
    token: str
    token_type: str = "bearer"
    expires_in: int = 3600
    
    class Config:
        json_schema_extra = {
            "example": {
                "user_id": "USER-12345",
                "email": "gopal@gmail.com",
                "full_name": "Gopal Kumar",
                "trust_score": 0.0,
                "risk_tier": "BRONZE",
                "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
                "expires_in": 3600
            }
        }
