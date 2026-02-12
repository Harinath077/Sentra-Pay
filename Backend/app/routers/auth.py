"""
Authentication API endpoints for signup and login.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import logging

from app.models.auth import SignupRequest, LoginRequest, AuthResponse
from app.services.auth_service import create_user, authenticate_user, generate_auth_response
from app.database.connection import get_db

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/signup", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def signup(request: SignupRequest, db: Session = Depends(get_db)):
    """
    Register a new user account.
    
    Args:
        request: Signup request with email, password, full_name, phone
        db: Database session
    
    Returns:
        AuthResponse with user data and JWT token
    
    Raises:
        400: If email or phone already exists
        422: If validation fails
        500: If server error occurs
    """
    logger.info(f"Signup request for email: {request.email}")
    
    # Create new user
    user = create_user(db, request)
    
    # Generate auth response with token
    auth_response = generate_auth_response(user)
    
    logger.info(f"User signup successful: {user.user_id}")
    return auth_response


@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate user and return JWT token.
    
    Args:
        request: Login request with email and password
        db: Database session
    
    Returns:
        AuthResponse with user data and JWT token
    
    Raises:
        401: If credentials are invalid
        422: If validation fails
    """
    logger.info(f"Login request for email: {request.email}")
    
    # Authenticate user
    user = authenticate_user(db, request)
    
    # Generate auth response with token
    auth_response = generate_auth_response(user)
    
    logger.info(f"User login successful: {user.user_id}")
    return auth_response


@router.get("/health")
async def health_check():
    """
    Health check endpoint for authentication service.
    
    Returns:
        Status message
    """
    return {"status": "ok", "service": "authentication"}
#     pass
