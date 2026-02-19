import os
os.environ.setdefault('DATABASE_URL', 'sqlite:///:memory:')
os.environ.setdefault('REDIS_URL', 'redis://localhost')
os.environ.setdefault('SECRET_KEY', 'dev')

from app.core.ml_engine import load_model
from app.core import ml_engine

load_model()
print('model_available:', ml_engine.model_available)
print('model obj:', type(ml_engine.model) if ml_engine.model is not None else None)
