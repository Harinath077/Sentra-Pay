"""
FastAPI Main Application
Entry point for Risk Orchestration Engine - Fraud Detection Backend
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import logging
import time

from app.config import settings
from app.database.connection import test_db_connection, engine
from app.database.redis_client import redis_client
from app.database import models
from app.routers import auth, payment, receiver
from app.core.ml_engine import load_model

# Configure logging
logging.basicConfig(
    level=logging.INFO if settings.DEBUG else logging.WARNING,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup and shutdown events.
    
    Startup:
    - Test database connection
    - Test Redis connection
    - Load ML model
    - Create database tables
    
    Shutdown:
    - Close database connections
    - Close Redis connections
    """
    # ──────────────────────────────────────────────
    # STARTUP
    # ──────────────────────────────────────────────
    logger.info("=" * 60)
    logger.info("🚀 Starting Fraud Detection Backend")
    logger.info("=" * 60)
    
    # Test database connection
    logger.info("📊 Testing database connection...")
    if test_db_connection():
        logger.info("✓ Database connection successful")
    else:
        logger.error("✗ Database connection failed")
    
    # Create database tables
    logger.info("📊 Creating database tables...")
    try:
        models.Base.metadata.create_all(bind=engine)
        logger.info("✓ Database tables created/verified")
    except Exception as e:
        logger.error(f"✗ Failed to create tables: {e}")
    
    # Test Redis connection
    logger.info("🔴 Testing Redis connection...")
    try:
        redis_client.ping()
        logger.info("✓ Redis connection successful")
    except Exception as e:
        logger.warning(f"⚠ Redis connection failed: {e}")
        logger.warning("  System will continue without caching")
    
    # Load ML model
    logger.info("🧠 Loading ML model...")
    try:
        load_model()
        logger.info("✓ ML model loaded successfully")
    except Exception as e:
        logger.warning(f"⚠ ML model loading failed: {e}")
        logger.warning("  System will use fallback predictions")
    
    logger.info("=" * 60)
    logger.info(f"✓ {settings.APP_NAME} v{settings.APP_VERSION} started")
    logger.info(f"  Environment: {settings.ENVIRONMENT}")
    logger.info(f"  Debug mode: {settings.DEBUG}")
    logger.info(f"  API timeout target: {settings.API_RESPONSE_TIMEOUT}ms")
    logger.info("=" * 60)
    
    yield
    
    # ──────────────────────────────────────────────
    # SHUTDOWN
    # ──────────────────────────────────────────────
    logger.info("🛑 Shutting down Fraud Detection Backend")
    logger.info("✓ Cleanup complete")


# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Risk Orchestration Engine for Fraud Detection - Combines Rules + ML + Context",
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None
)


# ──────────────────────────────────────────────
# MIDDLEWARE
# ──────────────────────────────────────────────

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Request timing middleware
@app.middleware("http")
async def log_request_time(request: Request, call_next):
    """Log request processing time for performance monitoring."""
    start_time = time.time()
    response = await call_next(request)
    process_time = (time.time() - start_time) * 1000  # Convert to milliseconds
    
    # Add processing time header
    response.headers["X-Process-Time"] = f"{process_time:.2f}ms"
    
    # Log slow requests
    if process_time > settings.API_RESPONSE_TIMEOUT:
        logger.warning(
            f"⚠ Slow request: {request.method} {request.url.path} "
            f"took {process_time:.2f}ms (target: {settings.API_RESPONSE_TIMEOUT}ms)"
        )
    else:
        logger.debug(
            f"✓ {request.method} {request.url.path} - {process_time:.2f}ms"
        )
    
    return response


# Exception handling middleware
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler for unhandled errors."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "detail": str(exc) if settings.DEBUG else "An unexpected error occurred",
            "path": str(request.url)
        }
    )


# ──────────────────────────────────────────────
# ROUTERS
# ──────────────────────────────────────────────

app.include_router(auth.router)
app.include_router(payment.router)
app.include_router(receiver.router)

# TODO: Add user and transaction routers when implemented
# app.include_router(user.router)
# app.include_router(transaction.router)


# ──────────────────────────────────────────────
# ROOT ENDPOINTS
# ──────────────────────────────────────────────

@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "environment": settings.ENVIRONMENT,
        "docs": "/docs" if settings.DEBUG else "disabled",
        "endpoints": {
            "authentication": "/api/auth",
            "payment": "/api/payment",
            "health": "/health"
        }
    }


@app.get("/health")
async def health_check():
    """
    Comprehensive health check endpoint.
    
    Checks:
    - Database connectivity
    - Redis connectivity
    - ML model availability
    
    Returns:
        Health status with component details
    """
    health_status = {
        "status": "healthy",
        "timestamp": time.time(),
        "components": {}
    }
    
    # Check database
    try:
        db_healthy = test_db_connection()
        health_status["components"]["database"] = {
            "status": "healthy" if db_healthy else "unhealthy",
            "message": "Connected" if db_healthy else "Connection failed"
        }
    except Exception as e:
        health_status["components"]["database"] = {
            "status": "unhealthy",
            "message": str(e)
        }
        health_status["status"] = "degraded"
    
    # Check Redis
    try:
        redis_client.ping()
        health_status["components"]["redis"] = {
            "status": "healthy",
            "message": "Connected"
        }
    except Exception as e:
        health_status["components"]["redis"] = {
            "status": "unhealthy",
            "message": str(e)
        }
        health_status["status"] = "degraded"
    
    # Check ML model
    from app.core.ml_engine import model_available
    health_status["components"]["ml_model"] = {
        "status": "healthy" if model_available else "degraded",
        "message": "Model loaded" if model_available else "Using fallback predictions"
    }
    
    return health_status


@app.get("/metrics")
async def metrics():
    """
    Basic metrics endpoint for monitoring.
    
    Returns:
        System metrics including cache performance
    """
    try:
        cache_stats = redis_client.get_cache_stats()
    except:
        cache_stats = {"error": "Redis unavailable"}
    
    return {
        "app": {
            "name": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "environment": settings.ENVIRONMENT
        },
        "performance": {
            "target_response_time_ms": settings.API_RESPONSE_TIMEOUT,
            "target_ml_inference_ms": settings.ML_INFERENCE_TIMEOUT
        },
        "cache": cache_stats
    }


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info" if settings.DEBUG else "warning"
    )
