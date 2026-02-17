from catboost import CatBoostClassifier
import os

PREVIOUS_MODEL = "app/ml/catboost_fraud_final.cbm"
NEW_MODEL = "app/ml/fraud_model.cbm"

def inspect():
    m_prev = CatBoostClassifier().load_model(PREVIOUS_MODEL)
    m_new = CatBoostClassifier().load_model(NEW_MODEL)
    
    print("Previous Model Features:")
    print(m_prev.feature_names_)
    
    print("\nNew Model Features:")
    print(m_new.feature_names_)

if __name__ == "__main__":
    inspect()
