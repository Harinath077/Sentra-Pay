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
        
        # Calculate transaction statistics from DB
        txn_stats = calculate_user_stats(user_id, db)

        # Augment with CSV-based history (simulation memory) if available
        try:
            from app.core.history_engine import compute_user_stats as csv_compute_stats, get_receiver_summary_for_user
            csv_stats = csv_compute_stats(user_id)
            # Merge sensible fields (prefer DB values, fallback to CSV)
            for k, v in csv_stats.items():
                if k not in txn_stats or not txn_stats.get(k):
                    txn_stats[k] = v
        except Exception as e:
            logger.debug(f"CSV history not available or failed to compute; continuing with DB stats. Error: {e}")
        
        # Get receiver reputation if provided
        receiver_info = {}
        if receiver:
            receiver_info = get_receiver_reputation(receiver, db)
            
            # Merge CSV-derived receiver summary if available
            try:
                from app.core.history_engine import get_receiver_summary_for_user
                csv_rec = get_receiver_summary_for_user(user_id, receiver)
                # Map CSV summary keys into receiver_info expected fields
                receiver_info.setdefault('is_new', csv_rec.get('is_new', receiver_info.get('is_new', True)))
                receiver_info.setdefault('total_transactions', csv_rec.get('total_transactions', receiver_info.get('total_transactions', 0)))
                receiver_info.setdefault('reputation_score', csv_rec.get('reputation_score', receiver_info.get('reputation_score', 0.5)))
            except Exception:
                pass
            
            # ─────────────────────────────────────────────────────────────
            # NEW: Analyze detailed receiver history (The Brain update)
            # ─────────────────────────────────────────────────────────────
            history_analysis = analyze_receiver_history(user_id, receiver, db)
            receiver_info.update(history_analysis)
        
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
    - Average amount (30 days, 7 days)
    - Max amount (30 days, 7 days)
    - Transaction count (30 days, 24 hours, 1 hour, 5 minutes)
    - Days since last transaction
    - Night transaction ratio
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
            "avg_amount_7d": 0.0,
            "max_amount_30d": 0.0,
            "max_amount_7d": 0.0,
            "txn_count_30d": 0,
            "txn_count_24h": 0,
            "txn_count_1hour": 0,
            "txn_count_5min": 0,
            "night_txn_ratio": 0.0,
            "failed_txn_count_7d": 0,
            "days_since_last_txn": 999,
            "user_tenure_days": 0
        }
    
    internal_user_id = user_orm.id

    now = datetime.utcnow()
    thirty_days_ago = now - timedelta(days=30)
    seven_days_ago = now - timedelta(days=7)
    one_day_ago = now - timedelta(days=1)
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
    night_txns = 0
    
    if txns_30d:
        amounts = [float(txn.amount) for txn in txns_30d]
        avg_amount_30d = sum(amounts) / len(amounts)
        max_amount_30d = max(amounts)
        
        # Calculate night txn ratio (23:00 to 05:00)
        night_txns = len([t for t in txns_30d if t.created_at.hour >= 23 or t.created_at.hour <= 5])
    
    night_txn_ratio = night_txns / max(txn_count_30d, 1)

    # 7-day statistics
    txns_7d = [t for t in txns_30d if t.created_at >= seven_days_ago]
    avg_amount_7d = 0.0
    max_amount_7d = 0.0
    if txns_7d:
        amounts_7d = [float(txn.amount) for txn in txns_7d]
        avg_amount_7d = sum(amounts_7d) / len(amounts_7d)
        max_amount_7d = max(amounts_7d)

    # 24-hour count
    txn_count_24h = db.query(Transaction).filter(
        Transaction.user_id == internal_user_id,
        Transaction.created_at >= one_day_ago
    ).count()

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
        "avg_amount_7d": avg_amount_7d,
        "max_amount_30d": max_amount_30d,
        "max_amount_7d": max_amount_7d,
        "txn_count_30d": txn_count_30d,
        "txn_count_24h": txn_count_24h,
        "txn_count_1hour": txn_count_1hour,
        "txn_count_5min": txn_count_5min,
        "night_txn_ratio": night_txn_ratio,
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
    Uses dedicated ReceiverHistory table for efficiency.
    """
    user_orm = db.query(User).filter(User.user_id == user_id).first()
    if not user_orm:
        return True
        
    # Standardize receiver ID
    receiver_upi = receiver.lower().strip()
    
    from app.database.models import ReceiverHistory
    
    history_record = db.query(ReceiverHistory).filter(
        ReceiverHistory.user_id == user_orm.id,
        ReceiverHistory.receiver_upi == receiver_upi
    ).first()
    
    return history_record is None


def analyze_receiver_history(user_id: str, receiver_upi: str, db: Session) -> Dict:
    """
    Advanced receiver history analysis based on transaction records.
    
    Logic:
    - Normalizes UPI ID
    - Checks for successful (COMPLETED) transactions
    - Flags suspicious behavior (FAILED/BLOCKED/HIGH_RISK)
    """
    # 1. Normalize UPI ID
    receiver_upi = receiver_upi.lower().strip()
    
    # 2. Get User internal ID
    user_orm = db.query(User).filter(User.user_id == user_id).first()
    if not user_orm:
        return {
            "is_new": True,
            "good_history": False,
            "risky_history": False,
            "transaction_count": 0,
            "avg_risk_score": 0.0,
            "receiver_trust_score": 0.0
        }
    
    # 4. Phase 1: Check established history record (Primary Source of Truth)
    from app.database.models import ReceiverHistory
    history_record = db.query(ReceiverHistory).filter(
        ReceiverHistory.user_id == user_orm.id,
        ReceiverHistory.receiver_upi == receiver_upi
    ).first()
    
    # 5. Phase 2: Query Transactions for Detailed Risk Profiling
    # We only care about COMPLETED transactions for the "Count"
    # and all transactions for the "Risk" profile
    all_txns = db.query(Transaction).filter(
        Transaction.user_id == user_orm.id,
        Transaction.receiver == receiver_upi
    ).all()
    
    completed_txns = [t for t in all_txns if t.status == "COMPLETED"]
    txn_count = len(completed_txns)
    
    # Fallback to history record count if transaction list is lagging
    if history_record and history_record.payment_count > txn_count:
        txn_count = history_record.payment_count

    failed_count = len([t for t in all_txns if t.status == "FAILED"])
    blocked_count = len([t for t in all_txns if t.status == "BLOCKED"])
    high_risk_flags = len([t for t in all_txns if t.risk_level in ["HIGH", "VERY_HIGH"]])
    
    # Calculate average risk of COMPLETED transactions
    if txn_count > 0:
        avg_risk = sum([float(t.risk_score or 0.0) for t in completed_txns]) / len(completed_txns) if completed_txns else 0.0
    else:
        avg_risk = 0.0
    
    # 6. Define History Profiles (STRICT FINTECH LOGIC)
    
    # A receiver is "NEW" if no COMPLETED transactions exist in history table OR transaction table
    is_new = (txn_count == 0) and (history_record is None)
    
    # Case 2: Good History
    is_good = (
        txn_count >= 2 and 
        blocked_count == 0 and 
        high_risk_flags == 0 and 
        avg_risk < 0.50
    )
    
    # Case 3: Risky History
    is_risky = (
        failed_count >= 2 or 
        blocked_count > 0 or 
        high_risk_flags > 0 or 
        avg_risk > 0.70
    )
    
    logger.info(f"Receiver Analysis for {receiver_upi}: New={is_new}, Count={txn_count}, Risky={is_risky}")
    
    return {
        "is_new": is_new,
        "good_history": is_good,
        "risky_history": is_risky,
        "transaction_count": txn_count,
        "avg_risk_score": round(avg_risk, 2)
    }
    

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
        from datetime import timezone
        cutoff_date = datetime.now(timezone.utc) - timedelta(days=days)
        
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
