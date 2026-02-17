from app.core import ml_engine
from app.core.context_engine import UserContext
import logging

logging.basicConfig(level=logging.INFO)

# Mock context
context = UserContext(
    user_profile={"trust_score": 85, "known_devices": ["dev1"]},
    txn_stats={"avg_amount_30d": 5000, "txn_count_5min": 0},
    receiver_info={"is_new": False, "good_history": True, "risky_history": False}
)

txn_data = {"amount": 500, "receiver": "test@upi", "device_id": "dev1"}

result = ml_engine.predict(txn_data, context)
print(f"\nModel Available: {ml_engine.model_available}")
print(f"Model Version: {result.model_version}")
print(f"ML Score: {result.ml_score}")
print(f"Good History Flag: {result.features['good_history_flag']}")
print(f"Risky History Flag: {result.features['risky_history_flag']}")
