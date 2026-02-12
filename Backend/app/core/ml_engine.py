"""
ML ENGINE - CatBoost Fraud Prediction
Feature engineering and model inference for probabilistic risk scoring.
"""

from typing import Dict, List, Optional
from datetime import datetime
import logging
import os
import numpy as np

from app.core.context_engine import UserContext
from app.config import settings

logger = logging.getLogger(__name__)

# Global model instance
model = None
model_available = False


def load_model():
    """
    Load CatBoost model from file.
    
    Falls back to mock predictions if model file doesn't exist.
    This allows the system to run without a trained model during development.
    """
    global model, model_available
    
    try:
        from catboost import CatBoostClassifier
        
        model_path = getattr(settings, "ML_MODEL_PATH", "app/ml_models/fraud_model.cbm")
        
        if os.path.exists(model_path):
            model = CatBoostClassifier()
            model.load_model(model_path)
            model_available = True
            logger.info(f"ML model loaded from: {model_path}")
        else:
            logger.warning(f"ML model not found at {model_path}. Using fallback predictions.")
            model_available = False
    
    except ImportError:
        logger.warning("CatBoost not installed. Using fallback predictions.")
        model_available = False
    except Exception as e:
        logger.error(f"Error loading ML model: {e}")
        model_available = False


class MLResult:
    """Result from ML engine prediction."""
    def __init__(self, ml_score: float, features: Dict, model_version: str = "fallback"):
        self.ml_score = ml_score
        self.features = features
        self.model_version = model_version


def predict(txn_data: Dict, context: UserContext) -> MLResult:
    """
    Predict fraud probability using ML model.
    
    Args:
        txn_data: Transaction data (amount, receiver, device_id, etc.)
        context: User context from context engine
    
    Returns:
        MLResult with probability score and features
    """
    # Extract features
    features = engineer_features(txn_data, context)
    
    # Get prediction
    if model_available and model is not None:
        # Real model prediction
        feature_vector = [features[f"feature_{i}"] for i in range(1, 15)]
        ml_score = float(model.predict_proba([feature_vector])[0][1])
        model_version = "v1.0"
        logger.info(f"ML prediction: {ml_score:.3f}")
    else:
        # Fallback: Rule-based prediction
        ml_score = calculate_fallback_score(features)
        model_version = "fallback"
        logger.debug(f"Fallback prediction: {ml_score:.3f}")
    
    return MLResult(
        ml_score=ml_score,
        features=features,
        model_version=model_version
    )


