"""
RULES ENGINE - Deterministic Fraud Detection
Catches patterns ML might miss.
"""

from typing import Dict, List, Optional
from datetime import datetime, timedelta
import logging

from app.core.context_engine import UserContext, check_new_receiver
from app.config import settings

logger = logging.getLogger(__name__)


class RuleResult:
    """Result from rules engine evaluation."""
    def __init__(self):
        self.rule_score = 0.0
        self.flags: List[str] = []
        self.hard_block = False
        self.block_reason: Optional[str] = None
        self.rule_breakdown: Dict[str, float] = {}


def evaluate(txn_data: Dict, context: UserContext) -> RuleResult:
    """
    Evaluate all fraud detection rules.
    
    Args:
        txn_data: Transaction data (amount, receiver, device_id, etc.)
        context: User context from context engine
    
    Returns:
        RuleResult with score, flags, and potential hard block
    """
    result = RuleResult()
    
    amount = txn_data.get("amount", 0.0)
    receiver = txn_data.get("receiver", "")
    device_id = txn_data.get("device_id", "")
    
    # ────────────────────────────────────────────────
    # RULE 1: Velocity Check (5min and 1hour)
    # ────────────────────────────────────────────────
    velocity_score = check_velocity(
        txn_count_5min=context.txn_stats["txn_count_5min"],
        txn_count_1hour=context.txn_stats["txn_count_1hour"],
        days_since_last=context.txn_stats["days_since_last_txn"]
    )
    result.rule_breakdown["velocity"] = velocity_score
    
    if velocity_score > 0:
        result.flags.append("VELOCITY_SPIKE")
        logger.info(f"Velocity spike detected: {velocity_score}")
    
    # ────────────────────────────────────────────────
    # RULE 2: Blacklist Check (HARD BLOCK)
    # ────────────────────────────────────────────────
    blacklist_result = check_blacklist(
        receiver=receiver,
        receiver_info=context.receiver_info
    )
    
    if blacklist_result["is_blacklisted"]:
        result.hard_block = True
        result.block_reason = blacklist_result["reason"]
        logger.warning(f"Blacklist HARD BLOCK: {receiver}")
        return result  # Early exit for hard blocks
    
    # ────────────────────────────────────────────────
    # RULE 3: New Receiver + High Amount
    # ────────────────────────────────────────────────
    amount_anomaly_score = check_amount_anomaly(
        amount=amount,
        avg_amount_30d=context.txn_stats["avg_amount_30d"],
        max_amount_30d=context.txn_stats["max_amount_30d"],
        receiver=receiver,
        receiver_info=context.receiver_info
    )
    result.rule_breakdown["amount_anomaly"] = amount_anomaly_score
    
    if amount_anomaly_score > 0:
        result.flags.append("NEW_RECEIVER_HIGH_AMOUNT")
        logger.info(f"Amount anomaly detected: {amount_anomaly_score}")
    
    # ────────────────────────────────────────────────
    # RULE 4: Device Change Detection
    # ────────────────────────────────────────────────
    device_score = check_device_change(
        device_id=device_id,
        known_devices=context.user_profile.get("known_devices", [])
    )
    result.rule_breakdown["device_change"] = device_score
    
    if device_score > 0:
        result.flags.append("DEVICE_CHANGE")
        logger.info(f"Device change detected: {device_score}")
    
    # ────────────────────────────────────────────────
    # RULE 5: Failed Transaction Pattern
    # ────────────────────────────────────────────────
    failed_txn_score = check_failed_txn_pattern(
        failed_count=context.txn_stats["failed_txn_count_7d"]
    )
    result.rule_breakdown["failed_pattern"] = failed_txn_score
    
    if failed_txn_score > 0:
        result.flags.append("HIGH_FAILED_TXN")
    
    # ────────────────────────────────────────────────
    # COMBINE RULE SCORES
    # ────────────────────────────────────────────────
    result.rule_score = min(
        velocity_score + amount_anomaly_score + device_score + failed_txn_score,
        1.0  # Cap at 1.0
    )
    
    logger.info(f"Rules engine total score: {result.rule_score:.2f}")
    return result


