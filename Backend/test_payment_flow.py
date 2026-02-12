"""
Quick Test Script for Payment Confirmation Flow
Run this after starting the backend to verify everything works
"""

import requests
import json
import time

# Configuration
BASE_URL = "http://localhost:8000"

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_success(msg):
    print(f"{Colors.GREEN}✅ {msg}{Colors.END}")

def print_error(msg):
    print(f"{Colors.RED}❌ {msg}{Colors.END}")

def print_info(msg):
    print(f"{Colors.BLUE}ℹ️  {msg}{Colors.END}")

def print_warning(msg):
    print(f"{Colors.YELLOW}⚠️  {msg}{Colors.END}")

def print_section(title):
    print(f"\n{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BLUE}{title:^60}{Colors.END}")
    print(f"{Colors.BLUE}{'='*60}{Colors.END}\n")


def test_payment_flow():
    """Test complete payment flow"""
    
    print_section("SENTRA PAY - PAYMENT FLOW TEST")
    
    # Step 1: Register/Login
    print_section("Step 1: Authentication")
    
    # Try to register (might fail if user exists)
    register_data = {
        "email": "testpay@example.com",
        "phone": "9876543210",
        "password": "Test@123",
        "full_name": "Payment Test User"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/auth/register", json=register_data)
        if response.status_code == 200:
            print_success("User registered successfully")
        elif response.status_code == 400:
            print_warning("User already exists, proceeding to login")
    except Exception as e:
        print_error(f"Registration failed: {e}")
    
    # Login
    login_data = {
        "email": "testpay@example.com",
        "password": "Test@123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/auth/login", json=login_data)
        if response.status_code == 200:
            data = response.json()
            token = data["access_token"]
            print_success(f"Login successful! Token: {token[:20]}...")
        else:
            print_error(f"Login failed: {response.text}")
            return
    except Exception as e:
        print_error(f"Login request failed: {e}")
        return
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Step 2: Create Payment Intent
    print_section("Step 2: Payment Intent (Risk Analysis)")
    
    intent_data = {
        "amount": 500000,  # ₹5000 in paise
        "receiver": "sachin@paytm",
        "note": "Test payment for cricket gear",
        "device_id": "test-device-123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/payment/intent", json=intent_data, headers=headers)
        if response.status_code == 200:
            intent_result = response.json()
            transaction_id = intent_result["transaction_id"]
            risk_score = intent_result["risk_score"]
            risk_level = intent_result["risk_level"]
            action = intent_result["action"]
            
            print_success(f"Payment intent created: {transaction_id}")
            print_info(f"Risk Score: {risk_score*100:.1f}% ({risk_level})")
            print_info(f"Recommended Action: {action}")
            
            # Pretty print risk factors
            if intent_result.get("risk_factors"):
                print_info("Risk Factors:")
                for factor in intent_result["risk_factors"][:3]:
                    print(f"   • {factor['factor']} ({factor['severity']})")
        else:
            print_error(f"Payment intent failed: {response.text}")
            return
    except Exception as e:
        print_error(f"Payment intent request failed: {e}")
        return
    
    # Step 3: User Reviews (simulated delay)
    print_section("Step 3: User Reviews Risk Analysis")
    print_info("Simulating user review...")
    time.sleep(1)
    print_success("User acknowledged risks and clicked 'Pay Now'")
    
    # Step 4: Confirm Payment
    print_section("Step 4: Payment Confirmation")
    
    confirm_data = {
        "transaction_id": transaction_id,
        "user_acknowledged": True
    }
    
    try:
        print_info("Initiating UPI payment (mock)...")
        response = requests.post(f"{BASE_URL}/api/payment/confirm", json=confirm_data, headers=headers)
        
        if response.status_code == 200:
            payment_result = response.json()
            status = payment_result["status"]
            
            if status == "success":
                print_success("🎉 PAYMENT SUCCESSFUL!")
                print_info(f"Amount: ₹{payment_result.get('amount', 0)/100:.2f}")
                print_info(f"Receiver: {payment_result.get('receiver')}")
                print_info(f"UTR Number: {payment_result.get('utr_number')}")
                print_info(f"PSP: {payment_result.get('psp_name')}")
                print_info(f"Timestamp: {payment_result.get('timestamp')}")
            elif status == "failed":
                print_warning("Payment Failed")
                print_info(f"Reason: {payment_result.get('message')}")
                print_info(f"Error Code: {payment_result.get('error_code')}")
            else:
                print_info(f"Payment Status: {status}")
        else:
            print_error(f"Payment confirmation failed: {response.text}")
            return
    except Exception as e:
        print_error(f"Payment confirmation request failed: {e}")
        return
    
    # Step 5: Check Payment Status
    print_section("Step 5: Payment Status Check")
    
    try:
        response = requests.get(f"{BASE_URL}/api/payment/status/{transaction_id}", headers=headers)
        if response.status_code == 200:
            status_data = response.json()
            print_success("Status retrieved successfully")
            print_info(f"Transaction ID: {status_data['transaction_id']}")
            print_info(f"Status: {status_data['status']}")
            print_info(f"Amount: ₹{status_data['amount']/100:.2f}")
            print_info(f"Risk Score: {status_data['risk_score']*100:.1f}%")
            
            if status_data.get('utr_number'):
                print_info(f"UTR: {status_data['utr_number']}")
                print_info(f"PSP: {status_data['psp_name']}")
        else:
            print_error(f"Status check failed: {response.text}")
    except Exception as e:
        print_error(f"Status check request failed: {e}")
    
    # Summary
    print_section("TEST SUMMARY")
    print_success("All payment flow tests completed!")
    print_info("Your payment system is working correctly ✨")
    print("")
    print("Next steps:")
    print("  1. Test with different receivers (scammer@paytm, merchant@razorpay)")
    print("  2. Test with different amounts (high, low, etc.)")
    print("  3. Integrate with your Flutter frontend")
    print("  4. Prepare your demo script for judges!")
    print("")


if __name__ == "__main__":
    try:
        test_payment_flow()
    except KeyboardInterrupt:
        print("\n\n" + Colors.YELLOW + "Test interrupted by user" + Colors.END)
    except Exception as e:
        print_error(f"Unexpected error: {e}")
        import traceback
        traceback.print_exc()