def engineer_features(txn_data: Dict, context: UserContext) -> Dict:
    """
    Engineer 14 features for ML model.
    
    Features:
    1. amount_to_avg_ratio - Current amount / 30-day average
    2. is_new_receiver - 1 if new, 0 if known
    3. txn_velocity_5min - Transactions in last 5 minutes
    4. txn_velocity_1hour - Transactions in last hour
    5. days_since_last_txn - Days since last transaction
    6. hour_of_day - 0-23
    7. day_of_week - 0-6 (Monday=0)
    8. device_change_flag - 1 if new device, 0 if known
    9. receiver_reputation_score - 0.0-1.0 (fraud ratio)
    10. avg_amount_30d - User's 30-day average
    11. max_amount_30d - User's 30-day maximum
    12. failed_txn_count_7d - Failed transactions in 7 days
    13. user_tenure_days - Days since account creation
    14. trust_score - User's trust score
    
    Args:
        txn_data: Transaction data
        context: User context
    
    Returns:
        Dictionary with all features
    """
    amount = txn_data.get("amount", 0.0)
    receiver = txn_data.get("receiver", "")
    device_id = txn_data.get("device_id", "")
    
    stats = context.txn_stats
    profile = context.user_profile
    receiver_info = context.receiver_info or {}
    
    # Feature 1: Amount to average ratio
    avg_amount = stats.get("avg_amount_30d", 1000.0)  # Default baseline
    if avg_amount == 0:
        avg_amount = 1000.0
    amount_to_avg_ratio = amount / avg_amount
    
    # Feature 2: Is new receiver
    is_new_receiver = 1.0 if receiver_info.get("is_new", False) else 0.0
    
    # Feature 3-4: Velocity
    txn_velocity_5min = float(stats.get("txn_count_5min", 0))
    txn_velocity_1hour = float(stats.get("txn_count_1hour", 0))
    
    # Feature 5: Days since last transaction
    days_since_last_txn = float(stats.get("days_since_last_txn", 999))
    
    # Feature 6-7: Time features
    now = datetime.utcnow()
    hour_of_day = float(now.hour)
    day_of_week = float(now.weekday())
    
    # Feature 8: Device change
    known_devices = profile.get("known_devices", [])
    device_change_flag = 1.0 if device_id and device_id not in known_devices else 0.0
    
    # Feature 9: Receiver reputation
    receiver_reputation_score = receiver_info.get("reputation_score", 0.5)
    
    # Feature 10-11: Amount statistics
    avg_amount_30d = stats.get("avg_amount_30d", 0.0)
    max_amount_30d = stats.get("max_amount_30d", 0.0)
    
    # Feature 12: Failed transactions
    failed_txn_count_7d = float(stats.get("failed_txn_count_7d", 0))
    
    # Feature 13: User tenure
    user_tenure_days = float(stats.get("user_tenure_days", 0))
    
    # Feature 14: Trust score
    trust_score = float(profile.get("trust_score", 0.0))
    
    features = {
        "feature_1": amount_to_avg_ratio,
        "feature_2": is_new_receiver,
        "feature_3": txn_velocity_5min,
        "feature_4": txn_velocity_1hour,
        "feature_5": days_since_last_txn,
        "feature_6": hour_of_day,
        "feature_7": day_of_week,
        "feature_8": device_change_flag,
        "feature_9": receiver_reputation_score,
        "feature_10": avg_amount_30d,
        "feature_11": max_amount_30d,
        "feature_12": failed_txn_count_7d,
        "feature_13": user_tenure_days,
        "feature_14": trust_score,
        # Named features for clarity
        "amount_to_avg_ratio": amount_to_avg_ratio,
        "is_new_receiver": is_new_receiver,
        "txn_velocity_5min": txn_velocity_5min,
        "txn_velocity_1hour": txn_velocity_1hour,
        "days_since_last_txn": days_since_last_txn,
        "hour_of_day": hour_of_day,
        "day_of_week": day_of_week,
        "device_change_flag": device_change_flag,
        "receiver_reputation_score": receiver_reputation_score,
        "avg_amount_30d": avg_amount_30d,
        "max_amount_30d": max_amount_30d,
        "failed_txn_count_7d": failed_txn_count_7d,
        "user_tenure_days": user_tenure_days,
        "trust_score": trust_score
    }
    
    return features


def calculate_fallback_score(features: Dict) -> float:
    """
    Calculate fallback fraud score when ML model is not available.
    
    Uses simple heuristics based on feature values.
    This is NOT a substitute for a trained model, but allows development/testing.
    
    Args:
        features: Engineered features
    
    Returns:
        Fraud probability 0.0 - 1.0
    """
    score = 0.0
    
    # High amount to average ratio
    if features["amount_to_avg_ratio"] > 5:
        score += 0.25
    elif features["amount_to_avg_ratio"] > 3:
        score += 0.15
    
    # New receiver
    if features["is_new_receiver"] == 1.0:
        score += 0.10
    
    # Velocity spike
    if features["txn_velocity_5min"] >= 3:
        score += 0.20
    elif features["txn_velocity_1hour"] >= 10:
        score += 0.10
    
    # Dormant account
    if features["days_since_last_txn"] > 30:
        score += 0.15
    
    # Device change
    if features["device_change_flag"] == 1.0:
        score += 0.10
    
    # Bad receiver reputation
    if features["receiver_reputation_score"] > 0.7:
        score += 0.20
    
    # Failed transactions
    if features["failed_txn_count_7d"] >= 3:
        score += 0.15
    
    # Low trust score
    if features["trust_score"] < 20:
        score += 0.10
    
    # Unusual time (late night: 1 AM - 5 AM)
    if 1 <= features["hour_of_day"] <= 5:
        score += 0.05
    
    return min(score, 1.0)


# Load model on module import
try:
    load_model()
except Exception as e:
    logger.error(f"Failed to load ML model on import: {e}")