def check_velocity(txn_count_5min: int, txn_count_1hour: int, days_since_last: int) -> float:
    """
    Check for velocity anomalies.
    
    Patterns:
    - Dormant account suddenly active: High risk
    - Multiple transactions in 5 minutes: High risk
    - Burst of transactions in 1 hour: Moderate risk
    
    Args:
        txn_count_5min: Transactions in last 5 minutes
        txn_count_1hour: Transactions in last hour
        days_since_last: Days since last transaction
    
    Returns:
        Risk score 0.0 - 1.0
    """
    score = 0.0
    
    # Dormant account activation (>7 days inactive, then burst)
    if days_since_last > 7 and txn_count_5min >= 3:
        score += 0.35
        logger.warning(f"Dormant account burst: {days_since_last} days, {txn_count_5min} txns/5min")
    
    # High frequency in 5 minutes
    if txn_count_5min >= 5:
        score += 0.25
    elif txn_count_5min >= 3:
        score += 0.15
    
    # High frequency in 1 hour
    if txn_count_1hour >= 15:
        score += 0.20
    elif txn_count_1hour >= 10:
        score += 0.10
    
    return min(score, 1.0)


def check_blacklist(receiver: str, receiver_info: Optional[Dict]) -> Dict:
    """
    Check if receiver is blacklisted.
    
    Criteria for blacklist:
    - Fraud ratio > 70%
    - Total transactions > 10 AND fraud count > 7
    
    Args:
        receiver: Receiver identifier
        receiver_info: Receiver reputation data
    
    Returns:
        Dictionary with is_blacklisted and reason
    """
    if not receiver_info:
        return {"is_blacklisted": False, "reason": None}
    
    fraud_ratio = receiver_info.get("fraud_ratio", 0.0)
    total_txns = receiver_info.get("total_transactions", 0)
    fraud_count = receiver_info.get("fraud_count", 0)
    
    # High fraud ratio
    if fraud_ratio > 0.70 and total_txns >= 10:
        return {
            "is_blacklisted": True,
            "reason": f"Receiver has {fraud_ratio*100:.0f}% fraud rate"
        }
    
    # High absolute fraud count
    if fraud_count >= 7 and total_txns >= 10:
        return {
            "is_blacklisted": True,
            "reason": f"Receiver has {fraud_count} fraud transactions"
        }
    
    return {"is_blacklisted": False, "reason": None}


def check_amount_anomaly(
    amount: float,
    avg_amount_30d: float,
    max_amount_30d: float,
    receiver: str,
    receiver_info: Optional[Dict]
) -> float:
    """
    Check for amount anomalies.
    
    Patterns:
    - New receiver + amount > 3x average: High risk
    - Amount > 5x average: Moderate risk
    - New receiver + amount > max_30d: Moderate risk
    
    Args:
        amount: Transaction amount
        avg_amount_30d: User's 30-day average
        max_amount_30d: User's 30-day maximum
        receiver: Receiver identifier
        receiver_info: Receiver reputation data
    
    Returns:
        Risk score 0.0 - 1.0
    """
    score = 0.0
    
    # Handle new users (no transaction history)
    if avg_amount_30d == 0:
        avg_amount_30d = 1000.0  # Default baseline
    
    is_new_receiver = receiver_info.get("is_new", False) if receiver_info else True
    amount_to_avg_ratio = amount / avg_amount_30d
    
    # New receiver + high amount (CRITICAL PATTERN)
    if is_new_receiver and amount > 3 * avg_amount_30d:
        score += 0.30
        logger.warning(f"New receiver + high amount: ₹{amount} vs avg ₹{avg_amount_30d}")
    
    # Extreme amount deviation
    if amount_to_avg_ratio > 5:
        score += 0.25
    elif amount_to_avg_ratio > 3:
        score += 0.15
    
    # Exceeds historical maximum
    if max_amount_30d > 0 and amount > max_amount_30d * 1.5:
        score += 0.10
    
    return min(score, 1.0)


def check_device_change(device_id: str, known_devices: List[str]) -> float:
    """
    Check for device change.
    
    Args:
        device_id: Current device identifier
        known_devices: List of known device IDs
    
    Returns:
        Risk score 0.0 - 1.0
    """
    if not device_id:
        return 0.0
    
    if device_id not in known_devices:
        logger.info(f"New device detected: {device_id}")
        return 0.15  # Moderate risk for new device
    
    return 0.0


def check_failed_txn_pattern(failed_count: int) -> float:
    """
    Check for suspicious failed transaction patterns.
    
    High failed transaction count may indicate:
    - Account testing
    - Failed fraud attempts
    - Compromised account
    
    Args:
        failed_count: Failed transactions in last 7 days
    
    Returns:
        Risk score 0.0 - 1.0
    """
    if failed_count >= 5:
        return 0.20
    elif failed_count >= 3:
        return 0.10
    
    return 0.0
