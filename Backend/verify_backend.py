
import requests
import json
import time

BASE_URL = "http://localhost:8000"

def print_step(msg):
    print(f"\n🔹 {msg}")

def test_backend_health():
    print_step("Checking Backend Health...")
    try:
        response = requests.get(f"{BASE_URL}/docs")
        if response.status_code == 200:
            print("✅ Backend is ONLINE (Docs page accessible)")
        else:
            print(f"❌ Backend returned {response.status_code}")
    except Exception as e:
        print(f"❌ Backend Connection Failed: {e}")

def test_signup():
    print_step("Testing Signup (Auth)...")
    payload = {
        "email": "testuser@example.com",
        "password": "securepassword123",
        "full_name": "Test User",
        "phone": "9876543210"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/auth/signup", json=payload)
        
        if response.status_code == 201:
            print("✅ Signup Successful!")
            data = response.json()
            print(f"   Token received: {data.get('access_token')[:10]}...")
            return data.get('access_token')
        elif response.status_code == 400 and "already registered" in response.text:
            print("✅ Signup Logic Verified (User already exists)")
            # Try login instead
            return login()
        else:
            print(f"❌ Signup Failed: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Signup Request Error: {e}")
        return None

def login():
    print_step("Testing Login...")
    payload = {
        "email": "testuser@example.com",
        "password": "securepassword123"
    }
    try:
        response = requests.post(f"{BASE_URL}/api/auth/login", json=payload)
        if response.status_code == 200:
            print("✅ Login Successful!")
            return response.json().get('access_token')
        else:
            print(f"❌ Login Failed: {response.text}")
            return None
    except:
        return None

def test_risk_engine(token):
    print_step("Testing Risk Engine (The 'Brain')...")
    
    headers = {"Authorization": f"Bearer {token}"}
    payload = {
        "amount": 50000.0,
        "receiver": "suspicious@upi",
        "note": "Test Transaction",
        "device_id": "device_123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/payment/intent", json=payload, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Risk Engine Response Received!")
            print(f"   Risk Score: {data.get('risk_score')}")
            print(f"   Action: {data.get('action')} (Should likely be WARN or BLOCK for 50k)")
            print(f"   Factors: {data.get('risk_factors')}")
            
            # Verify Breakdown exists
            if 'risk_breakdown' in data:
                print("✅ UI Breakdown Data Present (Matches Frontend Bars)")
        else:
            print(f"❌ Risk Engine Failed: {response.text}")
    except Exception as e:
        print(f"❌ Risk Engine Request Error: {e}")

if __name__ == "__main__":
    print("🚀 Starting Backend Readiness Test...")
    test_backend_health()
    token = test_signup()
    if token:
        test_risk_engine(token)
    print("\n✅ Test Complete.")
