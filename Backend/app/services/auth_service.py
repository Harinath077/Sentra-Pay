"""
Authentication service for user signup, login, and token management.
"""

from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from datetime import timedelta
import logging

from app.database.models import User
from app.utils.security import hash_password, verify_password, create_access_token
from app.models.auth import SignupRequest, LoginRequest, AuthResponse
from app.config import settings
from app.database.redis_client import redis_client

logger = logging.getLogger(__name__)


def create_user(db: Session, signup_data: SignupRequest) -> User:
    """
    Create a new user account.
    
    Args:
        db: Database session
        signup_data: Signup request data
    
    Returns:
        Created User object
    
    Raises:
        HTTPException: If email already exists
    """
    # Check if user already exists
    existing_user = db.query(User).filter(User.email == signup_data.email).first()
    if existing_user:
        logger.warning(f"Signup attempt with existing email: {signup_data.email}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Check if phone already exists (if provided)
    if signup_data.phone:
        existing_phone = db.query(User).filter(User.phone == signup_data.phone).first()
        if existing_phone:
            logger.warning(f"Signup attempt with existing phone: {signup_data.phone}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Phone number already registered"
            )
    
    # Hash password
    hashed_password = hash_password(signup_data.password)
    
    # Create new user
    new_user = User(
        email=signup_data.email,
        phone=signup_data.phone,
        password_hash=hashed_password,
        full_name=signup_data.full_name,
        trust_score=0.0,
        risk_tier="BRONZE",
        known_devices=[]
    )
    
    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        logger.info(f"New user created: {new_user.user_id} - {new_user.email}")
        return new_user
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating user: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error creating user account"
        )


def authenticate_user(db: Session, login_data: LoginRequest) -> User:
    """
    Authenticate a user with email and password.
    
    Args:
        db: Database session
        login_data: Login request data
    
    Returns:
        User object if authentication successful
    
    Raises:
        HTTPException: If credentials are invalid
    """
    # Fetch user by email
    user = db.query(User).filter(User.email == login_data.email).first()
    
    if not user:
        logger.warning(f"Login attempt with non-existent email: {login_data.email}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify password
    if not verify_password(login_data.password, user.password_hash):
        logger.warning(f"Failed login attempt for user: {user.user_id}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Update last login
    from datetime import datetime
    user.last_login = datetime.utcnow()
    db.commit()
    
    logger.info(f"User authenticated: {user.user_id} - {user.email}")
    return user


async def authenticate_google_user(db: Session, id_token_str: str) -> User:
    """
    Authenticate a user using Google OAuth2 ID Token.
    
    Args:
        db: Database session
        id_token_str: Google ID Token from frontend
        
    Returns:
        User object
    """
    from google.oauth2 import id_token
    from google.auth.transport import requests
    import uuid
    from datetime import datetime
    
    try:
        # Verify the ID token
        id_info = id_token.verify_oauth2_token(
            id_token_str, 
            requests.Request(), 
            settings.GOOGLE_CLIENT_ID
        )
        
        # Extract user info
        email = id_info['email']
        name = id_info.get('name', email.split('@')[0])
        google_id = id_info['sub']
        
        # Check if user exists by google_id
        user = db.query(User).filter(User.google_id == google_id).first()
        
        if not user:
            # Check if user exists by email (Link if already exists)
            user = db.query(User).filter(User.email == email).first()
            
            if user:
                # Link existing email account to Google
                user.google_id = google_id
                user.login_method = "google"
                user.is_verified = True
                user.auth_provider = "google"
            else:
                # Create new Google user
                user = User(
                    email=email,
                    full_name=name,
                    google_id=google_id,
                    login_method="google",
                    is_verified=True,
                    auth_provider="google",
                    trust_score=0.0,
                    risk_tier="BRONZE",
                    known_devices=[]
                )
                db.add(user)
        
        user.last_login = datetime.utcnow()
        db.commit()
        db.refresh(user)
        
        logger.info(f"Google user authenticated: {user.user_id} - {user.email}")
        return user
        
    except ValueError as e:
        logger.error(f"Invalid Google ID Token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google ID Token"
        )
    except Exception as e:
        logger.error(f"Google authentication error: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Google authentication failed"
        )
    

def generate_auth_response(user: User) -> AuthResponse:
    """
    Generate authentication response with user data and JWT token.
    
    Args:
        user: User object
    
    Returns:
        AuthResponse with token and user data
    """
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.user_id, "email": user.email},
        expires_delta=access_token_expires
    )
    
    # Cache user profile in Redis
    user_profile = {
        "user_id": user.user_id,
        "email": user.email,
        "full_name": user.full_name,
        "trust_score": user.trust_score,
        "risk_tier": user.risk_tier,
        "known_devices": user.known_devices or []
    }
    redis_client.set_user_profile(user.user_id, user_profile)
    
    return AuthResponse(
        user_id=user.user_id,
        email=user.email,
        full_name=user.full_name,
        trust_score=user.trust_score,
        risk_tier=user.risk_tier,
        token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )


def get_current_user(db: Session, token: str) -> User:
    """
    Get current user from JWT token.
    
    Args:
        db: Database session
        token: JWT token string
    
    Returns:
        User object
    
    Raises:
        HTTPException: If token is invalid or user not found
    """
    from app.utils.security import verify_token
    
    # Verify token
    payload = verify_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id: str = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Get user from database
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return user

# TODO: def create_access_token(user_id: str) -> str:
#     """Generate JWT token"""
#     # Create JWT with expiration
#     pass
