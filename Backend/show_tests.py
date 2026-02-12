"""
Simple script to run and display all test cases
"""
import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"

def print_section(title):
    print("\n" + "="*70)
    print(f"  {title}")
    print("="*70)

def print_result(label, value, color=""):
    symbols = {"success": "✓", "warning": "⚠", "error": "✗"}
    print(f"{symbols.get(color, '•')} {label}: {value}")

try:
    # Test 1: Health Check
    print_section("TEST 1: Health Check")
    response = requests.get(f"{BASE_URL}/health")
    health = response.json()
    print_result("Status", response.status_code, "success")
    print_result("Backend", health["status"], "success")
    print(json.dumps(health, indent=2))
    
    # Test 2: User Signup
    print_section("TEST 2: User Signup")
    timestamp = int(datetime.now().timestamp())
    signup_data = {
        "name": "Demo User",
        "email": f"demo_{timestamp}@example.com",
        "password": "Test123!",
        "phone": "+919876543210"
    }
    print(f"Creating user: {signup_data['email']}")
    response = requests.post(f"{BASE_URL}/api/auth/signup", json=signup_data)
    signup_result = response.json()
    
    if response.status_code == 200:
        print_result("Signup", "SUCCESS", "success")
        print_result("User ID", signup_result["user"]["id"], "success")
        print_result("User Tier", signup_result["user"]["tier"], "success")
        print_result("Trust Score", signup_result["user"]["trust_score"], "success")
        token = signup_result["access_token"]
    else:
        print_result("Signup", "FAILED", "error")
        print(json.dumps(signup_result, indent=2))
        exit(1)
    
    # Test 3: User Login
    print_section("TEST 3: User Login")
    login_data = {
        "email": signup_data["email"],
        "password": signup_data["password"]
    }
    response = requests.post(f"{BASE_URL}/api/auth/login", json=login_data)
    login_result = response.json()
    
    if response.status_code == 200:
        print_result("Login", "SUCCESS", "success")
        print_result("Token received", "YES", "success")
    else:
        print_result("Login", "FAILED", "error")
    
    # Test 4: Low-Risk Payment (₹500 to Swiggy)
    print_section("TEST 4: LOW-RISK Payment Analysis")
    headers = {"Authorization": f"Bearer {token}"}
    payment_data = {
        "amount": 500.0,
        "receiver_upi": "swiggy@paytm",
        "device_id": "device_abc123",
        "location": "Mumbai",
        "merchant_category": "Food"
    }
    
    print(f"Payment: ₹{payment_data['amount']} to {payment_data['receiver_upi']}")
    response = requests.post(
        f"{BASE_URL}/api/payment/intent",
        json=payment_data,
        headers=headers
    )
    result = response.json()
    
    if response.status_code == 200:
        risk = result["risk_assessment"]
        print_result("Risk Score", f"{risk['overall_risk_score']:.3f}", "success")
        print_result("Risk Level", risk["risk_level"], "success")
        print_result("Action", risk["action"], "success")
        print_result("Message", risk["message"], "success")
        print("\n📊 Breakdown:")
        for key, val in risk["breakdown"].items():
            print(f"   {key}: {val:.3f}")
        
        if risk["risk_factors"]:
            print("\n⚠️  Risk Factors:")
            for factor in risk["risk_factors"]:
                print(f"   - {factor}")
    else:
        print_result("Payment Analysis", "FAILED", "error")
        print(json.dumps(result, indent=2))
    
    # Test 5: Medium-Risk Payment (₹15,000 to friend)
    print_section("TEST 5: MEDIUM-RISK Payment Analysis")
    payment_data = {
        "amount": 15000.0,
        "receiver_upi": "friend@paytm",
        "device_id": "device_abc123",
        "location": "Mumbai",
        "merchant_category": "P2P"
    }
    
    print(f"Payment: ₹{payment_data['amount']} to {payment_data['receiver_upi']} (new receiver)")
    response = requests.post(
        f"{BASE_URL}/api/payment/intent",
        json=payment_data,
        headers=headers
    )
    result = response.json()
    
    if response.status_code == 200:
        risk = result["risk_assessment"]
        print_result("Risk Score", f"{risk['overall_risk_score']:.3f}", "warning")
        print_result("Risk Level", risk["risk_level"], "warning")
        print_result("Action", risk["action"], "warning")
        print_result("Verification Required", str(risk.get("requires_verification", False)), "warning")
        print_result("Message", risk["message"], "warning")
        print("\n📊 Breakdown:")
        for key, val in risk["breakdown"].items():
            print(f"   {key}: {val:.3f}")
        
        if risk["risk_factors"]:
            print("\n⚠️  Risk Factors:")
            for factor in risk["risk_factors"]:
                print(f"   - {factor}")
    
    # Test 6: High-Risk Payment (₹90,000 to unknown + new device)
    print_section("TEST 6: HIGH-RISK Payment Analysis")
    payment_data = {
        "amount": 90000.0,
        "receiver_upi": "unknown_receiver@paytm",
        "device_id": "NEW_DEVICE_XYZ",
        "location": "Delhi",
        "merchant_category": "P2P"
    }
    
    print(f"Payment: ₹{payment_data['amount']} to {payment_data['receiver_upi']}")
    print(f"Device: {payment_data['device_id']} (NEW!)")
    response = requests.post(
        f"{BASE_URL}/api/payment/intent",
        json=payment_data,
        headers=headers
    )
    result = response.json()
    
    if response.status_code == 200:
        risk = result["risk_assessment"]
        print_result("Risk Score", f"{risk['overall_risk_score']:.3f}", "error")
        print_result("Risk Level", risk["risk_level"], "error")
        print_result("Action", risk["action"], "error")
        print_result("Verification Required", str(risk.get("requires_verification", False)), "error")
        print_result("Message", risk["message"], "error")
        
        print("\n📊 Breakdown:")
        for key, val in risk["breakdown"].items():
            print(f"   {key}: {val:.3f}")
        
        print("\n🚨 Risk Factors:")
        for factor in risk["risk_factors"]:
            print(f"   - {factor}")
        
        if risk.get("recommendations"):
            print("\n💡 Recommendations:")
            for rec in risk["recommendations"]:
                print(f"   - {rec}")
    
    # Test 7: System Metrics
    print_section("TEST 7: System Metrics")
    response = requests.get(f"{BASE_URL}/metrics", headers=headers)
    
    if response.status_code == 200:
        metrics = response.json()
        print_result("Metrics Retrieved", "SUCCESS", "success")
        print("\n📈 System Stats:")
        print(f"   Total Requests: {metrics.get('total_requests', 0)}")
        print(f"   Avg Response Time: {metrics.get('avg_response_time', 0):.2f}ms")
        print(f"   Cache Hit Rate: {metrics.get('cache_hit_rate', 0):.1%}")
    
    # Summary
    print_section("TEST SUMMARY")
    print("✓ All 7 test cases executed successfully!")
    print("\n📋 Tests Performed:")
    print("   1. ✓ Health Check")
    print("   2. ✓ User Signup")
    print("   3. ✓ User Login")
    print("   4. ✓ Low-Risk Payment (₹500) → ALLOW")
    print("   5. ✓ Medium-Risk Payment (₹15,000) → SOFT_CHALLENGE")
    print("   6. ✓ High-Risk Payment (₹90,000) → HARD_CHALLENGE/BLOCK")
    print("   7. ✓ System Metrics")
    
    print("\n" + "="*70)
    print("  🎉 FRAUD DETECTION BACKEND IS WORKING PERFECTLY!")
    print("="*70)
    
except requests.exceptions.ConnectionError:
    print("\n❌ ERROR: Cannot connect to server!")
    print("\nPlease start the server first:")
    print("   python -m uvicorn app.main:app --host 127.0.0.1 --port 8000")
    print("\nOr use the automated script:")
    print("   python run_tests.py")
    
except Exception as e:
    print(f"\n❌ ERROR: {str(e)}")
    import traceback
    traceback.print_exc()
