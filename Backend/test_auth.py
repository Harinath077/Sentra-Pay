import requests
import json

base_url = "http://localhost:8000/api/auth"

def test_signup():
    print("\n--- Testing Signup ---")
    data = {
        "email": "tester_final@sentra.app",
        "password": "strongpassword123",
        "full_name": "Final Tester",
        "phone": "1234567890"
    }
    try:
        response = requests.post(f"{base_url}/signup", json=data)
        print(f"Status Code: {response.statusCode if hasattr(response, 'statusCode') else response.status_code}")
        print(f"Response: {response.text}")
        return response.json() if response.status_code == 201 else None
    except Exception as e:
        print(f"Signup Error: {e}")
        return None

def test_login(email, password):
    print("\n--- Testing Login ---")
    data = {
        "email": email,
        "password": password
    }
    try:
        response = requests.post(f"{base_url}/login", json=data)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        return response.json() if response.status_code == 200 else None
    except Exception as e:
        print(f"Login Error: {e}")
        return None

if __name__ == "__main__":
    signup_res = test_signup()
    if signup_res or True: # Try login anyway if signup failed because of "already exists"
        test_login("tester_final@sentra.app", "strongpassword123")
