
import requests
import json

BASE_URL = "http://localhost:8000/api"
DEMO_TOKEN = "demo-token"

def check_api():
    print(f"--- CHECKING API: {BASE_URL} ---")
    
    # 1. Check Health
    try:
        resp = requests.get(f"{BASE_URL}/payment/health")
        print(f"Health: {resp.status_code} - {resp.json()}")
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return

    # 2. Get Transaction History
    print("\n--- FETCHING HISTORY ---")
    headers = {"Authorization": f"Bearer {DEMO_TOKEN}"}
    try:
        resp = requests.get(f"{BASE_URL}/payment/history", headers=headers)
        if resp.status_code == 200:
            history = resp.json()
            print(f"✅ History Count: {len(history)}")
            for txn in history[:5]: # Print first 5
                print(f"- {txn.get('timestamp')} | {txn.get('receiver')} | ₹{txn.get('amount')}")
        else:
            print(f"❌ History Fetch Failed: {resp.status_code} - {resp.text}")
            
    except Exception as e:
        print(f"❌ History request failed: {e}")

if __name__ == "__main__":
    check_api()
