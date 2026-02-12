"""
DECISION ENGINE - Maps Risk to Actions
Determines appropriate friction level based on risk score and user trust.
"""

from typing import Dict, List
import logging

from app.config import settings

logger = logging.getLogger(__name__)


class ActionResult:
    """Result from decision engine."""
    def __init__(self, action: str, risk_level: str, requires_otp: bool = False):
        self.action = action
        self.risk_level = risk_level
        self.requires_otp = requires_otp
        self.message = ""
        self.recommendations: List[str] = []


def get_action(risk_score: float, flags: List[str], user_tier: str = "BRONZE") -> ActionResult:
    """
    Determine action based on risk score and context.
    
    Risk Buckets:
    - LOW (0.00-0.30): ALLOW - Proceed with transaction
    - MODERATE (0.30-0.60): WARNING - Show warning, allow user to proceed
    - HIGH (0.60-0.80): OTP_REQUIRED - Require additional verification
    - VERY_HIGH (0.80-1.00): BLOCK - Block transaction
    
    Args:
        risk_score: Final combined risk score (0.0 - 1.0)
        flags: List of risk flags from rules engine
        user_tier: User's trust tier (BRONZE, SILVER, GOLD)
    
    Returns:
        ActionResult with action, risk level, and requirements
    """
    # Map score to risk level
    risk_level = map_to_risk_level(risk_score)
    
    # Determine base action
    action = determine_base_action(risk_level)
    
    # Apply tier-based adjustments
    action, requires_otp = apply_tier_adjustment(action, risk_score, user_tier)
    
    # Create result
    result = ActionResult(
        action=action,
        risk_level=risk_level,
        requires_otp=requires_otp
    )
    
    # Generate message and recommendations
    result.message = generate_message(risk_level, action, flags)
    result.recommendations = generate_recommendations(risk_level, flags)
    
    logger.info(f"Decision: {action} (risk={risk_level}, score={risk_score:.2f}, tier={user_tier})")
    return result


def map_to_risk_level(risk_score: float) -> str:
    """
    Map risk score to risk level.
    
    Args:
        risk_score: Risk score 0.0 - 1.0
    
    Returns:
        Risk level: LOW, MODERATE, HIGH, VERY_HIGH
    """
    if risk_score < settings.RISK_THRESHOLD_LOW:
        return "LOW"
    elif risk_score < settings.RISK_THRESHOLD_MODERATE:
        return "MODERATE"
    elif risk_score < settings.RISK_THRESHOLD_HIGH:
        return "HIGH"
    else:
        return "VERY_HIGH"


def determine_base_action(risk_level: str) -> str:
    """
    Determine base action from risk level.
    
    Args:
        risk_level: LOW, MODERATE, HIGH, VERY_HIGH
    
    Returns:
        Action: ALLOW, WARNING, OTP_REQUIRED, BLOCK
    """
    action_map = {
        "LOW": "ALLOW",
        "MODERATE": "WARNING",
        "HIGH": "OTP_REQUIRED",
        "VERY_HIGH": "BLOCK"
    }
    return action_map.get(risk_level, "WARNING")


def apply_tier_adjustment(action: str, risk_score: float, user_tier: str) -> tuple:
    """
    Apply trust tier adjustments to action.
    
    GOLD users (71-100 trust): More lenient
    SILVER users (31-70 trust): Standard
    BRONZE users (0-30 trust): More strict
    
    Args:
        action: Base action
        risk_score: Risk score
        user_tier: User trust tier
    
    Returns:
        Tuple of (adjusted_action, requires_otp)
    """
    requires_otp = action == "OTP_REQUIRED"
    
    # GOLD users - reduce friction
    if user_tier == "GOLD":
        if action == "OTP_REQUIRED" and risk_score < 0.70:
            action = "WARNING"
            requires_otp = False
            logger.info("GOLD tier: Downgrading OTP_REQUIRED → WARNING")
        elif action == "WARNING" and risk_score < 0.40:
            action = "ALLOW"
            logger.info("GOLD tier: Downgrading WARNING → ALLOW")
    
    # BRONZE users - increase friction
    elif user_tier == "BRONZE":
        if action == "WARNING" and risk_score > 0.50:
            action = "OTP_REQUIRED"
            requires_otp = True
            logger.info("BRONZE tier: Upgrading WARNING → OTP_REQUIRED")
        elif action == "ALLOW" and risk_score > 0.25:
            action = "WARNING"
            logger.info("BRONZE tier: Upgrading ALLOW → WARNING")
    
    return action, requires_otp


def generate_message(risk_level: str, action: str, flags: List[str]) -> str:
    """
    Generate user-friendly message.
    
    Args:
        risk_level: Risk level
        action: Determined action
        flags: Risk flags
    
    Returns:
        Message string
    """
    if action == "ALLOW":
        return "Transaction approved. Low risk detected."
    
    elif action == "WARNING":
        if "NEW_RECEIVER_HIGH_AMOUNT" in flags:
            return "⚠️ Warning: This is a high amount to a new receiver. Please verify before proceeding."
        elif "VELOCITY_SPIKE" in flags:
            return "⚠️ Warning: Unusual transaction frequency detected. Please verify this transaction."
        else:
            return "⚠️ Warning: Moderate risk detected. Please review transaction details carefully."
    
    elif action == "OTP_REQUIRED":
        return "🔐 For your security, please verify this transaction with OTP."
    
    elif action == "BLOCK":
        if "NEW_RECEIVER_HIGH_AMOUNT" in flags and "VELOCITY_SPIKE" in flags:
            return "🚫 Transaction blocked: Multiple high-risk patterns detected. Contact support if this is legitimate."
        else:
            return "🚫 Transaction blocked: High fraud risk detected. Contact support if needed."
    
    return "Transaction under review."


def generate_recommendations(risk_level: str, flags: List[str]) -> List[str]:
    """
    Generate recommendations based on risk factors.
    
    Args:
        risk_level: Risk level
        flags: Risk flags
    
    Returns:
        List of recommendation strings
    """
    recommendations = []
    
    if "NEW_RECEIVER_HIGH_AMOUNT" in flags:
        recommendations.append("Verify receiver details carefully")
        recommendations.append("Start with a smaller test transaction")
    
    if "VELOCITY_SPIKE" in flags:
        recommendations.append("Wait a few minutes before next transaction")
        recommendations.append("Ensure your account is secure")
    
    if "DEVICE_CHANGE" in flags:
        recommendations.append("Verify you're using your trusted device")
    
    if "HIGH_FAILED_TXN" in flags:
        recommendations.append("Check your account for suspicious activity")
        recommendations.append("Update your password if needed")
    
    if risk_level in ["HIGH", "VERY_HIGH"]:
        recommendations.append("Contact support if you believe this is an error")
    
    return recommendations


def should_require_otp(risk_score: float, trust_score: float) -> bool:
    """
    Determine if OTP is required.
    
    Args:
        risk_score: Risk score 0.0 - 1.0
        trust_score: User trust score 0-100
    
    Returns:
        True if OTP required
    """
    # High risk always requires OTP
    if risk_score >= settings.RISK_THRESHOLD_HIGH:
        return True
    
    # Moderate risk + low trust requires OTP
    if risk_score >= settings.RISK_THRESHOLD_MODERATE and trust_score < 30:
        return True
    
    return False
