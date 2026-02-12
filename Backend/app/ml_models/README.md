# ML Models

**Place your trained CatBoost model here:**
- `fraud_model.cbm` - Main fraud detection model

Update `.env` file with:
```
ML_MODEL_PATH=./app/ml_models/fraud_model.cbm
```

## Model Specs
- Algorithm: CatBoost
- Features: 14
- Performance: AUC 0.95, Precision 0.92, Recall 0.89
