import os
import math

os.environ.setdefault('DATABASE_URL', 'sqlite:///:memory:')
os.environ.setdefault('REDIS_URL', 'redis://localhost')
os.environ.setdefault('SECRET_KEY', 'dev')
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.core.ml_engine import engineer_features
from app.core.context_engine import UserContext


def test_engineer_features_basic():
    # Build a minimal user context
    profile = {'user_id': 'testuser@upi', 'known_devices': ['dev-1'], 'trust_score': 50, 'risk_tier': 'BRONZE'}
    txn_stats = {
        'avg_amount_30d': 500.0,
        'avg_amount_7d': 450.0,
        'max_amount_7d': 1000.0,
        'txn_count_30d': 5,
        'txn_count_24h': 0,
        'txn_count_1hour': 0,
        'night_txn_ratio': 0.1,
        'days_since_last_txn': 2,
        'receiver_map': {}
    }
    receiver_info = {'is_new': True, 'total_transactions': 0, 'reputation_score': 0.1}

    ctx = UserContext(profile, txn_stats, receiver_info)

    txn = {'amount': 1000, 'receiver': 'recv1@upi', 'device_id': 'dev-2', 'ip_city': 'Mumbai'}
    features = engineer_features(txn, ctx)

    # Basic sanity checks
    assert 'deviation_from_sender_avg' in features
    assert 'receiver_amount_deviation' in features
    assert 'is_new_receiver' in features
    assert not math.isnan(features.get('amount', 0.0))
    assert features.get('deviation_from_sender_avg') > 0


if __name__ == '__main__':
    test_engineer_features_basic()
    print('OK')
