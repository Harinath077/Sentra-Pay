# 🧪 All Test Cases Explained

## Overview
The system has **7 comprehensive test cases** that validate the entire fraud detection flow.

---

## Test Case 1: Health Check ✅

**What it does:**
- Checks if the backend server is running
- Validates database connection
- Checks Redis cache status  
- Verifies ML model status

**API Call:**
```http
GET /health
```

**Expected Result:**
```json
{
  "status": "healthy",
  "components": {
    "database": {"status": "healthy"},
    "redis": {"status": "degraded"},  // OK if not running
    "ml_model": {"status": "degraded"}  // OK, uses fallback
  }
}
```

**Pass Criteria:** Status code 200, backend is healthy

---

## Test Case 2: User Signup ✅

**What it does:**
- Creates a new user account
- Generates JWT authentication token
- Assigns initial trust score (0) and tier (BRONZE)

**API Call:**
```http
POST /api/auth/signup
{
  "name": "Test User",
  "email": "testuser_123@example.com",
  "password": "Test123!",
  "phone": "+919876543210"
}
```

**Expected Result:**
```json
{
  "status": "success",
  "user": {
    "id": 1,
    "name": "Test User",
    "email": "testuser_123@example.com",
    "trust_score": 0,
    "tier": "BRONZE"
  },
  "access_token": "eyJhbGci..."
}
```

**Pass Criteria:** User created, token received

---

## Test Case 3: User Login ✅

**What it does:**
- Authenticates existing user
- Verifies password (bcrypt)
- Generates new JWT token

**API Call:**
```http
POST /api/auth/login
{
  "email": "testuser_123@example.com",
  "password": "Test123!"
}
```

**Expected Result:**
```json
{
  "status": "success",
  "user": {
    "id": 1,
    "email": "testuser_123@example.com"
  },
  "access_token": "eyJhbGci...",
  "token_type": "bearer"
}
```

**Pass Criteria:** Login successful, token received

---

## Test Case 4: LOW-RISK Payment (₹500 to Swiggy) ✅

**What it does:**
- Analyzes a normal, safe payment transaction
- Tests the complete Risk Orchestrator flow
- Should result in ALLOW action (smooth UX)

**API Call:**
```http
POST /api/payment/intent
Authorization: Bearer <token>
{
  "amount": 500.0,
  "receiver_upi": "swiggy@paytm",
  "device_id": "device_abc123",
  "location": "Mumbai",
  "merchant_category": "Food"
}
```

**Analysis:**
- Amount: ₹500 (normal for food delivery)
- Receiver: Known merchant (Swiggy)
- Device: Same device
- User: New BRONZE user (no history yet)

**Expected Result:**
```json
{
  "status": "success",
  "risk_assessment": {
    "overall_risk_score": 0.15,  // LOW
    "risk_level": "LOW",
    "action": "ALLOW",
    "requires_verification": false,
    "message": "✅ Payment approved!",
    "breakdown": {
      "behavior_score": 0.10,
      "amount_score": 0.05,
      "receiver_score": 0.20,
      "ml_score": 0.12
    },
    "risk_factors": [],  // None!
    "processing_time_ms": 150
  }
}
```

**Pass Criteria:** 
- Risk score < 0.30 (LOW)
- Action = ALLOW
- No verification required
- Processing time < 300ms

---

## Test Case 5: MEDIUM-RISK Payment (₹15,000 to Friend) ⚠️

**What it does:**
- Analyzes a moderately risky transaction
- Tests amount anomaly detection
- Should trigger soft verification (OTP)

**API Call:**
```http
POST /api/payment/intent
Authorization: Bearer <token>
{
  "amount": 15000.0,
  "receiver_upi": "friend@paytm",
  "device_id": "device_abc123",
  "location": "Mumbai",
  "merchant_category": "P2P"
}
```

**Analysis:**
- Amount: ₹15,000 (30x larger than previous ₹500)
- Receiver: NEW (never paid before)
- Device: Same device (good)
- Pattern: First large P2P payment

**Expected Result:**
```json
{
  "status": "pending_verification",
  "risk_assessment": {
    "overall_risk_score": 0.52,  // MODERATE
    "risk_level": "MODERATE",
    "action": "SOFT_CHALLENGE",
    "requires_verification": true,
    "verification_type": "OTP",
    "message": "⚠️ Please verify with OTP for security",
    "breakdown": {
      "behavior_score": 0.40,
      "amount_score": 0.65,  // High!
      "receiver_score": 0.50,  // Unknown receiver
      "ml_score": 0.48
    },
    "risk_factors": [
      "Amount 30x higher than previous payment",
      "New receiver detected"
    ],
    "recommendations": [
      "Verify the UPI ID is correct: friend@paytm",
      "Ensure you know the receiver personally"
    ]
  }
}
```

**Pass Criteria:**
- Risk score 0.30-0.60 (MODERATE)
- Action = SOFT_CHALLENGE
- Verification required = true
- Clear risk factors listed

---

## Test Case 6: HIGH-RISK Payment (₹90,000 to Unknown + New Device) 🚫

