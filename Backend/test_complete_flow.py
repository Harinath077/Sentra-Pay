"""
Complete End-to-End Test Script
Tests the entire fraud detection flow from signup to payment analysis.
"""

import requests
import json
import time
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8000"
TEST_EMAIL = f"testuser_{int(time.time())}@example.com"
TEST_PASSWORD = "Test123!"  # Shorter password to avoid bcrypt 72 byte limit


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
        print(json.dumps(response.json(), indent=2))
    except:
        print(response.text)


def test_health_check():
    """Test health check endpoint."""
    print_section("1. Health Check")
    
    response = requests.get(f"{BASE_URL}/health")
    print_response(response, "Health Status")
    
    if response.status_code == 200:
        print("✓ Backend is healthy")
        return True
    else:
        print("✗ Backend is not healthy")
        return False


def test_signup():
    """Test user signup."""
    print_section("2. User Signup")
    
    signup_data = {
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD,
        "full_name": "Test User",
        "phone": "+919876543210"
    }
    
    print(f"Creating user: {TEST_EMAIL}")
    response = requests.post(f"{BASE_URL}/api/auth/signup", json=signup_data)
    print_response(response, "Signup Response")
    
    if response.status_code == 201:
        data = response.json()
        print(f"✓ User created: {data['user_id']}")
        print(f"  Trust Score: {data['trust_score']}")
        print(f"  Risk Tier: {data['risk_tier']}")
        return data["token"]
    else:
        print("✗ Signup failed")
        return None


def test_login():
    """Test user login."""
    print_section("3. User Login")
    
    login_data = {
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    }
    
    print(f"Logging in: {TEST_EMAIL}")
    response = requests.post(f"{BASE_URL}/api/auth/login", json=login_data)
    print_response(response, "Login Response")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✓ Login successful")
        print(f"  Token expires in: {data['expires_in']} seconds")
        return data["token"]
    else:
        print("✗ Login failed")
        return None


def test_payment_intent_low_risk(token):
    """Test payment intent with low risk transaction."""
    print_section("4. Payment Intent - Low Risk Transaction")
    
    payment_data = {
        "amount": 50000,  # ₹500
        "receiver": "known@upi",
        "note": "Small test payment",
        "device_id": "device-123"
    }
    
    headers = {"Authorization": f"Bearer {token}"}
    
    print(f"Analyzing transaction: ₹{payment_data['amount']/100:.2f}")
    response = requests.post(
        f"{BASE_URL}/api/payment/intent",
        json=payment_data,
        headers=headers
    )
    print_response(response, "Risk Analysis")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\n✓ Risk Analysis Complete:")
        print(f"  Transaction ID: {data['transaction_id']}")
        print(f"  Risk Score: {data['risk_score']:.2f} ({data['risk_percentage']}%)")
        print(f"  Risk Level: {data['risk_level']}")
        print(f"  Action: {data['action']}")
        print(f"  Can Proceed: {data['can_proceed']}")
        print(f"  Requires OTP: {data['requires_otp']}")
        
        print(f"\n  Risk Breakdown:")
        for category, details in data['risk_breakdown'].items():
            print(f"    {category}: {details['score']}/100 (weight: {details['weight']}%)")
        
        print(f"\n  Risk Factors ({len(data['risk_factors'])}):")
        for factor in data['risk_factors']:
            print(f"    - [{factor['severity'].upper()}] {factor['factor']}")
        
        return True
    else:
        print("✗ Payment intent failed")
        return False


def test_payment_intent_high_risk(token):
    """Test payment intent with high risk transaction."""
    print_section("5. Payment Intent - High Risk Transaction")
    
    payment_data = {
        "amount": 9000000,  # ₹90,000 (high amount)
        "receiver": "unknown@upi",  # New receiver
        "note": "Large payment to new receiver",
        "device_id": "new-device-456"  # New device
    }
    
    headers = {"Authorization": f"Bearer {token}"}
    
    print(f"Analyzing HIGH RISK transaction: ₹{payment_data['amount']/100:.2f}")
    response = requests.post(
        f"{BASE_URL}/api/payment/intent",
        json=payment_data,
        headers=headers
    )
    print_response(response, "Risk Analysis")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\n✓ Risk Analysis Complete:")
        print(f"  Transaction ID: {data['transaction_id']}")
        print(f"  Risk Score: {data['risk_score']:.2f} ({data['risk_percentage']}%)")
        print(f"  Risk Level: {data['risk_level']}")
        print(f"  Action: {data['action']}")
        print(f"  Message: {data['message']}")
        
        print(f"\n  Risk Breakdown:")
        for category, details in data['risk_breakdown'].items():
            print(f"    {category}: {details['score']}/100")
        
        print(f"\n  Recommendations ({len(data['recommendations'])}):")
        for rec in data['recommendations']:
            print(f"    - {rec}")
        
        print(f"\n  Debug Info:")
        print(f"    Rule Score: {data['debug']['rule_score']}")
        print(f"    ML Score: {data['debug']['ml_score']}")
        print(f"    Flags: {', '.join(data['debug']['flags'])}")
        print(f"    Model: {data['debug']['model_version']}")
        
        return True
    else:
        print("✗ Payment intent failed")
        return False


def test_metrics():
    """Test metrics endpoint."""
    print_section("6. System Metrics")
    
    response = requests.get(f"{BASE_URL}/metrics")
    print_response(response, "Metrics")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\n✓ Metrics Retrieved:")
        print(f"  Cache Hit Rate: {data['cache'].get('hit_rate', 'N/A')}")
        print(f"  Cache Hits: {data['cache'].get('hits', 0)}")
        print(f"  Cache Misses: {data['cache'].get('misses', 0)}")
        return True
    else:
        print("✗ Metrics failed")
        return False


def main():
    """Run complete test flow."""
    print("\n" + "🧪" * 35)
    print("  FRAUD DETECTION BACKEND - COMPLETE FLOW TEST")
    print("🧪" * 35)
    print(f"\nTimestamp: {datetime.utcnow().isoformat()}")
    print(f"Base URL: {BASE_URL}")
    
    results = {
        "health": False,
        "signup": False,
        "login": False,
        "low_risk_payment": False,
        "high_risk_payment": False,
        "metrics": False
    }
    
    # Test 1: Health Check
    results["health"] = test_health_check()
    if not results["health"]:
        print("\n❌ Backend is not healthy. Stopping tests.")
        return
    
    # Test 2: Signup
    token = test_signup()
    if token:
        results["signup"] = True
    else:
        print("\n❌ Signup failed. Stopping tests.")
        return
    
    # Test 3: Login
    token = test_login()
    if token:
        results["login"] = True
    else:
        print("\n⚠️  Login failed, but continuing with signup token")
    
    # Test 4: Low Risk Payment
    results["low_risk_payment"] = test_payment_intent_low_risk(token)
    
    # Test 5: High Risk Payment
    results["high_risk_payment"] = test_payment_intent_high_risk(token)
    
    # Test 6: Metrics
    results["metrics"] = test_metrics()
    
    # Summary
    print_section("TEST SUMMARY")
    total = len(results)
    passed = sum(results.values())
    
    print(f"\nResults: {passed}/{total} tests passed")
    for test_name, passed in results.items():
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"  {status} - {test_name}")
    
    if passed == total:
        print("\n🎉 ALL TESTS PASSED!")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
    
    print("\n" + "=" * 70 + "\n")


if __name__ == "__main__":
    main()
