import pandas as pd
import numpy as np
from catboost import CatBoostClassifier
import os

# 1. Generate Synthetic Data
# We simulate features extracted from QR codes and transaction context
data_size = 1000
np.random.seed(42)

data = {
    'amount': [],
    'is_personal_upi': [], # 1 if phone number based
    'has_url': [],         # 1 if contains URL
    'hourly_scan_count': [],
    'keyword_risk': [],    # 1 if 'winner', 'cashback' etc
    'is_fraud': []
}

for _ in range(data_size):
    is_fraud = np.random.choice([0, 1], p=[0.8, 0.2]) # 20% fraud rate
    
    if is_fraud:
        # Fraud patterns
        amount = np.random.choice([0, 5000, 10000, 50000], p=[0.1, 0.2, 0.3, 0.4])
        is_personal = np.random.choice([0, 1], p=[0.3, 0.7])
        has_url = np.random.choice([0, 1], p=[0.4, 0.6])
        scan_count = np.random.randint(10, 100) # Viral
        keyword = np.random.choice([0, 1], p=[0.2, 0.8])
    else:
        # Legit patterns
        amount = np.random.exponential(scale=500) # Mostly small amounts
        is_personal = np.random.choice([0, 1], p=[0.6, 0.4])
        has_url = 0
        scan_count = np.random.randint(0, 10) # Low activity
        keyword = 0

    data['amount'].append(amount)
    data['is_personal_upi'].append(is_personal)
    data['has_url'].append(has_url)
    data['hourly_scan_count'].append(scan_count)
    data['keyword_risk'].append(keyword)
    data['is_fraud'].append(is_fraud)

df = pd.DataFrame(data)

# 2. Train CatBoost Model
print("Training CatBoost Model...")
X = df.drop('is_fraud', axis=1)
y = df['is_fraud']

model = CatBoostClassifier(
    iterations=100,
    learning_rate=0.1,
    depth=6,
    verbose=False
)

model.fit(X, y)

# 3. Save Model
output_dir = "app/ml"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

model_path = os.path.join(output_dir, "fraud_model.cbm")
model.save_model(model_path)

print(f"✅ Model saved successfully to {model_path}")
print("Feature Importance:")
print(model.get_feature_importance(prettified=True))