**What it does:**
- Analyzes a highly suspicious transaction
- Tests multiple fraud indicators simultaneously
- Should BLOCK or require HARD_CHALLENGE

**API Call:**
```http
POST /api/payment/intent
Authorization: Bearer <token>
{
  "amount": 90000.0,
  "receiver_upi": "unknown@paytm",
  "device_id": "NEW_DEVICE_XYZ",  // Different!
  "location": "Delhi",  // Different city
  "merchant_category": "P2P"
}
```

**Analysis:**
- Amount: ₹90,000 (180x larger! HUGE anomaly)
- Receiver: Unknown (never interacted before)
- Device: NEW (potential phone theft/hack)
- Location: Changed (Mumbai → Delhi)
- User: Still BRONZE tier (new, untrusted)

**Red Flags Detected:**
🚩 Massive amount anomaly  
🚩 New receiver  
🚩 Device change  
🚩 Location change  
🚩 Low trust score  

**Expected Result:**
```json
{
  "status": "blocked",
  "risk_assessment": {
    "overall_risk_score": 0.87,  // VERY HIGH!
    "risk_level": "VERY_HIGH",
    "action": "BLOCK",
    "requires_verification": false,  // Too risky to even allow
    "message": "🚫 Transaction blocked for security",
    "breakdown": {
      "behavior_score": 0.75,
      "amount_score": 0.95,  // Extreme!
      "receiver_score": 0.85,  // Very suspicious
      "ml_score": 0.92  // 92% fraud probability
    },
    "risk_factors": [
      "Amount 180x higher than average",
      "New receiver detected",
      "Device change detected",
      "Location change detected",
      "Multiple fraud indicators"
    ],
    "recommendations": [
      "Your account has been temporarily frozen",
      "We've sent a security alert to your email",
      "Please call customer support: 1800-XXX-XXXX",
      "If you didn't initiate this, change password immediately"
    ],
    "immediate_actions": [
      "Transaction blocked",
      "Account locked for 30 minutes",
      "Security team notified",
      "SMS alert sent to registered phone"
    ]
  }
}
```

**Pass Criteria:**
- Risk score > 0.80 (VERY HIGH)
- Action = BLOCK or HARD_CHALLENGE
- Multiple risk factors listed
- Recommendations provided
- Processing time < 300ms

---

## Test Case 7: System Metrics 📊

**What it does:**
- Retrieves system performance metrics
- Shows cache hit rates
- Displays average response times

**API Call:**
```http
GET /metrics
Authorization: Bearer <token>
```

**Expected Result:**
```json
{
  "total_requests": 6,
  "avg_response_time": 187.5,
  "cache": {
    "hits": 3,
    "misses": 3,
    "hit_rate": 0.50
  },
  "ml_model": {
    "status": "fallback",
    "predictions": 3,
    "avg_score": 0.51
  },
  "database": {
    "total_transactions": 3,
    "fraud_detected": 1
  }
}
```

**Pass Criteria:** Metrics retrieved successfully

---

## Complete Test Flow Summary

```
1. Health Check
   → Backend is healthy ✓

2. User Signup  
   → User created (ID: 1, Tier: BRONZE) ✓

3. User Login
   → Token received ✓

4. Low-Risk Payment (₹500 to Swiggy)
   → Risk: 0.15 (LOW)
   → Action: ALLOW ✅
   → Message: "Payment approved!"

5. Medium-Risk Payment (₹15,000 to friend)
   → Risk: 0.52 (MODERATE)
   → Action: SOFT_CHALLENGE ⚠️
   → Message: "Please verify with OTP"

6. High-Risk Payment (₹90,000 to unknown + new device)
   → Risk: 0.87 (VERY HIGH)
   → Action: BLOCK 🚫
   → Message: "Transaction blocked for security"

7. System Metrics
   → Performance stats retrieved ✓
```

---

## How Risk Scores Progress

Notice how the risk score increases with each payment:

| Payment | Amount | Risk Score | Action | Why? |
|---------|--------|------------|--------|------|
| #1 Swiggy | ₹500 | 0.15 | ALLOW | Normal merchant, reasonable amount |
| #2 Friend | ₹15,000 | 0.52 | OTP | 30x larger + new receiver |
| #3 Unknown | ₹90,000 | 0.87 | BLOCK | 180x larger + new receiver + new device |

**This demonstrates the Risk Orchestrator working perfectly!** 🎯

---

## Running All Tests

### Option 1: Automated Script
```powershell
python run_tests.py
```
Starts server, runs all 7 tests, stops server.

### Option 2: Manual Testing
```powershell
# Terminal 1: Start server
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000

# Terminal 2: Run tests
python test_complete_flow.py
```

### Option 3: Visual API Testing
```powershell
# Start server
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000

# Open browser to:
http://127.0.0.1:8000/docs
```

---

## Success Indicators

All tests should show:
- ✅ HTTP 200/201 status codes
- ✅ Processing time < 300ms
- ✅ Risk scores between 0.0 and 1.0
- ✅ Appropriate actions for risk levels
- ✅ Clear, actionable messages
- ✅ Detailed risk factor explanations

**If all pass → Your fraud detection backend is working perfectly! 🎉**
