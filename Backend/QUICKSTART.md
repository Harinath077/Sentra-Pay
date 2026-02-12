# 🚀 Quick Start Guide - Run & Test Your Fraud Detection Backend

## Option 1: Automated Testing (Easiest!)

### Step 1: Run the automated test script
```powershell
python run_tests.py
```

**What this does:**
- ✅ Starts the server automatically
- ✅ Waits for it to be ready
- ✅ Runs complete flow tests
- ✅ Cleans up when done

**Expected output:**
```
Starting server...
⏳ Waiting for server to be ready...
✓ Server is ready!

🧪 FRAUD DETECTION BACKEND - COMPLETE FLOW TEST
======================================================================

1. Health Check
   Status: 200
   ✓ Backend is healthy

2. User Signup
   Creating user: testuser_123@example.com
   ✓ Signup successful!

3. User Login
   ✓ Login successful! Got token.

4. Low-Risk Payment (₹500 to known merchant)
   Risk Score: 0.15
   Risk Level: LOW
   Action: ALLOW
   ✓ Payment approved!

5. High-Risk Payment (₹90,000 to unknown receiver)
   Risk Score: 0.78
   Risk Level: HIGH
   Action: HARD_CHALLENGE
   ✓ Verification required (as expected)

6. System Metrics
   ✓ Metrics retrieved

All tests completed! ✓
```

---

## Option 2: Manual Testing (More Control)

### Step 1: Start the Server

Open **PowerShell** in `d:\fraud-detection-backend\` and run:

```powershell
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

**Expected output:**
```
⚠ Redis not available: Timeout connecting to server
  System will run without caching (slower performance)
CatBoost not installed. Using fallback predictions.
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
🚀 Starting Fraud Detection Backend
✓ Database tables created/verified
✓ Fraud Detection Backend v1.0.0 started
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000
```

**Server is now running! ✓**

### Step 2: Test the API

**Open a NEW PowerShell window** (keep server running in first window!)

#### Test 1: Health Check
```powershell
python -c "import requests, json; r = requests.get('http://127.0.0.1:8000/health'); print(json.dumps(r.json(), indent=2))"
```

**Expected response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "components": {
    "database": {"status": "healthy"},
    "redis": {"status": "degraded"},
    "ml_model": {"status": "degraded"}
  }
}
```

#### Test 2: Run Complete Flow Test
```powershell
python test_complete_flow.py
```

**This will test:**
- ✅ User signup
- ✅ User login
- ✅ Low-risk payment (₹500)
- ✅ High-risk payment (₹90,000)
- ✅ System metrics

### Step 3: Stop the Server

Go back to the first PowerShell window and press:
```
Ctrl + C
```

---

## Option 3: Interactive API Testing (Using Browser)

### Step 1: Start the Server
```powershell
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

### Step 2: Open Swagger UI

Open your browser and go to:
```
http://127.0.0.1:8000/docs
```

**You'll see an interactive API documentation!** 🎉

### Step 3: Test Endpoints Visually

**Try this flow:**

1. **POST /api/auth/signup** - Create a user
   ```json
   {
     "name": "Test User",
     "email": "test@example.com",
     "password": "Test123!",
     "phone": "+919876543210"
   }
   ```
   → Copy the `access_token` from response

2. **Click "Authorize" 🔓** (top right)
   - Enter: `Bearer YOUR_TOKEN_HERE`
   - Click "Authorize"

3. **POST /api/payment/intent** - Test payment analysis
   ```json
   {
     "amount": 500,
     "receiver_upi": "merchant@paytm",
     "device_id": "device123",
     "location": "Mumbai",
     "merchant_category": "Food"
   }
   ```
   → See the risk analysis!

4. Try a **risky payment:**
   ```json
   {
     "amount": 95000,
     "receiver_upi": "unknown@paytm",
     "device_id": "new_device_xyz",
     "location": "Delhi",
     "merchant_category": "P2P"
   }
   ```
   → Should get HIGH risk score!

---

## Option 4: Using Python Requests (Programmatic)

Create a file `manual_test.py`:

```python
import requests
import json

BASE_URL = "http://127.0.0.1:8000"

# 1. Signup
signup_data = {
    "name": "Manual Test User",
    "email": "manual@example.com",
    "password": "Test123!",
    "phone": "+919999999999"
}

print("1. Creating user...")
response = requests.post(f"{BASE_URL}/api/auth/signup", json=signup_data)
result = response.json()
print(f"   Status: {response.status_code}")
print(f"   User: {result['user']['email']}")

# Get token
token = result['access_token']
headers = {"Authorization": f"Bearer {token}"}

# 2. Test low-risk payment
print("\n2. Testing LOW-RISK payment (₹500 to Swiggy)...")
payment_data = {
    "amount": 500,
    "receiver_upi": "swiggy@paytm",
    "device_id": "device123",
    "location": "Mumbai",
    "merchant_category": "Food"
}

response = requests.post(
    f"{BASE_URL}/api/payment/intent",
    json=payment_data,
    headers=headers
)
result = response.json()
print(f"   Risk Score: {result['risk_assessment']['overall_risk_score']:.2f}")
print(f"   Risk Level: {result['risk_assessment']['risk_level']}")
print(f"   Action: {result['risk_assessment']['action']}")
print(f"   Message: {result['risk_assessment']['message']}")

# 3. Test high-risk payment
print("\n3. Testing HIGH-RISK payment (₹90,000 to unknown)...")
payment_data = {
    "amount": 90000,
    "receiver_upi": "unknown@paytm",
    "device_id": "new_device_xyz",
    "location": "Delhi",
    "merchant_category": "P2P"
}

response = requests.post(
    f"{BASE_URL}/api/payment/intent",
    json=payment_data,
    headers=headers
)
result = response.json()
print(f"   Risk Score: {result['risk_assessment']['overall_risk_score']:.2f}")
print(f"   Risk Level: {result['risk_assessment']['risk_level']}")
print(f"   Action: {result['risk_assessment']['action']}")
print(f"   Message: {result['risk_assessment']['message']}")
print(f"   Risk Factors:")
for factor in result['risk_assessment']['risk_factors']:
    print(f"      - {factor}")

print("\n✓ All tests completed!")
```

