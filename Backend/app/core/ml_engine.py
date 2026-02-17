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
        # Real model prediction - updated to 22 features
        try:
            # We match the EXACT names and order from the model
            feature_names = [
                'amount', 'payment_mode', 'receiver_type', 'is_new_receiver', 
                'avg_amount_7d', 'avg_amount_30d', 'max_amount_7d', 'txn_count_1h', 
                'txn_count_24h', 'days_since_last_txn', 'night_txn_ratio', 
                'location_mismatch', 'is_night', 'is_round_amount', 'velocity_check', 
                'deviation_from_sender_avg', 'exceeds_recent_max', 'amount_log', 
                'hour_sin', 'hour_cos', 'ratio_30d', 'risk_profile'
            ]
            
            # Ensure features are correctly typed (CatBoost is strict about categorical types)
            feature_vector = []
            for i, name in enumerate(feature_names):
                val = float(features.get(name, 0.0))
                # Features at indices 1, 2, 21 are categorical (payment_mode, receiver_type, risk_profile)
                if i in [1, 2, 21]:
                    feature_vector.append(int(val))
                else:
                    feature_vector.append(val)
            
            # Predict probability
            ml_score = float(model.predict_proba([feature_vector])[0][1])
            model_version = getattr(settings, "ML_MODEL_VERSION", "v1.1")
            
            logger.info(f"ML prediction: {ml_score:.3f} using {len(feature_vector)} features")
        except Exception as e:
            logger.error(f"Error during ML inference: {e}")
            ml_score = calculate_fallback_score(features)
            model_version = "v1.1-fallback"
    else:
        # Fallback: Rule-based prediction
        ml_score = calculate_fallback_score(features)
        model_version = "rule-fallback"
        logger.debug(f"Rule-fallback prediction: {ml_score:.3f}")
    
    return MLResult(
        ml_score=ml_score,
        features=features,
        model_version=model_version
    )


def engineer_features(txn_data: Dict, context: UserContext) -> Dict:
    """
    Engineer 22 features for the upgraded ML model.
    Exactly aligned with upi_fraud_hackathon_v4_replica_complete.csv schema.
    """
    amount = float(txn_data.get("amount", 0.0))
    receiver = txn_data.get("receiver", "")
    device_id = txn_data.get("device_id", "")
    
    stats = context.txn_stats
    profile = context.user_profile
    receiver_info = context.receiver_info or {}
    
    now = datetime.utcnow()
    hour = now.hour
    
    # 1. Base Features
    avg_7d = stats.get("avg_amount_7d", 0.0)
    avg_30d = stats.get("avg_amount_30d", 1000.0)
    if avg_30d == 0: avg_30d = 1000.0
    
    # night_txn_ratio calculation
    night_ratio = stats.get("night_txn_ratio", 0.0)
    
    # is_night flag (23:00 to 05:00)
    is_night = 1.0 if hour >= 23 or hour <= 5 else 0.0
    
    # is_round_amount
    is_round = 1.0 if amount > 0 and amount % 100 == 0 else 0.0
    
    # velocity_check (Trigger if frequency is 3x the normal)
    velocity_check = 1.0 if stats.get("txn_count_1hour", 0) > 5 else 0.0
    
    # deviation_from_sender_avg
    deviation = amount / avg_30d
    
    # exceeds_recent_max
    max_7d = stats.get("max_amount_7d", 0.0)
    exceeds_max = 1.0 if amount > max_7d and max_7d > 0 else 0.0

    # 2. Advanced Derived Features
    amount_log = np.log1p(amount)
    
    # Cyclical Time Features
    hour_sin = np.sin(2 * np.pi * hour / 24)
    hour_cos = np.cos(2 * np.pi * hour / 24)
    
    # ratio_30d
    ratio_30d = amount / (avg_30d + 1.0)
    
    # risk_profile (Relationship score)
    # If they have a risky history, this score is higher
    risk_profile = receiver_info.get("reputation_score", 0.1)
    if receiver_info.get("risky_history"):
        risk_profile = max(risk_profile, 0.8)
    elif receiver_info.get("good_history"):
        risk_profile = min(risk_profile, 0.05)

    features = {
        "amount": amount,
        "payment_mode": 2.0, # Default to UPI App
        "receiver_type": 1.0 if "@" in receiver and not receiver.split("@")[0].isdigit() else 0.0,
        "is_new_receiver": 1.0 if receiver_info.get("is_new", False) else 0.0,
        "avg_amount_7d": avg_7d,
        "avg_amount_30d": avg_30d,
        "max_amount_7d": max_7d,
        "txn_count_1h": float(stats.get("txn_count_1hour", 0)),
        "txn_count_24h": float(stats.get("txn_count_24h", 0)),
        "days_since_last_txn": float(stats.get("days_since_last_txn", 999)),
        "night_txn_ratio": night_ratio,
        "location_mismatch": 0.0, # Placeholder
        "is_night": is_night,
        "is_round_amount": is_round,
        "velocity_check": velocity_check,
        "deviation_from_sender_avg": deviation,
        "exceeds_recent_max": exceeds_max,
        "amount_log": amount_log,
        "hour_sin": hour_sin,
        "hour_cos": hour_cos,
        "ratio_30d": ratio_30d,
        "risk_profile": risk_profile,
        
        # Backward compatibility for fallback
        "risky_history_flag": 1.0 if receiver_info.get("risky_history") else 0.0,
        "good_history_flag": 1.0 if receiver_info.get("good_history") else 0.0,
        "amount_to_avg_ratio": deviation,
        "device_change_flag": 1.0 if device_id and device_id not in profile.get("known_devices", []) else 0.0,
        "receiver_reputation_score": risk_profile
    }
    
    return features


def calculate_fallback_score(features: Dict) -> float:
    """
    Calculate fallback fraud score when ML model is not available.
    Updated to use new feature keys from 22-feature engine.
    """
    score = 0.0
    
    # History Profile (High Confidence)
    if features.get("risky_history_flag") == 1.0:
        score += 0.35
    elif features.get("good_history_flag") == 1.0:
        score -= 0.15
        
    # High deviation/amount ratio
    deviation = features.get("deviation_from_sender_avg", 1.0)
    if deviation > 10:
        score += 0.40
    elif deviation > 5:
        score += 0.25
    
    # New receiver
    if features.get("is_new_receiver") == 1.0 and features.get("good_history_flag") == 0:
        score += 0.15
    
    # Velocity spike
    if features.get("txn_count_1h", 0) >= 5 or features.get("velocity_check") == 1.0:
        score += 0.25
        
    # Device change
    if features.get("device_change_flag") == 1.0:
        score += 0.15
        
    if features.get("risk_profile", 0.5) > 0.7:
        score += 0.25
    
    return max(0.0, min(score, 1.0))


# Load model on module import
try:
    load_model()
except Exception as e:
    logger.error(f"Failed to load ML model on import: {e}")
