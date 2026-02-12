"""
Test script for Phase 1: Foundation Setup
Tests configuration, database connection, and Redis connection.
"""

import sys
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def test_configuration():
    """Test configuration loading."""
    try:
        from app.config import settings
        logger.info("✓ Configuration loaded successfully")
        logger.info(f"  - App Name: {settings.APP_NAME}")
        logger.info(f"  - Environment: {settings.ENVIRONMENT}")
        logger.info(f"  - Debug Mode: {settings.DEBUG}")
        return True
    except Exception as e:
        logger.error(f"✗ Configuration failed: {e}")
        return False


def test_database_connection():
    """Test database connection."""
    try:
        from app.database.connection import test_db_connection
        
        if test_db_connection():
            logger.info("✓ Database connection successful")
            return True
        else:
            logger.error("✗ Database connection failed")
            return False
    except Exception as e:
        logger.error(f"✗ Database connection error: {e}")
        logger.info("  Make sure PostgreSQL is running:")
        logger.info("  docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:14")
        return False


def test_redis_connection():
    """Test Redis connection."""
    try:
        from app.database.redis_client import test_redis_connection
        
        if test_redis_connection():
            logger.info("✓ Redis connection successful")
            return True
        else:
            logger.error("✗ Redis connection failed")
            return False
    except Exception as e:
        logger.error(f"✗ Redis connection error: {e}")
        logger.info("  Make sure Redis is running:")
        logger.info("  docker run -d -p 6379:6379 redis:7")
        return False


def test_redis_operations():
    """Test basic Redis operations."""
    try:
        from app.database.redis_client import redis_client
        
        # Test SET
        test_key = "test:key"
        test_value = {"message": "Hello, Redis!"}
        redis_client.set(test_key, test_value, ttl=60)
        
        # Test GET
        retrieved = redis_client.get(test_key)
        
        if retrieved == test_value:
            logger.info("✓ Redis SET/GET operations working")
            
            # Test DELETE
            redis_client.delete(test_key)
            logger.info("✓ Redis DELETE operation working")
            return True
        else:
            logger.error("✗ Redis GET returned incorrect value")
            return False
            
    except Exception as e:
        logger.error(f"✗ Redis operations error: {e}")
        return False


def main():
    """Run all Phase 1 tests."""
    logger.info("=" * 60)
    logger.info("PHASE 1: Foundation Setup Tests")
    logger.info("=" * 60)
    
    results = {
        "Configuration": test_configuration(),
        "Database Connection": test_database_connection(),
        "Redis Connection": test_redis_connection(),
        "Redis Operations": test_redis_operations(),
    }
    
    logger.info("\n" + "=" * 60)
    logger.info("TEST RESULTS")
    logger.info("=" * 60)
    
    for test_name, passed in results.items():
        status = "✓ PASS" if passed else "✗ FAIL"
        logger.info(f"{test_name}: {status}")
    
    all_passed = all(results.values())
    
    logger.info("=" * 60)
    if all_passed:
        logger.info("✓ ALL TESTS PASSED - Phase 1 Complete!")
        logger.info("\nNext Steps:")
        logger.info("1. Review docs/PIPELINE.md")
        logger.info("2. Proceed to Phase 2: Authentication")
    else:
        logger.error("✗ SOME TESTS FAILED")
        logger.info("\nTroubleshooting:")
        logger.info("1. Make sure PostgreSQL is running on port 5432")
        logger.info("2. Make sure Redis is running on port 6379")
        logger.info("3. Check .env file for correct configuration")
    logger.info("=" * 60)
    
    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
