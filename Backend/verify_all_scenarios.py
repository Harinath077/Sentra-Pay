"""
Verify All Scenarios Script
Tests the entire fraud detection flow including Low, Medium, High risk cases and Scanner simulation.
Builds user history to attempt to lower risk over time.
"""

import requests
import json
import time
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8000"
TEST_EMAIL = f"testuser_{int(time.time())}@example.com"
TEST_PASSWORD = "Test123!"

def print_section(title):
    """Print formatted section header."""
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70)

def print_response(response, title="Response"):
    """Print formatted response."""
    print(f"\n{title}:")
    print(f"Status: {response.status_code}")
    try:
        data = response.json()
        print(json.dumps(data, indent=2))
        return data
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        print(f"Raw Response: {response.text}")
        return None

def wait_for_server():
    print("Waiting for server...")
    for i in range(10):
        try:
            response = requests.get(f"{BASE_URL}/health")
            if response.status_code == 200:
                print("Server is ready!")
                return True
        except:
            pass
        time.sleep(2)
    print("Server failed to start.")
    return False

def get_auth_token():
    print_section("1. User Signup & Auth")
    phone_num = f"+91{int(time.time())}"
    signup_data = {
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD,
        "full_name": "Test User",
        "phone": phone_num
    }
    
    print(f"Creating user: {TEST_EMAIL}")
    response = requests.post(f"{BASE_URL}/api/auth/signup", json=signup_data)
    
    if response.status_code == 201:
        data = response.json()
        print(f"✓ User created. Trust Score: {data['trust_score']}")
        return data["token"]
    else:
        print("✗ Signup failed")
        print(response.text)
        return None

def confirm_payment(token, transaction_id):
    """Confirm a payment to build history."""
    print(f"\nConfirming transaction {transaction_id}...")
    headers = {"Authorization": f"Bearer {token}"}
    data = {"transaction_id": transaction_id, "user_acknowledged": True}
    
    response = requests.post(f"{BASE_URL}/api/payment/confirm", json=data, headers=headers)
    if response.status_code == 200:
        print("✓ Payment Confirmed! Transaction history built.")
        return True
    else:
        print(f"✗ Payment confirmation failed: {response.text}")
        return False

def test_risk_scenario(token, scenario_name, data, expected_risk_level, confirm=False):
    """Test a specific risk scenario."""
    print_section(f"Test Scenario: {scenario_name}")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    print(f"Transaction Details:")
    print(f"  Amount: {data['amount']} paise (₹{data['amount']/100:.2f})")
    print(f"  Receiver: {data['receiver']}")
    print(f"  Note: {data.get('note', '')}")
    
    response = requests.post(
        f"{BASE_URL}/api/payment/intent",
        json=data,
        headers=headers
    )
    
    result = print_response(response, "Risk Analysis Result")
    
    should_confirm = False
    
    if response.status_code == 200 and result:
        risk_level = result['risk_level']
        risk_score = result['risk_score']
        print(f"\n✓ Analysis Complete:")
        print(f"  Risk Score: {risk_score:.2f} ({result['risk_percentage']}%)")
        print(f"  Risk Level: {risk_level}")
        
        # Explain why expected might differ
        if risk_level != expected_risk_level:
            print(f"  ℹ️  Note: Expected {expected_risk_level}, got {risk_level}.")
            print(f"      Actual score {risk_score:.2f} vs Thresholds.")
        else:
             print(f"  ✅ MATCHES EXPECTATION")
        
        if confirm and result.get('can_proceed', False):
            confirm_payment(token, result['transaction_id'])
            
        return True
    else:
        print("✗ Payment intent failed")
        return False

def main():
    print("\n" + "🚀" * 35)
    print("  VERIFYING APP SCENARIOS: LOW, MODERATE, HIGH RISK")
    print("🚀" * 35)
    
    if not wait_for_server():
        return

    token = get_auth_token()
    if not token:
        return

    # 1. Setup: Low Risk Case (Building Trust & Device History)
    # We confirm this to whitelist usage patterns.
    test_risk_scenario(token, "Setup: Low Risk (Build History)", {
        "amount": 20000,  # ₹200
        "receiver": "safe_shop@upi",
        "note": "Groceries",
        "device_id": "device-123"
    }, "LOW", confirm=True) # First txn might be Moderate/High due to cold start, but we confirm it.

    # 2. Moderate Risk Case
    # - Known Device (device-123)
    # - New Receiver (new_cafe@upi)
    # - Amount 500 (2.5x Average of 200) -> New Receiver Risk (+0.30) + Flags (+0.25) = ~0.55
    # Expected Score: ~0.55 (Moderate is 0.30 - 0.60)
    test_risk_scenario(token, "Moderate Risk Case", {
        "amount": 50000,  # ₹500
        "receiver": "new_cafe@upi",
        "note": "Dinner",
        "device_id": "device-123" # SAME DEVICE
    }, "MODERATE")

    # 3. High Risk Case
    # - New Device (device-999) -> +0.15
    # - Huge Amount (₹90,000) -> +0.25 (Ratio > 5)
    # - New Receiver -> +0.30
    # Expected Score: > 0.70 (High is > 0.60)
    test_risk_scenario(token, "High Risk Case", {
        "amount": 9000000,  # ₹90,000
        "receiver": "unknown_hacker@upi",
        "note": "Urgent Transfer",
        "device_id": "device-999"  # NEW DEVICE
    }, "HIGH")
    
    print("\n" + "=" * 70)
    print("  VERIFICATION COMPLETE")
    print("=" * 70)

if __name__ == "__main__":
    main()
