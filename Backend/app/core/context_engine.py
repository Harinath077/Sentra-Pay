"""
CONTEXT ENGINE - User Behavior Analysis
Retrieves user context from cache/database for risk analysis.
"""

from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import logging

from app.database.models import User, Transaction, ReceiverReputation
from app.database.redis_client import redis_client
from app.database.connection import SessionLocal

logger = logging.getLogger(__name__)


class UserContext:
    """User context data structure."""
    def __init__(self, user_profile: dict, txn_stats: dict, receiver_info: Optional[dict] = None):
        self.user_profile = user_profile
        self.txn_stats = txn_stats
        self.receiver_info = receiver_info or {}


def get_user_context(user_id: str, receiver: Optional[str] = None, db: Optional[Session] = None) -> UserContext:
    """
    Get comprehensive user context for risk analysis.
    
    Strategy:
    1. Try Redis cache for user profile
    2. Fallback to PostgreSQL if cache miss
    3. Calculate transaction statistics
    4. Get receiver reputation if provided
    
    Args:
        user_id: User identifier
        receiver: Receiver UPI/identifier (optional)
        db: Database session (creates new if not provided)
    
    Returns:
        UserContext object with profile, stats, and receiver info
    """
    close_db = False
    if not db:
        db = SessionLocal()
        close_db = True
    
    try:
        # Try cache first
        cached_profile = redis_client.get_user_profile(user_id)
        
        if cached_profile:
            logger.debug(f"Cache HIT for user: {user_id}")
            user_profile = cached_profile
        else:
            logger.debug(f"Cache MISS for user: {user_id}")
            user = db.query(User).filter(User.user_id == user_id).first()
            
            if not user:
                logger.error(f"User not found: {user_id}")
                raise ValueError(f"User not found: {user_id}")
            
            user_profile = {
                "user_id": user.user_id,
                "email": user.email,
                "full_name": user.full_name,
                "trust_score": user.trust_score,
                "risk_tier": user.risk_tier,
                "known_devices": user.known_devices or [],
                "created_at": user.created_at.isoformat() if user.created_at else None
            }
            
            # Cache for 5 minutes
            redis_client.set_user_profile(user_id, user_profile)
        
        # Calculate transaction statistics
        txn_stats = calculate_user_stats(user_id, db)
        
        # Get receiver reputation if provided
        receiver_info = None
        if receiver:
            receiver_info = get_receiver_reputation(receiver, db)
        
        return UserContext(
            user_profile=user_profile,
            txn_stats=txn_stats,
            receiver_info=receiver_info
        )
    
    finally:
        if close_db:
            db.close()


def calculate_user_stats(user_id: str, db: Session) -> Dict:
    """
    Calculate user transaction statistics for risk analysis.
    
    Computes:
    - Average amount (30 days)
    - Max amount (30 days)
    - Transaction count (30 days, 1 hour, 5 minutes)
    - Days since last transaction
    - Failed transaction count (7 days)
    - User tenure in days
    
    Args:
        user_id: User identifier
        db: Database session
    
    Returns:
        Dictionary with transaction statistics
    """
    # Get internal User ID (int) from public User ID (str)
    user_orm = db.query(User).filter(User.user_id == user_id).first()
    if not user_orm:
        return {
            "avg_amount_30d": 0.0,
            "max_amount_30d": 0.0,
            "txn_count_30d": 0,
            "txn_count_1hour": 0,
            "txn_count_5min": 0,
            "failed_txn_count_7d": 0,
            "days_since_last_txn": 999,
            "user_tenure_days": 0
        }
    
    internal_user_id = user_orm.id

    now = datetime.utcnow()
    thirty_days_ago = now - timedelta(days=30)
    seven_days_ago = now - timedelta(days=7)
    one_hour_ago = now - timedelta(hours=1)
    five_min_ago = now - timedelta(minutes=5)
    
    # 30-day statistics
    txns_30d = db.query(Transaction).filter(
        Transaction.user_id == internal_user_id,
        Transaction.created_at >= thirty_days_ago,
        Transaction.status == "COMPLETED"
    ).all()
    
    avg_amount_30d = 0.0
    max_amount_30d = 0.0
    txn_count_30d = len(txns_30d)
    
    if txns_30d:
        amounts = [float(txn.amount) for txn in txns_30d]
        avg_amount_30d = sum(amounts) / len(amounts)
        max_amount_30d = max(amounts)
    
    # Velocity calculations
    txn_count_1hour = db.query(Transaction).filter(
        Transaction.user_id == internal_user_id,
        Transaction.created_at >= one_hour_ago
    ).count()
    
    txn_count_5min = db.query(Transaction).filter(
        Transaction.user_id == internal_user_id,
        Transaction.created_at >= five_min_ago
    ).count()
    
    # Failed transactions (7 days)
    failed_txn_count_7d = db.query(Transaction).filter(
        Transaction.user_id == internal_user_id,
        Transaction.created_at >= seven_days_ago,
        Transaction.status == "FAILED"
    ).count()
    
    # Days since last transaction
    last_txn = db.query(Transaction).filter(
        Transaction.user_id == internal_user_id
    ).order_by(desc(Transaction.created_at)).first()
    
    days_since_last_txn = 999  # Default for new users
    if last_txn:
        days_since_last_txn = (now - last_txn.created_at).days
    
    # User tenure
    user_tenure_days = 0
    if user_orm.created_at:
        user_tenure_days = (now - user_orm.created_at).days
    
    return {
        "avg_amount_30d": avg_amount_30d,
        "max_amount_30d": max_amount_30d,
        "txn_count_30d": txn_count_30d,
        "txn_count_1hour": txn_count_1hour,
        "txn_count_5min": txn_count_5min,
        "failed_txn_count_7d": failed_txn_count_7d,
        "days_since_last_txn": days_since_last_txn,
        "user_tenure_days": user_tenure_days
    }


