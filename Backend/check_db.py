
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Start with the credentials that seemingly worked for connection (postgres)
DATABASE_URL = "postgresql://postgres:sentra_secure_2026@localhost:5432/fraud_detection"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

def check_data():
    print("\n--- CHECKING USER (Raw SQL) ---")
    try:
        # Fetch ID and User_ID
        result = db.execute(text("SELECT id, user_id, email, trust_score FROM users WHERE email = 'demo@sentra.app'"))
        user = result.fetchone()
        
        if not user:
            print("❌ Demo user 'demo@sentra.app' NOT found!")
            print("Listing first 5 users:")
            users = db.execute(text("SELECT id, user_id, email FROM users LIMIT 5"))
            for u in users:
                print(u)
            return

        print(f"✅ Demo User Found: ID={user[0]}, UserID={user[1]}, TrustScore={user[3]}")
        user_pk = user[0]

        print("\n--- CHECKING TRANSACTIONS (Last 5) ---")
        txns = db.execute(text(f"SELECT transaction_id, receiver, amount, status, created_at FROM transactions WHERE user_id = {user_pk} ORDER BY created_at DESC LIMIT 5"))
        txns_list = txns.fetchall()
        
        if not txns_list:
            print("❌ No transactions found for user.")
        else:
            for t in txns_list:
                print(f"- [{t[3]}] {t[0]} | {t[1]} | {t[2]} | {t[4]}")

        print("\n--- CHECKING RECEIVER HISTORY ---")
        history = db.execute(text(f"SELECT receiver_upi, payment_count, total_amount, last_paid_at FROM receiver_history WHERE user_id = {user_pk}"))
        history_list = history.fetchall()
        
        if not history_list:
            print("❌ No receiver history found.")
        else:
            for h in history_list:
                print(f"- {h[0]}: Count={h[1]}, Total={h[2]}, LastPaid={h[3]}")
                
    except Exception as e:
        print(f"Error executing raw SQL: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_data()
