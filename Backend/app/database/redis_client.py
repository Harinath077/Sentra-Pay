"""
Redis client for caching user profiles, receiver reputation, and session data.
Provides high-performance caching with TTL support.
"""

import redis
import json
import logging
from typing import Optional, Any, Dict
from app.config import settings

logger = logging.getLogger(__name__)


class RedisClient:
    """Redis client wrapper with caching utilities."""
    
    def __init__(self):
        """Initialize Redis connection."""
        try:
            self.client = redis.from_url(
                settings.REDIS_URL,
                decode_responses=True,
                socket_connect_timeout=2,
                socket_timeout=2,
            )
            # Test connection
            self.client.ping()
            self.is_available = True
            logger.info("✓ Redis connection established successfully")
        except Exception as e:
            logger.warning(f"⚠ Real Redis not available: {e}")
            try:
                # Fallback to FakeRedis (In-Memory)
                import fakeredis
                self.client = fakeredis.FakeRedis(decode_responses=True)
                self.is_available = True
                logger.info("✓ Using FakeRedis (In-Memory) fallback - Caching Enabled")
            except ImportError:
                logger.warning("  System will run without caching (slower performance)")
                self.client = None
                self.is_available = False
    
    def get(self, key: str) -> Optional[Any]:
        """
        Get value from Redis.
        
        Args:
            key: Cache key
        
        Returns:
            Cached value or None if not found
        """
        if not self.client:
            return None
        
        try:
            value = self.client.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            logger.error(f"Redis GET error for key {key}: {e}")
            return None
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """
        Set value in Redis with optional TTL.
        
        Args:
            key: Cache key
            value: Value to cache (will be JSON serialized)
            ttl: Time to live in seconds (optional)
        
        Returns:
            True if successful, False otherwise
        """
        if not self.client:
            return False
        
        try:
            serialized_value = json.dumps(value)
            if ttl:
                self.client.setex(key, ttl, serialized_value)
            else:
                self.client.set(key, serialized_value)
            return True
        except Exception as e:
            logger.error(f"Redis SET error for key {key}: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """
        Delete key from Redis.
        
        Args:
            key: Cache key to delete
        
        Returns:
            True if successful, False otherwise
        """
        if not self.client:
            return False
        
        try:
            self.client.delete(key)
            return True
        except Exception as e:
            logger.error(f"Redis DELETE error for key {key}: {e}")
            return False
    
    def exists(self, key: str) -> bool:
        """
        Check if key exists in Redis.
        
        Args:
            key: Cache key
        
        Returns:
            True if key exists, False otherwise
        """
        if not self.client:
            return False
        
        try:
            return self.client.exists(key) > 0
        except Exception as e:
            logger.error(f"Redis EXISTS error for key {key}: {e}")
            return False
    
    def get_user_profile(self, user_id: str) -> Optional[Dict]:
        """
        Get cached user profile.
        
        Args:
            user_id: User ID
        
        Returns:
            User profile dict or None
        """
        key = f"user:{user_id}"
        return self.get(key)
    
    def set_user_profile(self, user_id: str, profile: Dict) -> bool:
        """
        Cache user profile.
        
        Args:
            user_id: User ID
            profile: User profile dict
        
        Returns:
            True if successful
        """
        key = f"user:{user_id}"
        ttl = settings.REDIS_TTL_USER_PROFILE
        return self.set(key, profile, ttl)
    
    def invalidate_user_profile(self, user_id: str) -> bool:
        """
        Invalidate cached user profile.
        
        Args:
            user_id: User ID
        
        Returns:
            True if successful
        """
        key = f"user:{user_id}"
        return self.delete(key)
    
    def get_receiver_reputation(self, receiver: str) -> Optional[Dict]:
        """
        Get cached receiver reputation.
        
        Args:
            receiver: Receiver UPI ID
        
        Returns:
            Receiver reputation dict or None
        """
        key = f"receiver:{receiver}"
        return self.get(key)
    
    def set_receiver_reputation(self, receiver: str, reputation: Dict) -> bool:
        """
        Cache receiver reputation.
        
        Args:
            receiver: Receiver UPI ID
            reputation: Reputation dict
        
        Returns:
            True if successful
        """
        key = f"receiver:{receiver}"
        ttl = settings.REDIS_TTL_RECEIVER_REPUTATION
        return self.set(key, reputation, ttl)
    
    def ping(self) -> bool:
        """
        Test Redis connection.
        
        Returns:
            True if connection is alive
        """
        if not self.client:
            return False
        
        try:
            return self.client.ping()
        except Exception as e:
            logger.error(f"Redis PING error: {e}")
            return False
    
    def flushdb(self):
        """Flush all keys in current database (use with caution!)."""
        if not self.client:
            return
        
        try:
            self.client.flushdb()
            logger.warning("Redis database flushed")
        except Exception as e:
            logger.error(f"Redis FLUSHDB error: {e}")
    
    def get_stats(self) -> Dict:
        """
        Get Redis statistics.
        
        Returns:
            Dict with Redis info
        """
        if not self.client:
            return {}
        
        try:
            info = self.client.info()
            return {
                "connected_clients": info.get("connected_clients", 0),
                "used_memory": info.get("used_memory_human", "0"),
                "total_commands_processed": info.get("total_commands_processed", 0),
                "keyspace_hits": info.get("keyspace_hits", 0),
                "keyspace_misses": info.get("keyspace_misses", 0),
                "hit_rate": self._calculate_hit_rate(info),
            }
        except Exception as e:
            logger.error(f"Redis INFO error: {e}")
            return {}
    
    def _calculate_hit_rate(self, info: Dict) -> float:
        """Calculate cache hit rate."""
        hits = info.get("keyspace_hits", 0)
        misses = info.get("keyspace_misses", 0)
        total = hits + misses
        
        if total == 0:
            return 0.0
        
        return round((hits / total) * 100, 2)


# Global Redis client instance
redis_client = RedisClient()


def test_redis_connection() -> bool:
    """
    Test Redis connection.
    
    Returns:
        True if connection successful
    """
    return redis_client.ping()
