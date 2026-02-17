import pandas as pd
import numpy as np
from catboost import CatBoostClassifier
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 1. Generate Synthetic Data for 16 Contextual Features
# These align exactly with app/core/ml_engine.py
data_size = 5000
np.random.seed(42)

def generate_data(n):
    data = []
    for _ in range(n):
        # Feature 1: amount_to_avg_ratio
        amount_to_avg = np.random.exponential(1.5)
        if np.random.random() < 0.05: amount_to_avg *= 10  # Extreme spikes
        
        # Feature 2: is_new_receiver
        is_new = 1.0 if np.random.random() < 0.4 else 0.0
        
        # Feature 3-4: Velocity
        v_5m = float(np.random.poisson(0.1))
        v_1h = float(np.random.poisson(0.5))
        
        # Feature 5: days_since_last_txn
        days_last = float(np.random.randint(0, 60))
        
        # Feature 6-7: Time
        hour = float(np.random.randint(0, 24))
        day = float(np.random.randint(0, 7))
        
        # Feature 8: device_change
        device_change = 1.0 if np.random.random() < 0.1 else 0.0
        
        # Feature 9: receiver_reputation
        rep = np.random.beta(2, 5) # Mostly low fraud ratio, some high
        
        # Feature 10-11: Stats
        avg_30d = np.random.lognormal(8, 1) # ~3000 average
        max_30d = avg_30d * np.random.uniform(1, 3)
        
        # Feature 12: failed_txns
        failed = float(np.random.poisson(0.2))
        
        # Feature 13: tenure
        tenure = float(np.random.randint(1, 1000))
        
        # Feature 14: trust_score
        trust = np.random.uniform(0, 100)
        
        # Feature 15: good_history_flag
        good = 1.0 if not is_new and np.random.random() < 0.7 else 0.0
        
        # Feature 16: risky_history_flag
        risky = 1.0 if not is_new and not good and np.random.random() < 0.1 else 0.0
        if rep > 0.8: risky = 1.0
        
        # LABELING LOGIC (The "Ground Truth" for the AI)
        fraud_prob = 0.01 # Baseline
        
        if amount_to_avg > 8: fraud_prob += 0.3
        if is_new == 1.0: fraud_prob += 0.1
        if risky == 1.0: fraud_prob += 0.4
        if device_change == 1.0: fraud_prob += 0.2
        if v_5m > 2: fraud_prob += 0.3
        if 1 <= hour <= 5: fraud_prob += 0.1 # Night risk
        if good == 1.0: fraud_prob -= 0.2
        
        is_fraud = 1 if np.random.random() < fraud_prob else 0
        
        data.append([
            amount_to_avg, is_new, v_5m, v_1h, days_last, hour, day,
            device_change, rep, avg_30d, max_30d, failed, tenure, trust,
            good, risky, is_fraud
        ])
    
    cols = [f"feature_{i}" for i in range(1, 17)] + ["is_fraud"]
    return pd.DataFrame(data, columns=cols)

# 2. Train Model
logger.info("Generating synthetic training data...")
df = generate_data(data_size)

X = df.drop('is_fraud', axis=1)
y = df['is_fraud']

logger.info(f"Training on {len(X)} samples with {len(X.columns)} features...")
model = CatBoostClassifier(
    iterations=100,
    depth=6,
    learning_rate=0.1,
    loss_function='Logloss',
    verbose=False
)

model.fit(X, y)

# 3. Save Model
output_dir = "app/ml"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

model_path = os.path.join(output_dir, "fraud_model.cbm")
model.save_model(model_path)

logger.info(f"✅ Contextual Fraud Model saved to {model_path}")
logger.info(f"Feature count: {len(X.columns)}")
