import json
from app.core.risk_orchestrator import orchestrator
from app.database.connection import init_db, SessionLocal
from app.database.models import User

txn = {
    "receiver": "recv2@upi",
    "amount": 100,
    "note": "minimal test"
}

user_id = "user2@upi"

def ensure_user_exists(user_id: str):
    db = SessionLocal()
    try:
        u = db.query(User).filter(User.user_id == user_id).first()
        if not u:
            u = User(user_id=user_id, email=f"{user_id.replace('@','_')}@example.com", full_name="User Two")
            db.add(u)
            db.commit()
            print(f"Created user: {user_id}")
        else:
            print(f"User exists: {user_id}")
    finally:
        db.close()


if __name__ == "__main__":
    init_db()
    ensure_user_exists(user_id)
    out = orchestrator.analyze_transaction(txn, user_id, db=None, save=False)
    print(json.dumps(out, indent=2, default=str))
