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
        # Resolve relative paths robustly: try the configured path first,
        # then a few common locations relative to the repository/app layout.
        candidate_paths = [model_path]
        if not os.path.isabs(model_path):
            candidate_paths.append(os.path.abspath(os.path.join(os.getcwd(), model_path)))
            # Try typical repo layout from this module: go up to Sentra-Pay root and look in ML/
            candidate_paths.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'ML', os.path.basename(model_path))))
            # Try Sentra-Pay/ML relative to workspace cwd
            candidate_paths.append(os.path.abspath(os.path.join(os.getcwd(), 'Sentra-Pay', 'ML', os.path.basename(model_path))))
            # Walk upward from this file's directory to look for a top-level ML/ folder
            cur_dir = os.path.abspath(os.path.dirname(__file__))
            for _ in range(6):
                upward_cand = os.path.abspath(os.path.join(cur_dir, '..', 'ML', os.path.basename(model_path)))
                candidate_paths.append(upward_cand)
                cur_dir = os.path.abspath(os.path.join(cur_dir, '..'))

        found = None
        for p in candidate_paths:
            try:
                if p and os.path.exists(p):
                    found = p
                    break
            except Exception:
                continue

        if found:
            model = CatBoostClassifier()
            model.load_model(found)
            model_available = True
            logger.info(f"ML model loaded from: {found}")
        else:
            logger.warning(f"ML model not found at any candidate path: {candidate_paths}. Using fallback predictions.")
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
    
    # Build the 7-feature vector expected by the simplified model
    try:
        amount_deviation = float(features.get('deviation_from_sender_avg', 0.0))
        night_ratio = float(features.get('night_txn_ratio', 0.0))
        txn_last_1hr = float(features.get('txn_count_1h', features.get('txn_count_1hour', 0)))
        is_new_receiver = float(features.get('is_new_receiver', 0.0))
        impossible_travel_flag = 1.0 if context.txn_stats.get('impossible_travel_flag') else 0.0

        # receiver_txn_count: prefer receiver_info.total_transactions then stats.receiver_map
        receiver = txn_data.get('receiver')
        receiver_txn_count = 0.0
        try:
            receiver_txn_count = float(context.receiver_info.get('total_transactions', 0) or 0)
        except Exception:
            receiver_txn_count = 0.0
        if receiver_txn_count == 0:
            rmap = context.txn_stats.get('receiver_map', {})
            if receiver and receiver in rmap:
                receiver_txn_count = float(rmap[receiver].get('count', 0))

        receiver_amount_deviation = float(features.get('receiver_amount_deviation', 1.0))

        model_vector = [
            amount_deviation,
            night_ratio,
            txn_last_1hr,
            is_new_receiver,
            impossible_travel_flag,
            receiver_txn_count,
            receiver_amount_deviation
        ]

    except Exception as e:
        logger.error(f"Error building 7-feature vector: {e}")
        model_vector = None

    # Get prediction using the simplified 7-feature interface if possible
    if model_available and model is not None and model_vector is not None:
        try:
            # Attempt to use model with the 7-feature vector
            ml_score = float(model.predict_proba([model_vector])[0][1])
            model_version = getattr(settings, "ML_MODEL_VERSION", "v1.1")
            logger.info(f"ML prediction (7-features): {ml_score:.3f}")
        except Exception as e:
            logger.warning(f"Model failed for 7-feature vector, attempting full-vector fallback: {e}")
            # Try the full 22-feature vector as a fallback (model may expect original feature layout)
            try:
                feature_names = [
                    'amount', 'payment_mode', 'receiver_type', 'is_new_receiver',
                    'avg_amount_7d', 'avg_amount_30d', 'max_amount_7d', 'txn_count_1h',
                    'txn_count_24h', 'days_since_last_txn', 'night_txn_ratio',
                    'location_mismatch', 'is_night', 'is_round_amount', 'velocity_check',
                    'deviation_from_sender_avg', 'exceeds_recent_max', 'amount_log',
                    'hour_sin', 'hour_cos', 'ratio_30d', 'risk_profile'
                ]
                feature_vector = []
                for i, name in enumerate(feature_names):
                    val = features.get(name, 0.0)
                    try:
                        valf = float(val)
                    except Exception:
                        valf = 0.0
                    # indices 1,2,21 are categorical in original model
                    if i in [1, 2, 21]:
                        feature_vector.append(int(valf))
                    else:
                        feature_vector.append(valf)

                ml_score = float(model.predict_proba([feature_vector])[0][1])
                model_version = getattr(settings, "ML_MODEL_VERSION", "v1.1") + "-fullvec"
                logger.info(f"ML prediction (22-features fallback): {ml_score:.3f}")
            except Exception as e2:
                logger.error(f"Full-vector model fallback failed: {e2}")
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
        # location_mismatch: 1.0 if current txn city differs from last known city or impossible_travel_flag
        "location_mismatch": 0.0,
        "is_night": is_night,
        "is_round_amount": is_round,
        "velocity_check": velocity_check,
        "deviation_from_sender_avg": deviation,
        "exceeds_recent_max": exceeds_max,
        "amount_log": amount_log,
        # receiver amount deviation (current / receiver_avg)
        "receiver_amount_deviation": 1.0,
        "hour_sin": hour_sin,
        "hour_cos": hour_cos,
        "ratio_30d": ratio_30d,
        "risk_profile": risk_profile,
        
        # Backward compatibility for fallback
        "risky_history_flag": 1.0 if receiver_info.get("risky_history") else 0.0,
        "good_history_flag": 1.0 if receiver_info.get("good_history") else 0.0,
        "amount_to_avg_ratio": deviation,
        # Device-change feature disabled: keep as 0.0 for compatibility
        "device_change_flag": 0.0,
        # Reputation removed from receiver scoring — set to neutral 0.0
        "receiver_reputation_score": 0.0
    }

    # Additional derived features using history stats
    # receiver average
    receiver_avg = None
    try:
        # receiver_info may have avg_amount key or 'avg_amount' from CSV summary
        receiver_avg = receiver_info.get('avg_amount') if receiver_info.get('avg_amount') is not None else None
    except Exception:
        receiver_avg = None

    if receiver_avg and receiver_avg > 0:
        features['receiver_amount_deviation'] = amount / float(receiver_avg)
    else:
        # fallback: if receiver_map has values
        rmap = stats.get('receiver_map', {})
        rentry = rmap.get(receiver)
        if rentry and rentry.get('amounts'):
            avg_r = sum(rentry['amounts']) / len(rentry['amounts'])
            features['receiver_amount_deviation'] = amount / (avg_r if avg_r > 0 else 1.0)

    # location mismatch / impossible travel
    current_city = txn_data.get('ip_city') or txn_data.get('city')
    last_city = stats.get('last_city')
    if stats.get('impossible_travel_flag'):
        features['location_mismatch'] = 1.0
    elif last_city and current_city and last_city.lower() != str(current_city).lower():
        # if last txn was recent (days_since_last_txn small) consider mismatch
        if stats.get('days_since_last_txn', 999) <= 2:
            features['location_mismatch'] = 1.0

    # unusual hour detection
    frequent_hours = stats.get('frequent_hours') or []
    unusual_hour = 0.0
    if frequent_hours and hour not in frequent_hours:
        unusual_hour = 1.0
    # expose for downstream rules/tests
    features['unusual_hour'] = unusual_hour
    
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
