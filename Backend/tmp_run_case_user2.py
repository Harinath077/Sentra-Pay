import os
import json
from pprint import pprint

# Simple runner to analyze a single transaction using the Risk Orchestrator
from app.core.risk_orchestrator import orchestrator
from app.database.connection import init_db, SessionLocal
from app.database.models import User

txn = {
    "receiver": "recv2@upi",
    "amount": 100,
    "device_id": "device-unknown",
    "note": "test payment"
}

user_id = "user2@upi"

def ensure_user_exists(user_id: str):
    db = SessionLocal()
    try:
        u = db.query(User).filter(User.user_id == user_id).first()
        if not u:
            # Create a minimal user record required by orchestrator
            u = User(user_id=user_id, email=f"{user_id.replace('@','_')}@example.com", full_name="User Two")
            db.add(u)
            db.commit()
            print(f"Created user: {user_id}")
        else:
            print(f"User exists: {user_id}")
    finally:
        db.close()


if __name__ == "__main__":
    try:
        # Ensure DB tables exist and user is present
        init_db()
        ensure_user_exists(user_id)

        out = orchestrator.analyze_transaction(txn, user_id, db=None, save=False)
        print(json.dumps(out, indent=2, default=str))
    except Exception as e:
        print("ERROR:", type(e).__name__, str(e))
        raise