Then run:
```powershell
python manual_test.py
```

---

## 📊 Understanding the Output

### Risk Levels Explained

| Risk Score | Level | Action | What User Sees |
|------------|-------|--------|----------------|
| 0.00 - 0.30 | LOW | ✅ ALLOW | "Payment approved!" |
| 0.30 - 0.60 | MODERATE | ⚠️ SOFT_CHALLENGE | "Enter OTP" |
| 0.60 - 0.80 | HIGH | ⚠️ HARD_CHALLENGE | "Enter OTP + Verify call" |
| 0.80 - 1.00 | VERY_HIGH | 🚫 BLOCK | "Transaction blocked" |

### Example Output Analysis

```json
{
  "risk_assessment": {
    "overall_risk_score": 0.78,  // HIGH RISK!
    "risk_level": "HIGH",
    "action": "HARD_CHALLENGE",
    "requires_verification": true,
    "message": "⚠️ Additional verification required",
    
    "breakdown": {
      "behavior_score": 0.60,    // User behavior analysis
      "amount_score": 0.85,      // Amount anomaly
      "receiver_score": 0.70,    // Receiver reputation
      "ml_score": 0.87           // ML prediction
    },
    
    "risk_factors": [
      "Amount 112x higher than average",
      "New receiver detected",
      "Device change detected"
    ],
    
    "recommendations": [
      "This payment is significantly higher than your usual amount.",
      "First time paying this receiver - verify UPI ID carefully.",
      "If you didn't initiate this, contact support: 1800-XXX-XXXX"
    ]
  }
}
```

**What this means:**
- ⚠️ **Risk Score 0.78** = HIGH risk (near blocking threshold!)
- 🔍 **Main issues**: Huge amount (112x average), new receiver, new device
- 🛡️ **Action**: Request OTP + phone verification before allowing
- 💡 **ML Score 0.87**: Machine learning is 87% confident this is fraud

---

## 🔍 Troubleshooting

### Issue: "Port 8000 is already in use"

**Solution 1:** Kill existing process
```powershell
# Find and kill Python processes
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
```

**Solution 2:** Use different port
```powershell
python -m uvicorn app.main:app --host 127.0.0.1 --port 8001
```

### Issue: "Module not found: requests"

**Solution:** Install dependencies
```powershell
pip install -r requirements.txt
```

### Issue: "Redis connection failed"

**This is normal!** ✓ System works without Redis (just slower)

The warning means:
```
⚠ Redis not available: Timeout connecting to server
  System will run without caching (slower performance)
```

To enable Redis (optional):
1. Download Redis for Windows
2. Run `redis-server`
3. Restart backend

### Issue: "CatBoost not installed"

**This is normal!** ✓ System uses fallback predictions

To enable ML model (optional):
```powershell
pip install catboost
```

---

## 📝 Quick Command Reference

```powershell
# Start server
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000

# Run automated tests
python run_tests.py

# Run manual tests
python test_complete_flow.py

# Check health
python -c "import requests; print(requests.get('http://127.0.0.1:8000/health').json())"

# View API docs (in browser)
# http://127.0.0.1:8000/docs

# Stop server
# Press Ctrl + C in server window
```

---

## 🎯 What to Try

### Experiment 1: Amount Changes
Change amount in test and see risk score change:
- ₹100 → Low risk (~0.05)
- ₹5,000 → Moderate risk (~0.35)
- ₹50,000 → High risk (~0.65)
- ₹95,000 → Very high risk (~0.85)

### Experiment 2: New vs Known Receiver
- Same receiver multiple times → Risk decreases
- New receiver every time → Risk stays high

### Experiment 3: Trust Score Impact
Modify user trust score in database:
```sql
UPDATE users SET trust_score = 85 WHERE id = 1;  -- GOLD tier
```
Same transaction will have lower risk!

### Experiment 4: Time of Day
Try payment at different times:
- 2 PM → Normal
- 2 AM → +0.10 risk score (suspicious time)

---

## ✅ Success Checklist

After running tests, you should see:

- [x] Server starts without errors
- [x] Health endpoint returns 200 OK
- [x] User signup works
- [x] User login returns JWT token
- [x] Low-risk payment gets ALLOW action
- [x] High-risk payment gets HARD_CHALLENGE/BLOCK
- [x] Risk scores are between 0.0 and 1.0
- [x] Breakdown shows behavior/amount/receiver/ML scores
- [x] Risk factors list makes sense
- [x] Recommendations are helpful
- [x] Processing time < 300ms

**If all checked → System is working perfectly! 🎉**

---

## 🎓 Next Steps

Now that it's running:

1. **Read the Learning Guide** → [LEARNING_GUIDE.md](LEARNING_GUIDE.md)
2. **Understand the code** → Start with [app/main.py](app/main.py)
3. **Modify fraud rules** → [app/core/rules_engine.py](app/core/rules_engine.py)
4. **Add new features** → Check [API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)
5. **Deploy to production** → Add Docker, configure PostgreSQL

---

**Questions? Issues? Check the logs in the terminal where server is running!**
