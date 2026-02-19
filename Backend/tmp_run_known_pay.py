import os
import json
from pprint import pprint

# Runner to analyze a known-device routine payment
from app.core.risk_orchestrator import orchestrator
from app.database.connection import init_db, SessionLocal
from app.database.models import User

txn = {
    "receiver": "recv2@upi",
    "amount": 100,
    "device_id": "dev-known-1",
    "ip_city": "Mumbai",
    "timestamp": "2026-02-19T10:00:00Z",
    "note": "routine known pay"
}

user_id = "user2@upi"

def ensure_user_exists(user_id: str):
    db = SessionLocal()
    try:
        u = db.query(User).filter(User.user_id == user_id).first()
        if not u:
            u = User(user_id=user_id, email=f"{user_id.replace('@','_')}@example.com", full_name="User Two")
            # seed known_devices to include this device
            u.known_devices = ["dev-known-1"]
            db.add(u)
            db.commit()
            print(f"Created user: {user_id} with known device")
        else:
            # ensure known device present
            kd = u.known_devices or []
            if "dev-known-1" not in kd:
                kd.append("dev-known-1")
                u.known_devices = kd
                db.add(u)
                db.commit()
                print(f"Added known device for user: {user_id}")
            else:
                print(f"User exists and device known: {user_id}")
    finally:
        db.close()

if __name__ == "__main__":
    try:
        init_db()
        ensure_user_exists(user_id)
        out = orchestrator.analyze_transaction(txn, user_id, db=None, save=False)
        print(json.dumps(out, indent=2, default=str))
    except Exception as e:
        print("ERROR:", type(e).__name__, str(e))
        raise