def get_receiver_reputation(receiver: str, db: Session) -> Dict:
    """
    Get receiver reputation metrics.
    
    Checks:
    - Total transactions received
    - Fraud transaction count
    - Fraud ratio
    - Reputation score (0.0 - 1.0, lower is better)
    
    Args:
        receiver: Receiver UPI/identifier
        db: Database session
    
    Returns:
        Dictionary with receiver reputation metrics
    """
    # Try cache first
    cached_reputation = redis_client.get(f"receiver_reputation:{receiver}")
    if cached_reputation:
        logger.debug(f"Cache HIT for receiver reputation: {receiver}")
        return cached_reputation
    
    # Query database
    reputation = db.query(ReceiverReputation).filter(
        ReceiverReputation.receiver == receiver
    ).first()
    
    if reputation:
        reputation_data = {
            "receiver": receiver,
            "total_transactions": reputation.total_transactions,
            "fraud_count": reputation.fraud_count,
            "fraud_ratio": reputation.fraud_count / max(reputation.total_transactions, 1),
            "reputation_score": min(reputation.fraud_count / max(reputation.total_transactions, 1), 1.0),
            "last_updated": reputation.last_updated.isoformat() if reputation.last_updated else None
        }
    else:
        # New receiver - neutral reputation
        reputation_data = {
            "receiver": receiver,
            "total_transactions": 0,
            "fraud_count": 0,
            "fraud_ratio": 0.0,
            "reputation_score": 0.5,  # Neutral for unknown receivers
            "is_new": True
        }
    
    # Cache for 10 minutes
    redis_client.set(f"receiver_reputation:{receiver}", reputation_data, ttl=600)
    
    return reputation_data


def check_new_receiver(user_id: str, receiver: str, db: Session) -> bool:
    """
    Check if receiver is new for this user.
    
    Args:
        user_id: User identifier
        receiver: Receiver UPI/identifier
        db: Database session
    
    Returns:
        True if receiver is new, False otherwise
    """
    existing_txn = db.query(Transaction).filter(
        Transaction.user_id == user_id,
        Transaction.receiver == receiver,
        Transaction.status == "COMPLETED"
    ).first()
    
    return existing_txn is None


def get_transaction_history(user_id: str, days: int = 30, db: Optional[Session] = None) -> List[Dict]:
    """
    Get user transaction history.
    
    Args:
        user_id: User identifier
        days: Number of days to look back
        db: Database session (creates new if not provided)
    
    Returns:
        List of transaction dictionaries
    """
    close_db = False
    if not db:
        db = SessionLocal()
        close_db = True
    
    try:
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        
        transactions = db.query(Transaction).filter(
            Transaction.user_id == user_id,
            Transaction.created_at >= cutoff_date
        ).order_by(desc(Transaction.created_at)).all()
        
        return [{
            "transaction_id": txn.transaction_id,
            "amount": txn.amount,
            "receiver": txn.receiver,
            "status": txn.status,
            "risk_score": txn.risk_score,
            "created_at": txn.created_at.isoformat() if txn.created_at else None
        } for txn in transactions]
    
    finally:
        if close_db:
            db.close()
