# 🎓 Fraud Detection Backend - Complete Learning Guide
## From Zero to Hero

---

## 📚 Table of Contents

### Level 1: Absolute Basics (Understanding the Problem)
1. [What is Fraud Detection?](#what-is-fraud-detection)
2. [Why Do We Need a Backend?](#why-do-we-need-a-backend)
3. [Understanding Money Flow](#understanding-money-flow)

### Level 2: Core Concepts (Building Blocks)
4. [What is an API?](#what-is-an-api)
5. [Request and Response](#request-and-response)
6. [Database Basics](#database-basics)
7. [Authentication (Login/Signup)](#authentication)

### Level 3: Our Architecture (The Big Picture)
8. [The Risk Orchestrator Pattern](#the-risk-orchestrator-pattern)
9. [The 5 Engines Explained](#the-5-engines-explained)
10. [How Data Flows](#how-data-flows)

### Level 4: Deep Dive (How Each Part Works)
11. [Context Engine - User Behavior Analysis](#context-engine)
12. [Rules Engine - Pattern Detection](#rules-engine)
13. [ML Engine - Machine Learning Predictions](#ml-engine)
14. [Decision Engine - What Action to Take](#decision-engine)
15. [Risk Orchestrator - The Brain](#risk-orchestrator)

### Level 5: Practical Examples (See It in Action)
16. [Example 1: Safe Payment](#example-1-safe-payment)
17. [Example 2: Risky Payment](#example-2-risky-payment)
18. [Example 3: Fraudulent Payment](#example-3-fraudulent-payment)

### Level 6: Advanced Topics (Pro Level)
19. [Trust Scoring System](#trust-scoring-system)
20. [Caching Strategy](#caching-strategy)
21. [Performance Optimization](#performance-optimization)
22. [Security Best Practices](#security-best-practices)

---

# LEVEL 1: ABSOLUTE BASICS

## What is Fraud Detection?

### Simple Analogy 🏪
Imagine you own a shop:
- **Good customers**: Buy regularly, pay on time, friendly
- **Suspicious customers**: New, buying expensive items, acting strange
- **Fraudsters**: Using fake money, stealing, scamming

**Fraud detection = Being smart about who to trust**

### In Digital Payments
When someone sends money online:
- Is this their normal behavior?
- Are they using their usual device?
- Is the amount suspicious?
- Do they have a good history?

**Our system answers these questions in 200 milliseconds (0.2 seconds)!**

---

## Why Do We Need a Backend?

### The Restaurant Analogy 🍽️

**Frontend (Mobile App)** = The waiter
- Takes your order
- Shows you the menu
- Brings your food

**Backend (Our System)** = The kitchen + manager
- Prepares the food (processes requests)
- Checks inventory (database)
- Manages recipes (business logic)
- Ensures quality (security)

### What Our Backend Does
1. **Receives** payment requests from mobile app
2. **Analyzes** if the payment is safe or risky
3. **Decides** whether to allow, block, or ask for verification
4. **Stores** transaction history
5. **Learns** from patterns over time

---

## Understanding Money Flow

### Traditional Payment (No Fraud Detection)
```
User clicks "Pay ₹1000"
        ↓
    Payment processed immediately
        ↓
    Money transferred
```
**Problem**: Fraudsters can steal money easily!

### Smart Payment (With Our System)
```
User clicks "Pay ₹1000"
        ↓
    Our Backend Analyzes:
    - Who is sending?
    - Who is receiving?
    - Is amount normal?
    - Is device recognized?
    - Any suspicious patterns?
        ↓
    Decision in 0.2 seconds:
    ✅ Safe → Allow
    ⚠️ Risky → Ask for OTP
    🚫 Fraud → Block
        ↓
    Payment processed safely
```

**Result**: We catch 95%+ fraud while keeping good customers happy!

---

# LEVEL 2: CORE CONCEPTS

## What is an API?

### The Restaurant Order Analogy 🍔

**API = Menu + Order System**

When you go to McDonald's:
1. You read the **menu** (API documentation)
2. You **order** "1 Big Mac combo" (API request)
3. Kitchen **prepares** it (backend processing)
4. You **receive** your meal (API response)

### Our Payment API Example

**Request** (Customer orders):
```json
POST /api/payment/intent
{
  "amount": 1000,
  "receiver_upi": "friend@paytm",
  "device_id": "abc123"
}
```

**Response** (Kitchen replies):
```json
{
  "status": "success",
  "risk_level": "LOW",
  "action": "ALLOW",
  "message": "Payment looks safe! ✓"
}
```

### Types of Requests (HTTP Methods)

Think of them as **verbs** in English:

| Method | Meaning | Example |
|--------|---------|---------|
| `GET` | Read/Fetch | "Show me my transactions" |
| `POST` | Create | "Create new payment" |
| `PUT` | Update | "Update my profile" |
| `DELETE` | Remove | "Delete saved card" |

---

## Request and Response

### The Letter Analogy 📬

**Request = Letter you send**
```
To: Backend Server
Subject: Please analyze this payment

Body:
- Amount: ₹5000
- From: Me
- To: Amazon
```

**Response = Reply you get**
```
From: Backend Server
Subject: Analysis Complete

Body:
- Risk Score: 0.15 (LOW)
- Action: ALLOW
- Reason: Normal shopping pattern
```

### Real Example from Our System

**User Action**: Click "Pay ₹500"

**1. Mobile App Sends Request**:
```http
POST http://127.0.0.1:8000/api/payment/intent
Headers:
  Authorization: Bearer eyJ0eXAiOiJKV1QiLCJh... (your login token)
  Content-Type: application/json

Body:
{
  "amount": 500.0,
  "receiver_upi": "merchant@paytm",
  "device_id": "device_abc123",
  "location": "Mumbai",
  "merchant_category": "Food"
}
```

**2. Our Backend Analyzes** (0.15 seconds):
- Checks user history ✓
- Runs fraud rules ✓
- ML prediction ✓
- Calculates risk score ✓

**3. Backend Sends Response**:
```json
{
  "status": "success",
  "transaction_id": "txn_123456",
  "risk_assessment": {
    "overall_risk_score": 0.15,
    "risk_level": "LOW",
    "action": "ALLOW",
    "requires_verification": false,
    "message": "Payment approved! Enjoy your meal 🍕"
  },
  "breakdown": {
    "behavior_score": 0.10,
    "amount_score": 0.05,
    "receiver_score": 0.20
  }
}
```

**4. Mobile App Shows**: "✓ Payment successful!"

---

## Database Basics

### The Filing Cabinet Analogy 🗄️

**Database = Smart digital filing cabinet**

Instead of paper files, we store data in **tables**:

### Example: Users Table
| ID | Name | Email | Trust Score | Account Created |
|----|------|-------|-------------|-----------------|
| 1 | Arun | arun@gmail.com | 85 (GOLD) | 2024-01-15 |
| 2 | Priya | priya@gmail.com | 45 (SILVER) | 2025-12-01 |
| 3 | Vijay | vijay@gmail.com | 15 (BRONZE) | 2026-02-03 |

### Example: Transactions Table
| ID | User ID | Amount | Receiver | Status | Risk Score |
|----|---------|--------|----------|--------|------------|
| 101 | 1 | ₹500 | merchant@paytm | success | 0.12 |
| 102 | 2 | ₹95000 | unknown@paytm | blocked | 0.89 |
| 103 | 1 | ₹1200 | friend@paytm | success | 0.25 |

### Why We Need Databases
1. **Store** user information permanently
2. **Remember** transaction history
3. **Analyze** patterns (e.g., "What's this user's average payment?")
4. **Fast lookup** (find user in milliseconds)

### Our Database Structure

We have **4 main tables**:

1. **Users** - Who are our customers?
2. **Transactions** - What payments happened?
3. **Risk Events** - Which transactions were risky?
4. **Receiver Reputation** - Which receivers are trustworthy?

---

## Authentication

### The ID Card Analogy 🪪

**Problem**: How does the backend know WHO is making the payment?

**Solution**: JWT Tokens (like a digital ID card)

### The Flow

#### 1. Signup (Getting Your ID Card)
```
User fills form:
- Name: Arun
- Email: arun@gmail.com  
- Password: MySecret123!

Backend:
1. Checks email not already used ✓
2. Encrypts password (security!) ✓
3. Creates user in database ✓
4. Gives you a TOKEN (your ID card)
```

**Token looks like**:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE2Mzk5OTk5OTl9.xyz...
```

#### 2. Login (Showing Your ID Card)
```
Every request you make:

Headers:
  Authorization: Bearer eyJhbGciOiJIUz...

Backend:
1. Reads the token ✓
2. Verifies it's real (not fake) ✓
3. Knows you are user_id=1 (Arun) ✓
4. Processes your request ✓
```

#### 3. Token Expiry (ID Card Expires)
- Tokens expire after 60 minutes (security)
- You need to login again to get a new token
- Like refreshing your parking ticket

### Real Code Example

**Signup Request**:
```json
POST /api/auth/signup
{
  "name": "Arun Kumar",
  "email": "arun@gmail.com",
  "password": "SecurePass123!",
  "phone": "+919876543210"
}
```

**Response**:
```json
{
  "status": "success",
  "user": {
    "id": 1,
    "name": "Arun Kumar",
    "email": "arun@gmail.com",
    "trust_score": 0,
    "tier": "BRONZE"
  },
  "access_token": "eyJhbGci...",
  "token_type": "bearer"
}
```

**Now Use Token**:
```json
POST /api/payment/intent
Headers:
  Authorization: Bearer eyJhbGci...
Body:
  { "amount": 1000, ... }
```

---

# LEVEL 3: OUR ARCHITECTURE

## The Risk Orchestrator Pattern

### The Orchestra Analogy 🎼

**Regular fraud detection** = One musician playing alone
- Simple
- Limited perspective
- Misses nuances

**Our Risk Orchestrator** = Full orchestra with conductor
- **Conductor** (Orchestrator) coordinates everything
- **Violins** (Context Engine) provide melody (user behavior)
- **Drums** (Rules Engine) provide rhythm (patterns)
- **Piano** (ML Engine) adds harmony (predictions)
- **Director** (Decision Engine) decides the final piece (action)

### Why This is Better

**Old Way**: Single ML Model
```
Transaction → ML Model → Risk Score → Decision
```
**Problems**:
- Only sees numbers, not context
- Can't explain why
- Misses obvious fraud patterns

**Our Way**: Risk Orchestrator
```
Transaction
    ↓
Context Engine → "User usually pays ₹500, this is ₹90,000!"
    ↓
Rules Engine → "New device + new receiver = RED FLAG"
    ↓
ML Engine → "87% probability of fraud"
    ↓
Decision Engine → "BLOCK + Send alert + Ask for verification"
```

**Benefits**:
- ✅ Considers full context
- ✅ Combines multiple signals
- ✅ Explainable decisions
- ✅ Catches sophisticated fraud

---

## The 5 Engines Explained

### 1️⃣ Context Engine - "The Detective"

**Job**: Investigate user's history and behavior

**Questions it asks**:
- How long has this user been with us?
- What's their typical payment amount?
- How many transactions in last 30 days?
- Is this receiver new or known?
- What's the receiver's reputation?

**Example**:
```python
User: Arun (member for 365 days)
Average payment: ₹800
Total transactions: 145
Success rate: 98%
Last payment: 2 hours ago

→ Context Score: TRUSTED USER
```

---

### 2️⃣ Rules Engine - "The Security Guard"

**Job**: Check for known fraud patterns

**Rules it checks**:
1. **Velocity Check**: Is user sending money too fast?
   - ❌ "Dormant for 90 days, suddenly 10 transactions!"
   
2. **Blacklist Check**: Is receiver on fraud list?
   - ❌ "This UPI has 80% fraud complaints!"
   
3. **Amount Anomaly**: Is amount too high?
   - ❌ "User averages ₹500, now sending ₹50,000!"
   
4. **Device Change**: New device?
   - ⚠️ "Different phone than usual"
   
5. **Failed Attempts**: Too many failures?
   - ❌ "5 failed OTP attempts in 10 minutes!"

**Example**:
```python
Rule Check Results:
✓ Velocity: Normal (3 txn/day, limit 50)
✗ Amount Anomaly: TRIGGERED (₹90,000 vs avg ₹800)
✗ Device Change: TRIGGERED (new device_id)
✓ Receiver: Not blacklisted

→ Rules Risk Score: 0.75 (HIGH)
```
0.0
---

### 3️⃣ ML Engine - "The Fortune Teller"

**Job**: Predict fraud probability using machine learning

**What is Machine Learning?**
Think of it like **learning from experience**:

1. **Training**: Show the model 1 million transactions
   - 950,000 normal ✓
   - 50,000 fraudulent ✗

2. **Learning**: Model finds patterns
   - "When amount > 10x average AND new receiver → 87% fraud"
   - "When trusted user + known merchant → 2% fraud"

3. **Prediction**: New transaction comes
   - Model calculates: "This looks 67% like past frauds"

**Features it looks at** (14 total):
```python
1. amount_to_avg_ratio = 90000 / 800 = 112.5x
2. is_new_receiver = True
3. hourly_velocity = 2 transactions
4. daily_velocity = 2 transactions
5. weekly_velocity = 5 transactions
6. days_since_last_transaction = 0.08 (2 hours)
7. hour_of_day = 22 (10 PM - risky time)
8. day_of_week = 2 (Tuesday)
9. is_weekend = False
10. device_change_indicator = 1 (changed)
11. receiver_reputation_score = 0.3 (low)
12. trust_score = 45 (SILVER tier)
13. account_age_days = 365
14. transaction_count = 145

→ ML Prediction: 0.87 (87% fraud probability)
```

---

### 4️⃣ Decision Engine - "The Judge"

**Job**: Convert risk scores into actions

**Risk Levels**:
```
0.00 - 0.30 = LOW      → ✅ ALLOW (smooth experience)
0.30 - 0.60 = MODERATE → ⚠️ SOFT_CHALLENGE (quick OTP)
0.60 - 0.80 = HIGH     → ⚠️ HARD_CHALLENGE (OTP + call)
0.80 - 1.00 = VERY HIGH → 🚫 BLOCK (fraud detected!)
```

**Trust Tier Adjustments**:
```python
GOLD users (trust_score 71-100):
- Risk reduced by 10%
- Example: 0.65 → 0.55 (HIGH → MODERATE)
- Logic: Loyal customers get benefit of doubt

BRONZE users (trust_score 0-30):
- Risk increased by 5%
- Example: 0.55 → 0.60 (MODERATE → HIGH)
- Logic: New users need more verification

SILVER users (31-70):
- No adjustment
```

**Example Decision**:
```python
Risk Score: 0.67 (HIGH)
User Tier: SILVER (no adjustment)

Decision:
- Action: HARD_CHALLENGE
- Message: "For your security, we need to verify this ₹90,000 payment"
- Verification: OTP + Phone Call
- Recommendations:
  1. "This amount is 112x your average"
  2. "New receiver - verify UPI ID carefully"
  3. "Contact support if this wasn't you"
```

---

### 5️⃣ Risk Orchestrator - "The Brain"

**Job**: Coordinate all engines and make final decision

**The 7-Step Flow**:

```python
Step 1: Receive transaction request
        ↓
Step 2: Context Engine analyzes user history
        → Outputs: user_context, receiver_reputation
        ↓
Step 3: Rules Engine checks fraud patterns
        → Outputs: rule_results, triggered_rules
        ↓
Step 4: ML Engine predicts fraud probability
        → Outputs: ml_score, confidence
        ↓
Step 5: Combine scores (weighted average)
        → Formula: (rules_score * 0.6) + (ml_score * 0.4)
        → Why? Rules are more reliable (60%), ML adapts (40%)
        ↓
Step 6: Decision Engine determines action
        → Outputs: action, message, recommendations
        ↓
Step 7: Log everything and return response
        → Save to database for learning
```

**Real Example Flow**:

```python
# STEP 1: Receive Request
{
  "user_id": 1,
  "amount": 90000,
  "receiver_upi": "unknown@paytm",
  "device_id": "new_device_xyz"
}

# STEP 2: Context Engine
{
  "avg_transaction_amount": 800,
  "transaction_count": 145,
  "account_age_days": 365,
  "is_new_receiver": True,
  "receiver_fraud_ratio": 0.45
}

# STEP 3: Rules Engine
{
  "rules_score": 0.75,
  "triggered_rules": [
    "AMOUNT_ANOMALY: 112x average",
    "NEW_DEVICE: device_id changed",
    "NEW_RECEIVER: first time"
  ]
}

# STEP 4: ML Engine
{
  "ml_score": 0.87,
  "confidence": 0.92,
  "model": "fallback_heuristic"
}

# STEP 5: Combine Scores
combined_score = (0.75 * 0.6) + (0.87 * 0.4)
              = 0.45 + 0.348
              = 0.798 (HIGH RISK!)

# STEP 6: Decision
{
  "risk_level": "HIGH",
  "action": "HARD_CHALLENGE",
  "requires_verification": True,
  "verification_methods": ["OTP", "Phone Call"]
}

# STEP 7: Return Response
{
  "status": "pending_verification",
  "message": "⚠️ High-value transaction detected. Please verify.",
  "risk_assessment": { ... },
  "next_steps": "Enter OTP sent to your phone"
}
```

---

## How Data Flows

### The Complete Journey 🚀

Let's trace a payment from mobile app to backend and back:

```
┌─────────────────┐
│  Mobile App     │  User clicks "Pay ₹1000"
│  (Frontend)     │
└────────┬────────┘
         │ HTTP Request
         ↓
┌─────────────────┐
│  API Gateway    │  POST /api/payment/intent
│  (FastAPI)      │  + JWT Token validation
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│ Risk           │  Orchestrates the analysis
│ Orchestrator   │  (The Brain)
└────────┬────────┘
         │
         ├──→ [Context Engine]
         │    ↓ Queries Database
         │    └→ User has 145 txns, avg ₹800
         │
         ├──→ [Rules Engine]
         │    ↓ Checks patterns
         │    └→ Amount anomaly detected!
         │
         ├──→ [ML Engine]
         │    ↓ Predicts risk
         │    └→ 67% fraud probability
         │
         ├──→ [Decision Engine]
         │    ↓ Determines action
         │    └→ SOFT_CHALLENGE (ask OTP)
         │
         ↓
┌─────────────────┐
│   Database      │  Save transaction & risk event
│   (SQLite)      │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  API Response   │  Return to mobile app
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Mobile App     │  Shows: "Enter OTP to confirm"
└─────────────────┘
```

**Time taken**: 150-200 milliseconds (0.15-0.2 seconds)!

---

# LEVEL 4: DEEP DIVE

## Context Engine

### What It Does
Analyzes user's historical behavior to understand if current transaction is normal or anomalous.

### Real Code Walkthrough

```python
async def get_user_context(user_id: int, db: Session) -> dict:
    """
    Step 1: Try to get from Cache (Redis) - FAST!
    If found → Return immediately
    If not found → Query Database
    """
    
    # Check cache first (0.001 seconds)
    cache_key = f"user_context:{user_id}"
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Not in cache, query database (0.05 seconds)
    user = db.query(User).filter(User.id == user_id).first()
    
    # Calculate statistics
    stats = calculate_user_stats(user_id, db)
    
    context = {
        "user_id": user_id,
        "trust_score": user.trust_score,
        "tier": user.tier,
        "account_age_days": (datetime.now() - user.created_at).days,
        "avg_transaction_amount": stats["avg_amount"],
        "transaction_count": stats["count"],
        "success_rate": stats["success_rate"],
        "hourly_velocity": stats["hourly_velocity"],
        "daily_velocity": stats["daily_velocity"]
    }
    
    # Save to cache for next time (expires in 5 minutes)
    redis_client.set(cache_key, json.dumps(context), expire=300)
    
    return context
```

### Example Output

**For a Good User**:
```json
{
  "user_id": 1,
  "trust_score": 85,
  "tier": "GOLD",
  "account_age_days": 730,
  "avg_transaction_amount": 1500.50,
  "transaction_count": 523,
  "success_rate": 0.98,
  "hourly_velocity": 0,
  "daily_velocity": 2,
  "weekly_velocity": 12
}
```

**For a Suspicious User**:
```json
{
  "user_id": 42,
  "trust_score": 5,
  "tier": "BRONZE",
  "account_age_days": 3,
  "avg_transaction_amount": 200.0,
  "transaction_count": 2,
  "success_rate": 0.50,
  "hourly_velocity": 5,  ← RED FLAG!
  "daily_velocity": 15,  ← RED FLAG!
  "weekly_velocity": 15
}
```

---

## Rules Engine

### What It Does
Checks transaction against known fraud patterns using deterministic rules.

### The Rule Categories

#### 1. Velocity Check
```python
def check_velocity(user_context: dict) -> RuleResult:
    """
    Detects: Burst activity after dormancy
    
    Pattern: Account inactive for 90+ days,
             suddenly makes 10+ transactions
    
    Why fraud: Hacked/stolen accounts
    """
    
    # Check if dormant
    days_since_last = user_context.get("days_since_last_txn", 0)
    if days_since_last > 90:
        # Check current velocity
        if user_context["hourly_velocity"] > 5:
            return RuleResult(
                triggered=True,
                severity="critical",
                score=0.90,
                message="Dormant account burst activity"
            )
    
    return RuleResult(triggered=False, score=0.0)
```

#### 2. Blacklist Check
```python
def check_blacklist(receiver_upi: str, db: Session) -> RuleResult:
    """
    Detects: Payments to known fraud receivers
    
    Pattern: Receiver has >70% fraud ratio
    
    Why fraud: Money mules, scam accounts
    """
    
    receiver = db.query(ReceiverReputation).filter(
        ReceiverReputation.receiver_upi == receiver_upi
    ).first()
    
    if receiver and receiver.fraud_ratio > 0.70:
        return RuleResult(
            triggered=True,
            severity="critical",
            score=1.0,  # Instant block!
            message=f"Receiver has {receiver.fraud_ratio*100}% fraud rate"
        )
    
    return RuleResult(triggered=False, score=0.0)
```

#### 3. Amount Anomaly
```python
def check_amount_anomaly(
    amount: float,
    user_context: dict,
    is_new_receiver: bool
) -> RuleResult:
    """
    Detects: Unusual payment amounts
    
    Pattern: Amount > 3x average AND new receiver
    
    Why fraud: Scammers trick users to send large amounts
    """
    
    avg_amount = user_context["avg_transaction_amount"]
    ratio = amount / avg_amount if avg_amount > 0 else 0
    
    if ratio > 3.0 and is_new_receiver:
        severity = "high" if ratio < 10 else "critical"
        score = min(0.85, 0.40 + (ratio * 0.05))
        
        return RuleResult(
            triggered=True,
            severity=severity,
            score=score,
            message=f"Amount {ratio:.1f}x higher than average to new receiver"
        )
    
    return RuleResult(triggered=False, score=0.0)
```

### Example Analysis

**Transaction**:
```json
{
  "amount": 50000,
  "receiver_upi": "scammer@paytm",
  "device_id": "new_device",
  "user_avg_amount": 1000
}
```

**Rules Results**:
```json
{
  "velocity_check": {
    "triggered": false,
    "score": 0.0
  },
  "blacklist_check": {
    "triggered": true,
    "severity": "critical",
    "score": 1.0,
    "message": "Receiver has 85% fraud rate"
  },
  "amount_anomaly": {
    "triggered": true,
    "severity": "critical",
    "score": 0.85,
    "message": "Amount 50x higher than average to new receiver"
  },
  "device_change": {
    "triggered": true,
    "severity": "medium",
    "score": 0.30,
    "message": "New device detected"
  },
  "overall_rules_score": 1.0,  ← MAXIMUM RISK!
  "action": "BLOCK"
}
```

---

## ML Engine

### What It Does
Uses machine learning to predict fraud probability based on 14 features.

### Understanding Features

**Features = Characteristics the model looks at**

Think of it like a doctor's diagnosis:
- Doctor looks at: temperature, blood pressure, symptoms
- ML model looks at: amount ratio, velocities, device changes

### The 14 Features Explained

```python
def engineer_features(
    transaction: PaymentIntent,
    user_context: dict,
    receiver_reputation: dict
) -> dict:
    """
    Converts raw transaction data into ML features
    """
    
    features = {}
    
    # FEATURE 1: Amount Ratio
    # How many times larger is this payment vs user's average?
    avg = user_context.get("avg_transaction_amount", 1.0)
    features["amount_to_avg_ratio"] = transaction.amount / avg
    # Example: ₹10,000 / ₹1,000 = 10.0
    
    # FEATURE 2: Is New Receiver?
    # Has user paid this receiver before?
    features["is_new_receiver"] = 1 if is_new_receiver else 0
    # 1 = Yes (riskier), 0 = No (safer)
    
    # FEATURE 3-5: Velocity Features
    # How many transactions in last hour/day/week?
    features["hourly_velocity"] = user_context.get("hourly_velocity", 0)
    features["daily_velocity"] = user_context.get("daily_velocity", 0)
    features["weekly_velocity"] = user_context.get("weekly_velocity", 0)
    # High velocity = Potential fraud burst
    
    # FEATURE 6: Days Since Last Transaction
    # How long has user been inactive?
    features["days_since_last_transaction"] = user_context.get("days_since_last_txn", 0)
    # > 90 days then sudden activity = Hacked account?
    
    # FEATURE 7-9: Time Features
    # When is this transaction happening?
    now = datetime.now()
    features["hour_of_day"] = now.hour  # 0-23
    features["day_of_week"] = now.weekday()  # 0-6
    features["is_weekend"] = 1 if now.weekday() >= 5 else 0
    # Night transactions (11 PM - 5 AM) = Riskier
    
    # FEATURE 10: Device Change
    # Is this a new device?
    features["device_change_indicator"] = 1 if device_changed else 0
    # New device + large payment = Stolen phone?
    
    # FEATURE 11: Receiver Reputation
    # How trustworthy is the receiver?
    features["receiver_reputation_score"] = receiver_reputation.get("score", 0.5)
    # Low score = Known fraud receiver
    
    # FEATURE 12-14: User Trust Metrics
    features["trust_score"] = user_context.get("trust_score", 0)
    features["account_age_days"] = user_context.get("account_age_days", 0)
    features["transaction_count"] = user_context.get("transaction_count", 0)
    # Established users = More trustworthy
    
    return features
```

### Prediction Process

```python
def predict(features: dict) -> float:
    """
    Predicts fraud probability (0.0 to 1.0)
    
    If CatBoost model available:
        Use trained ML model
    Else:
        Use fallback heuristic
    """
    
    if model_loaded:
        # Real ML prediction
        feature_vector = [features[f] for f in FEATURE_ORDER]
        probability = model.predict_proba([feature_vector])[0][1]
        return probability
    else:
        # Fallback calculation
        return calculate_fallback_score(features)


def calculate_fallback_score(features: dict) -> float:
    """
    Heuristic-based scoring when ML model unavailable
    
    Weighted formula based on domain knowledge
    """
    
    score = 0.0
    
    # High amount ratio = Risk
    if features["amount_to_avg_ratio"] > 10:
        score += 0.35
    elif features["amount_to_avg_ratio"] > 5:
        score += 0.20
    elif features["amount_to_avg_ratio"] > 3:
        score += 0.10
    
    # New receiver + high amount = Risk
    if features["is_new_receiver"] and features["amount_to_avg_ratio"] > 3:
        score += 0.25
    
    # High velocity = Risk
    if features["hourly_velocity"] > 5:
        score += 0.20
    elif features["daily_velocity"] > 20:
        score += 0.15
    
    # Night transaction = Risk
    hour = features["hour_of_day"]
    if hour >= 23 or hour <= 5:
        score += 0.10
    
    # Device change = Risk
    if features["device_change_indicator"]:
        score += 0.15
    
    # Bad receiver reputation = Risk
    if features["receiver_reputation_score"] < 0.3:
        score += 0.25
    
    # Reduce for trusted users
    if features["trust_score"] > 70:
        score *= 0.8  # 20% reduction
    elif features["trust_score"] > 40:
        score *= 0.9  # 10% reduction
    
    return min(1.0, score)  # Cap at 1.0
```

### Example Prediction

**Input Features**:
```json
{
  "amount_to_avg_ratio": 50.0,
  "is_new_receiver": 1,
  "hourly_velocity": 3,
  "daily_velocity": 5,
  "weekly_velocity": 8,
  "days_since_last_transaction": 0.5,
  "hour_of_day": 23,
  "day_of_week": 4,
  "is_weekend": 0,
  "device_change_indicator": 1,
  "receiver_reputation_score": 0.25,
  "trust_score": 35,
  "account_age_days": 120,
  "transaction_count": 45
}
```

**Calculation**:
```
Base score: 0.0
+ Amount ratio > 10: +0.35
+ New receiver + high amount: +0.25
+ Night transaction: +0.10
+ Device change: +0.15
+ Bad receiver reputation: +0.25
= 1.10 (capped at 1.0)

Final ML Score: 0.95 (95% fraud probability!)
```

---

## Decision Engine

### What It Does
Maps risk scores to user-facing actions and messages.

### Risk Buckets

```python
def map_to_risk_level(risk_score: float) -> str:
    """
    Converts numerical score to risk category
    """
    if risk_score < 0.30:
        return "LOW"
    elif risk_score < 0.60:
        return "MODERATE"
    elif risk_score < 0.80:
        return "HIGH"
    else:
        return "VERY_HIGH"
```

### Action Mapping

```python
RISK_ACTIONS = {
    "LOW": {
        "action": "ALLOW",
        "verification": False,
        "message": "Payment approved! Transaction looks safe ✓",
        "icon": "✅"
    },
    "MODERATE": {
        "action": "SOFT_CHALLENGE",
        "verification": True,
        "verification_type": "OTP",
        "message": "Please verify with OTP for security",
        "icon": "⚠️"
    },
    "HIGH": {
        "action": "HARD_CHALLENGE",
        "verification": True,
        "verification_type": ["OTP", "Phone Call"],
        "message": "Additional verification required for this transaction",
        "icon": "⚠️"
    },
    "VERY_HIGH": {
        "action": "BLOCK",
        "verification": False,
        "message": "Transaction blocked due to security concerns",
        "contact_support": True,
        "icon": "🚫"
    }
}
```

### Trust Tier Adjustments

```python
def apply_tier_adjustment(risk_score: float, tier: str) -> float:
    """
    Loyal customers get better treatment
    """
    
    if tier == "GOLD":
        # Trust GOLD users more
        adjusted = risk_score * 0.9  # 10% reduction
        logger.info(f"GOLD tier: {risk_score:.2f} → {adjusted:.2f}")
        return adjusted
        
    elif tier == "BRONZE":
        # Be cautious with new users
        adjusted = min(1.0, risk_score * 1.05)  # 5% increase
        logger.info(f"BRONZE tier: {risk_score:.2f} → {adjusted:.2f}")
        return adjusted
        
    else:  # SILVER
        return risk_score
```

### Generate Recommendations

```python
def generate_recommendations(
    risk_factors: list,
    risk_level: str
) -> list:
    """
    Provides actionable advice to user
    """
    
    recommendations = []
    
    for factor in risk_factors:
        if "amount" in factor.lower():
            recommendations.append(
                "This payment is significantly higher than your usual amount. "
                "Verify the receiver details carefully."
            )
        
        if "new receiver" in factor.lower():
            recommendations.append(
                "First time paying this receiver. "
                "Double-check the UPI ID before confirming."
            )
        
        if "device" in factor.lower():
            recommendations.append(
                "New device detected. If this wasn't you, "
                "change your password immediately."
            )
        
        if "velocity" in factor.lower():
            recommendations.append(
                "Unusual transaction frequency detected. "
                "Ensure your account hasn't been compromised."
            )
    
    if risk_level in ["HIGH", "VERY_HIGH"]:
        recommendations.append(
            "If you didn't initiate this payment, contact support immediately: "
            "1800-XXX-XXXX"
        )
    
    return recommendations
```

### Complete Decision Example

**Input**:
```python
risk_score = 0.67
tier = "SILVER"
risk_factors = [
    "Amount 50x higher than average",
    "New receiver detected",
    "Device change detected"
]
```

**Output**:
```json
{
  "risk_level": "HIGH",
  "action": "HARD_CHALLENGE",
  "requires_verification": true,
  "verification_methods": ["OTP", "Phone Call"],
  "message": "⚠️ Additional verification required for this transaction",
  "recommendations": [
    "This payment is significantly higher than your usual amount. Verify the receiver details carefully.",
    "First time paying this receiver. Double-check the UPI ID before confirming.",
    "New device detected. If this wasn't you, change your password immediately.",
    "If you didn't initiate this payment, contact support immediately: 1800-XXX-XXXX"
  ],
  "estimated_time": "2-3 minutes",
  "support_contact": "1800-XXX-XXXX"
}
```

---

## Risk Orchestrator

### What It Does
The BRAIN that coordinates all engines and produces final risk assessment.

### Complete Flow with Code

```python
async def analyze_transaction(
    transaction: PaymentIntentRequest,
    user_id: int,
    db: Session
) -> RiskAssessment:
    """
    The main orchestration function
    """
    
    logger.info(f"🔍 Analyzing transaction for user {user_id}")
    start_time = time.time()
    
    # ============================================
    # STEP 1: Gather Context
    # ============================================
    logger.info("📊 Step 1: Gathering user context...")
    
    user_context = await context_engine.get_user_context(user_id, db)
    receiver_reputation = await context_engine.get_receiver_reputation(
        transaction.receiver_upi, db
    )
    is_new_receiver = await context_engine.check_new_receiver(
        user_id, transaction.receiver_upi, db
    )
    
    logger.info(f"   ✓ User: {user_context['tier']} tier, "
                f"{user_context['transaction_count']} txns")
    logger.info(f"   ✓ Receiver reputation: {receiver_reputation['score']:.2f}")
    
    # ============================================
    # STEP 2: Run Rules Engine
    # ============================================
    logger.info("📋 Step 2: Checking fraud rules...")
    
    rule_result = rules_engine.evaluate(
        transaction=transaction,
        user_context=user_context,
        is_new_receiver=is_new_receiver,
        receiver_reputation=receiver_reputation
    )
    
    logger.info(f"   ✓ Rules score: {rule_result.overall_score:.2f}")
    logger.info(f"   ✓ Triggered rules: {len(rule_result.triggered_rules)}")
    
    # ============================================
    # STEP 3: Run ML Engine
    # ============================================
    logger.info("🧠 Step 3: Running ML prediction...")
    
    ml_score = ml_engine.predict(
        transaction=transaction,
        user_context=user_context,
        receiver_reputation=receiver_reputation,
        is_new_receiver=is_new_receiver
    )
    
    logger.info(f"   ✓ ML score: {ml_score:.2f}")
    
    # ============================================
    # STEP 4: Combine Scores
    # ============================================
    logger.info("⚖️  Step 4: Combining scores...")
    
    # Weighted combination: Rules 60%, ML 40%
    combined_score = (
        rule_result.overall_score * 0.6 +
        ml_score * 0.4
    )
    
    logger.info(f"   ✓ Combined score: {combined_score:.2f}")
    logger.info(f"      (Rules: {rule_result.overall_score:.2f} * 0.6 = "
                f"{rule_result.overall_score * 0.6:.2f})")
    logger.info(f"      (ML: {ml_score:.2f} * 0.4 = {ml_score * 0.4:.2f})")
    
    # ============================================
    # STEP 5: Apply Trust Tier Adjustment
    # ============================================
    tier = user_context.get("tier", "BRONZE")
    adjusted_score = decision_engine.apply_tier_adjustment(
        combined_score, tier
    )
    
    if adjusted_score != combined_score:
        logger.info(f"   ✓ Tier adjustment ({tier}): "
                    f"{combined_score:.2f} → {adjusted_score:.2f}")
    
    # ============================================
    # STEP 6: Get Decision
    # ============================================
    logger.info("⚖️  Step 5: Determining action...")
    
    decision = decision_engine.get_action(
        risk_score=adjusted_score,
        risk_factors=rule_result.triggered_rules,
        tier=tier
    )
    
    logger.info(f"   ✓ Decision: {decision.action}")
    logger.info(f"   ✓ Risk level: {decision.risk_level}")
    
    # ============================================
    # STEP 7: Build Response
    # ============================================
    elapsed_time = (time.time() - start_time) * 1000  # milliseconds
    
    logger.info(f"✅ Analysis complete in {elapsed_time:.0f}ms")
    
    return RiskAssessment(
        overall_risk_score=adjusted_score,
        risk_level=decision.risk_level,
        action=decision.action,
        requires_verification=decision.requires_verification,
        message=decision.message,
        breakdown={
            "behavior_score": rule_result.behavior_score,
            "amount_score": rule_result.amount_score,
            "receiver_score": rule_result.receiver_score,
            "ml_score": ml_score
        },
        risk_factors=rule_result.triggered_rules,
        recommendations=decision.recommendations,
        processing_time_ms=elapsed_time
    )
```

### Example Complete Analysis

**Input Transaction**:
```json
{
  "amount": 90000,
  "receiver_upi": "unknown@paytm",
  "device_id": "new_device_xyz",
  "merchant_category": "P2P"
}
```

**Console Logs**:
```
🔍 Analyzing transaction for user 1

📊 Step 1: Gathering user context...
   ✓ User: SILVER tier, 145 txns
   ✓ Receiver reputation: 0.30

📋 Step 2: Checking fraud rules...
   ✓ Rules score: 0.75
   ✓ Triggered rules: 3
      - Amount 112.5x higher than average
      - New receiver detected
      - Device change detected

🧠 Step 3: Running ML prediction...
   ✓ ML score: 0.87

⚖️ Step 4: Combining scores...
   ✓ Combined score: 0.80
      (Rules: 0.75 * 0.6 = 0.45)
      (ML: 0.87 * 0.4 = 0.35)

⚖️ Step 5: Determining action...
   ✓ Decision: BLOCK
   ✓ Risk level: VERY_HIGH

✅ Analysis complete in 187ms
```

**Output Response**:
```json
{
  "status": "blocked",
  "transaction_id": "txn_20260204_001",
  "risk_assessment": {
    "overall_risk_score": 0.80,
    "risk_level": "VERY_HIGH",
    "action": "BLOCK",
    "requires_verification": false,
    "message": "🚫 Transaction blocked due to security concerns",
    "breakdown": {
      "behavior_score": 0.60,
      "amount_score": 0.85,
      "receiver_score": 0.70,
      "ml_score": 0.87
    },
    "risk_factors": [
      "Amount 112.5x higher than average",
      "New receiver detected",
      "Device change detected"
    ],
    "recommendations": [
      "This payment is significantly higher than your usual amount.",
      "First time paying this receiver - verify UPI ID carefully.",
      "New device detected. If this wasn't you, change password immediately.",
      "Contact support immediately: 1800-XXX-XXXX"
    ],
    "processing_time_ms": 187
  },
  "next_steps": "Contact customer support to unblock",
  "support_contact": "1800-XXX-XXXX"
}
```

---

# LEVEL 5: PRACTICAL EXAMPLES

## Example 1: Safe Payment

### Scenario
Arun (loyal GOLD user) paying ₹600 to Swiggy for dinner.

### Transaction Details
```json
{
  "user_id": 1,
  "user_name": "Arun Kumar",
  "user_tier": "GOLD",
  "trust_score": 85,
  "account_age_days": 730,
  "transaction_count": 523,
  "avg_transaction_amount": 1500,
  
  "current_transaction": {
    "amount": 600,
    "receiver_upi": "swiggy@paytm",
    "merchant_category": "Food",
    "device_id": "device_abc123"  // Same device
  }
}
```

### Analysis Flow

#### Step 1: Context
```
✓ Established user (2 years)
✓ High trust score (GOLD tier)
✓ Frequent transactor (523 txns)
✓ Known merchant (paid Swiggy 47 times)
✓ Same device (not changed)
```

#### Step 2: Rules Engine
```
Velocity Check: ✓ PASS (2 txn today, normal)
Blacklist Check: ✓ PASS (Swiggy is verified merchant)
Amount Anomaly: ✓ PASS (₹600 < ₹1500 average)
Device Change: ✓ PASS (same device)
Failed Attempts: ✓ PASS (no recent failures)

Rules Score: 0.05 (very low risk)
```

#### Step 3: ML Engine
```
Features:
  amount_to_avg_ratio: 0.4 (smaller than average)
  is_new_receiver: 0 (known merchant)
  hourly_velocity: 0
  daily_velocity: 2
  hour_of_day: 19 (7 PM - normal dinner time)
  device_change: 0
  receiver_reputation: 0.95 (excellent)
  trust_score: 85 (high)
  
ML Prediction: 0.03 (3% fraud probability)
```

#### Step 4: Combine
```
Combined Score = (0.05 * 0.6) + (0.03 * 0.4)
               = 0.03 + 0.012
               = 0.042
```

#### Step 5: Tier Adjustment
```
GOLD tier: 0.042 * 0.9 = 0.038
```

#### Step 6: Decision
```
Risk Level: LOW (0.038 < 0.30)
Action: ALLOW
Verification: Not required
```

### Response to User
```json
{
  "status": "success",
  "message": "✅ Payment approved! Enjoy your meal 🍕",
  "risk_assessment": {
    "risk_level": "LOW",
    "action": "ALLOW",
    "requires_verification": false
  },
  "estimated_delivery": "30-40 minutes",
  "processing_time_ms": 98
}
```

### User Experience
```
User clicks "Pay ₹600"
        ↓
    0.1 seconds
        ↓
"✅ Payment successful!"
        ↓
No OTP, no friction
        ↓
Happy customer! 😊
```

---

## Example 2: Risky Payment

### Scenario
Priya (SILVER user) paying ₹15,000 to a friend for first time.

### Transaction Details
```json
{
  "user_id": 2,
  "user_name": "Priya Shah",
  "user_tier": "SILVER",
  "trust_score": 45,
  "account_age_days": 180,
  "transaction_count": 87,
  "avg_transaction_amount": 2500,
  
  "current_transaction": {
    "amount": 15000,
    "receiver_upi": "friend@paytm",  // New receiver!
    "merchant_category": "P2P",
    "device_id": "device_xyz789"  // Same device
  }
}
```

### Analysis Flow

#### Step 1: Context
```
⚠️ Moderate user (6 months)
⚠️ Medium trust score (SILVER tier)
✓ Regular transactions (87 txns)
⚠️ New receiver (never paid before)
✓ Same device
```

#### Step 2: Rules Engine
```
Velocity Check: ✓ PASS (normal activity)
Blacklist Check: ✓ PASS (not blacklisted)
Amount Anomaly: ⚠️ TRIGGERED! (15000 / 2500 = 6x average)
Device Change: ✓ PASS (same device)
Failed Attempts: ✓ PASS

Triggered Rules:
  - "Amount 6x higher than average to new receiver"

Rules Score: 0.55 (moderate-high risk)
```

#### Step 3: ML Engine
```
Features:
  amount_to_avg_ratio: 6.0 (high!)
  is_new_receiver: 1 (yes)
  hourly_velocity: 0
  daily_velocity: 1
  hour_of_day: 14 (2 PM - normal)
  device_change: 0
  receiver_reputation: 0.5 (unknown)
  trust_score: 45 (medium)
  
ML Prediction: 0.47 (47% fraud probability)
```

#### Step 4: Combine
```
Combined Score = (0.55 * 0.6) + (0.47 * 0.4)
               = 0.33 + 0.188
               = 0.518
```

#### Step 5: Tier Adjustment
```
SILVER tier: No adjustment
Final Score: 0.52
```

#### Step 6: Decision
```
Risk Level: MODERATE (0.30 < 0.52 < 0.60)
Action: SOFT_CHALLENGE
Verification: OTP required
```

### Response to User
```json
{
  "status": "pending_verification",
  "message": "⚠️ Please verify with OTP for security",
  "risk_assessment": {
    "risk_level": "MODERATE",
    "action": "SOFT_CHALLENGE",
    "requires_verification": true,
    "verification_type": "OTP"
  },
  "reason": "This payment is higher than your usual amount to a new receiver",
  "recommendations": [
    "Verify the UPI ID is correct: friend@paytm",
    "Ensure you know the receiver personally",
    "This OTP helps protect your account"
  ],
  "processing_time_ms": 152
}
```

### User Experience
```
User clicks "Pay ₹15,000"
        ↓
    0.15 seconds
        ↓
"⚠️ Enter OTP to confirm"
(OTP sent to phone)
        ↓
User enters OTP
        ↓
"✅ Payment successful!"
        ↓
Slight friction, but understood 👍
```

---

## Example 3: Fraudulent Payment

### Scenario
Rahul's account hacked. Fraudster trying to transfer ₹95,000 to money mule.

### Transaction Details
```json
{
  "user_id": 3,
  "user_name": "Rahul Mehta",
  "user_tier": "BRONZE",
  "trust_score": 12,
  "account_age_days": 15,
  "transaction_count": 8,
  "avg_transaction_amount": 350,
  
  "current_transaction": {
    "amount": 95000,  // ⚠️ HUGE!
    "receiver_upi": "mule@paytm",  // ⚠️ Known fraud receiver!
    "merchant_category": "P2P",
    "device_id": "new_device_unknown"  // ⚠️ NEW DEVICE!
  }
}
```

### Red Flags 🚩
- Amount 271x higher than average!
- Brand new device
- Account only 15 days old
- Receiver has 78% fraud ratio
- Payment at 2:30 AM (suspicious time)
- No similar transactions before

### Analysis Flow

#### Step 1: Context
```
🚩 Very new user (15 days)
🚩 Low trust score (BRONZE tier)
🚩 Minimal history (8 txns)
🚩 NEW RECEIVER
🚩 NEW DEVICE (CRITICAL!)
```

#### Step 2: Rules Engine
```
Velocity Check: ⚠️ TRIGGERED (3 txn in 1 hour after 7 days dormant)
Blacklist Check: 🚨 CRITICAL! (Receiver has 78% fraud ratio!)
Amount Anomaly: 🚨 CRITICAL! (Amount 271x average to new receiver)
Device Change: 🚨 CRITICAL! (Completely new device)
Failed Attempts: ✓ PASS

Triggered Rules:
  - "CRITICAL: Receiver on fraud blacklist (78% fraud ratio)"
  - "CRITICAL: Amount 271x higher than average to new receiver"
  - "CRITICAL: New device detected"
  - "Burst activity after dormancy"

Rules Score: 0.98 (MAXIMUM RISK!)
```

#### Step 3: ML Engine
```
Features:
  amount_to_avg_ratio: 271.4 (EXTREME!)
  is_new_receiver: 1
  hourly_velocity: 3 (high for new user)
  daily_velocity: 3
  hour_of_day: 2 (2:30 AM - suspicious!)
  is_weekend: 0
  device_change: 1 (CRITICAL)
  receiver_reputation: 0.22 (very bad!)
  trust_score: 12 (very low)
  account_age_days: 15 (new)
  
ML Prediction: 0.96 (96% fraud probability!)
```

#### Step 4: Combine
```
Combined Score = (0.98 * 0.6) + (0.96 * 0.4)
               = 0.588 + 0.384
               = 0.972
```

#### Step 5: Tier Adjustment
```
BRONZE tier: 0.972 * 1.05 = 1.021
Capped at: 1.0
```

#### Step 6: Decision
```
Risk Level: VERY_HIGH (1.0 > 0.80)
Action: BLOCK
Verification: Not allowed
Alert: Send to fraud team + notify user
```

### Response to User
```json
{
  "status": "blocked",
  "message": "🚫 Transaction blocked for security",
  "risk_assessment": {
    "risk_level": "VERY_HIGH",
    "action": "BLOCK",
    "requires_verification": false
  },
  "reason": "Multiple security concerns detected",
  "immediate_actions": [
    "Your account has been temporarily frozen",
    "We've sent a security alert to your email",
    "Please call customer support immediately: 1800-XXX-XXXX"
  ],
  "risk_factors": [
    "Payment to high-risk receiver",
    "Unusual transaction amount",
    "Unrecognized device",
    "Suspicious transaction pattern"
  ],
  "processing_time_ms": 143
}
```

### Backend Actions
```
1. ❌ Block transaction immediately
2. 🔒 Lock user account temporarily
3. 📧 Send security alert email
4. 📱 Send SMS notification
5. 🚨 Create fraud investigation ticket
6. 📊 Log detailed fraud event
7. 🔔 Alert fraud team for manual review
```

### User Experience
```
Fraudster tries to pay ₹95,000
        ↓
    0.14 seconds
        ↓
"🚫 Transaction blocked!"
        ↓
Account locked
        ↓
SMS sent to real owner: "Suspicious activity detected!"
        ↓
Real user: "I didn't do this!"
        ↓
Calls support, account secured
        ↓
Money saved! Fraud prevented! 🎉
```

### What We Prevented
- ₹95,000 loss avoided
- User account secured
- Fraudster caught (device fingerprint logged)
- Receiver flagged for investigation
- Pattern added to ML model for future detection

---

# LEVEL 6: ADVANCED TOPICS

## Trust Scoring System

### What is Trust Score?

**Trust Score = Credit score for payments**

- Range: 0-100
- Updated after each transaction
- Determines user tier (BRONZE/SILVER/GOLD)
- Affects friction level

### How It's Calculated

```python
def calculate_trust_score(user_id: int, db: Session) -> int:
    """
    Complex algorithm considering multiple factors
    """
    
    user = db.query(User).filter(User.id == user_id).first()
    transactions = db.query(Transaction).filter(
        Transaction.user_id == user_id
    ).all()
    
    score = 50  # Start at 50 (neutral)
    
    # FACTOR 1: Account Age (max +20 points)
    account_age_days = (datetime.now() - user.created_at).days
    age_points = min(20, account_age_days / 36.5)  # 1 point per ~36 days
    score += age_points
    
    # FACTOR 2: Transaction Count (max +15 points)
    txn_count = len(transactions)
    count_points = min(15, txn_count / 10)  # 1 point per 10 txns
    score += count_points
    
    # FACTOR 3: Success Rate (max +20 points)
    successful = [t for t in transactions if t.status == "success"]
    success_rate = len(successful) / len(transactions) if transactions else 0
    success_points = success_rate * 20
    score += success_points
    
    # FACTOR 4: Fraud History (penalty -50 points)
    fraud_txns = [t for t in transactions if t.status == "fraud"]
    if fraud_txns:
        score -= len(fraud_txns) * 25  # Heavy penalty
    
    # FACTOR 5: Dispute Rate (penalty -30 points)
    disputed = [t for t in transactions if t.disputed]
    dispute_rate = len(disputed) / len(transactions) if transactions else 0
    if dispute_rate > 0.05:  # > 5% disputes
        score -= 30
    
    # FACTOR 6: Payment Velocity (penalty -10 if too high)
    recent_txns = [t for t in transactions 
                   if (datetime.now() - t.created_at).days <= 1]
    if len(recent_txns) > 20:  # > 20 txn/day = suspicious
        score -= 10
    
    # FACTOR 7: Average Transaction Size (bonus +15)
    avg_amount = sum(t.amount for t in successful) / len(successful) if successful else 0
    if avg_amount > 5000:  # Higher value customer
        score += 15
    elif avg_amount > 2000:
        score += 10
    elif avg_amount > 500:
        score += 5
    
    # FACTOR 8: Verification Compliance (bonus +10)
    challenged_txns = [t for t in transactions 
                       if t.verification_required]
    if challenged_txns:
        verified = [t for t in challenged_txns 
                    if t.verification_completed]
        compliance_rate = len(verified) / len(challenged_txns)
        if compliance_rate > 0.95:
            score += 10
    
    # Cap between 0 and 100
    return max(0, min(100, int(score)))
```

### Trust Tiers

```python
def get_tier(trust_score: int) -> str:
    if trust_score >= 71:
        return "GOLD"
    elif trust_score >= 31:
        return "SILVER"
    else:
        return "BRONZE"
```

### Real Examples

**New User - Day 1**:
```
Account age: 0 days → +0 points
Transactions: 0 → +0 points
Success rate: 0% → +0 points
Starting score: 50

Tier: SILVER (benefit of doubt)
```

**After 1 Month**:
```
Account age: 30 days → +16 points
Transactions: 25 → +2.5 points
Success rate: 96% → +19.2 points
Starting: 50
Total: 87.7 → 88

Tier: GOLD ⭐
```

**After Fraud**:
```
Previous score: 88
Fraud detected: -25 points
New score: 63

Tier: SILVER (downgraded)
```

---

## Caching Strategy

### Why Cache?

**Problem**: Database queries are slow (50-100ms)
**Solution**: Redis cache is fast (1-2ms)

**Speed Comparison**:
```
Database Query: 🐢 50ms
Redis Cache: 🚀 2ms

25x faster!
```

### What We Cache

```python
CACHE_PATTERNS = {
    # User context (very frequent)
    "user_context:{user_id}": {
        "ttl": 300,  # 5 minutes
        "hit_rate": "95%",
        "reason": "Same user makes multiple payments"
    },
    
    # Receiver reputation (somewhat frequent)
    "receiver_rep:{upi}": {
        "ttl": 600,  # 10 minutes
        "hit_rate": "80%",
        "reason": "Popular merchants get many payments"
    },
    
    # User statistics (medium frequency)
    "user_stats:{user_id}": {
        "ttl": 900,  # 15 minutes
        "hit_rate": "70%",
        "reason": "Stats don't change much in short time"
    },
    
    # Blacklist (infrequent changes)
    "blacklist:receivers": {
        "ttl": 3600,  # 1 hour
        "hit_rate": "99%",
        "reason": "Blacklist rarely updated"
    }
}
```

### Cache-Aside Pattern

```python
async def get_user_context(user_id: int, db: Session) -> dict:
    """
    1. Check cache first
    2. If miss, query database
    3. Store in cache for next time
    """
    
    cache_key = f"user_context:{user_id}"
    
    # TRY CACHE FIRST (2ms)
    cached = redis_client.get(cache_key)
    if cached:
        logger.info(f"✓ Cache HIT for {cache_key}")
        return json.loads(cached)
    
    logger.info(f"✗ Cache MISS for {cache_key}")
    
    # FALLBACK TO DATABASE (50ms)
    context = calculate_from_database(user_id, db)
    
    # POPULATE CACHE FOR NEXT TIME
    redis_client.set(
        cache_key,
        json.dumps(context),
        expire=300  # 5 minutes
    )
    
    return context
```

### Cache Invalidation

**When to invalidate**:

```python
# After every transaction
async def on_transaction_complete(transaction: Transaction):
    """
    Clear relevant caches when data changes
    """
    
    user_id = transaction.user_id
    receiver_upi = transaction.receiver_upi
    
    # Invalidate user context (stats changed)
    redis_client.delete(f"user_context:{user_id}")
    redis_client.delete(f"user_stats:{user_id}")
    
    # Invalidate receiver reputation (new data point)
    redis_client.delete(f"receiver_rep:{receiver_upi}")
    
    logger.info(f"🔄 Cache invalidated for user {user_id}")
```

### Performance Impact

**Without Cache**:
```
Request 1: DB query 50ms
Request 2: DB query 50ms
Request 3: DB query 50ms
Total: 150ms
```

**With Cache**:
```
Request 1: DB query 50ms → Cache stored
Request 2: Cache hit 2ms
Request 3: Cache hit 2ms
Total: 54ms (64% faster!)
```

---

## Performance Optimization

### Target: 200ms Response Time

**Breakdown of 200ms**:
```
Network (client → server): 30ms
Authentication (JWT verify): 5ms
Context gathering: 40ms
  - Cache hit: 2ms
  - or DB query: 50ms
Rules engine: 15ms
ML engine: 30ms
Decision engine: 5ms
Database write: 20ms
Response build: 10ms
Network (server → client): 30ms
Buffer: 15ms
Total: ~200ms
```

### Optimization Techniques

#### 1. Parallel Processing

**Sequential (slow)**:
```python
# Total: 50 + 30 + 20 = 100ms
context = await get_context()  # 50ms
rules = await run_rules()      # 30ms
ml = await run_ml()            # 20ms
```

**Parallel (fast)**:
```python
# Total: max(50, 30, 20) = 50ms
context, rules, ml = await asyncio.gather(
    get_context(),  # 50ms
    run_rules(),    # 30ms
    run_ml()        # 20ms
)
```

#### 2. Database Indexing

```sql
-- Slow query (1000ms for 1M records)
SELECT * FROM transactions 
WHERE user_id = 123;

-- Fast query with index (5ms)
CREATE INDEX idx_user_id ON transactions(user_id);
SELECT * FROM transactions 
WHERE user_id = 123;
```

#### 3. Connection Pooling

```python
# Bad: Create new connection every time (50ms overhead)
def get_db():
    connection = create_connection()
    # ...
    connection.close()

# Good: Reuse connections from pool (0ms overhead)
pool = create_pool(size=20)
def get_db():
    connection = pool.get_connection()
    # ...
    pool.return_connection(connection)
```

#### 4. Async/Await

```python
# Synchronous (blocking) - Total: 150ms
def process_payment():
    db_result = query_database()  # Wait 50ms
    cache_result = query_cache()  # Wait 50ms
    api_result = call_api()       # Wait 50ms
    # Thread blocked for 150ms!

# Asynchronous (non-blocking) - Total: 50ms
async def process_payment():
    db_task = asyncio.create_task(query_database())
    cache_task = asyncio.create_task(query_cache())
    api_task = asyncio.create_task(call_api())
    
    # All run in parallel!
    db_result, cache_result, api_result = await asyncio.gather(
        db_task, cache_task, api_task
    )
    # Thread free after 50ms
```

#### 5. Response Compression

```python
# Before: 50KB response
{
  "risk_assessment": {...},
  "user_context": {...},
  "transaction_history": [...],
  "recommendations": [...]
}

# After: 8KB response (gzip)
Content-Encoding: gzip
(compressed data)

# Network time: 200ms → 40ms
```

---

## Security Best Practices

### 1. Password Security

**Never do this** ❌:
```python
# Storing plain text password - VERY BAD!
user.password = "MySecret123"
```

**Always do this** ✅:
```python
# Hash password with bcrypt
hashed = bcrypt.hashpw(
    password.encode('utf-8'),
    bcrypt.gensalt(rounds=12)
)
user.password_hash = hashed
```

**Why?**
If database is hacked:
- Plain text: Hacker sees "MySecret123" ❌
- Hashed: Hacker sees "$2b$12$KIXXww..." ✅ (useless without key)

### 2. JWT Token Security

```python
# Secret key (keep this VERY secret!)
SECRET_KEY = "your-256-bit-secret"  # Use env variable!

# Create token with expiry
token = jwt.encode(
    {
        "user_id": 123,
        "exp": datetime.now() + timedelta(hours=1)  # Expires in 1 hour
    },
    SECRET_KEY,
    algorithm="HS256"
)

# Verify token
try:
    payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
    user_id = payload["user_id"]
except jwt.ExpiredSignatureError:
    # Token expired - user needs to login again
    raise Unauthorized("Token expired")
except jwt.InvalidTokenError:
    # Token is fake/tampered
    raise Unauthorized("Invalid token")
```

### 3. SQL Injection Prevention

**Vulnerable code** ❌:
```python
# User input: email = "x' OR '1'='1"
query = f"SELECT * FROM users WHERE email = '{email}'"
# Becomes: SELECT * FROM users WHERE email = 'x' OR '1'='1'
# Returns ALL users! (Security breach)
```

**Safe code** ✅:
```python
# Using parameterized queries (SQLAlchemy)
query = db.query(User).filter(User.email == email)
# Email is properly escaped, injection prevented
```

### 4. Rate Limiting

```python
from slowapi import Limiter

limiter = Limiter(key_func=get_remote_address)

@app.post("/api/auth/login")
@limiter.limit("5/minute")  # Max 5 attempts per minute
async def login(credentials: LoginRequest):
    # Prevents brute force attacks
    pass
```

### 5. HTTPS Only

```python
# Redirect HTTP to HTTPS
if not request.is_secure:
    return redirect(request.url.replace("http://", "https://"))

# Set secure cookie flags
response.set_cookie(
    "session_id",
    value=session_id,
    secure=True,      # Only sent over HTTPS
    httponly=True,    # Not accessible via JavaScript
    samesite="strict" # CSRF protection
)
```

### 6. Input Validation

```python
from pydantic import BaseModel, validator

class PaymentRequest(BaseModel):
    amount: float
    receiver_upi: str
    
    @validator('amount')
    def validate_amount(cls, v):
        if v <= 0:
            raise ValueError('Amount must be positive')
        if v > 1000000:
            raise ValueError('Amount too large')
        return v
    
    @validator('receiver_upi')
    def validate_upi(cls, v):
        if not re.match(r'^[\w.-]+@[\w-]+$', v):
            raise ValueError('Invalid UPI format')
        return v
```

### 7. Environment Variables

**Bad** ❌:
```python
DATABASE_URL = "postgresql://user:password@localhost/db"
SECRET_KEY = "mysecretkey123"
```

**Good** ✅:
```python
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
SECRET_KEY = os.getenv("SECRET_KEY")
```

`.env` file (not committed to git!):
```
DATABASE_URL=postgresql://user:password@localhost/db
SECRET_KEY=supersecretkey123...
```

---

# 🎓 Congratulations!

You've learned the complete fraud detection system from scratch!

## What You Now Know

### Level 1: Basics ✅
- What fraud detection is and why it matters
- How backends work
- The difference between fraud and safe payments

### Level 2: Core Concepts ✅
- APIs and HTTP requests/responses
- Databases and tables
- Authentication with JWT tokens

### Level 3: Architecture ✅
- The Risk Orchestrator pattern
- The 5 engines and their roles
- How data flows through the system

### Level 4: Deep Technical ✅
- Context Engine: User behavior analysis
- Rules Engine: Pattern detection
- ML Engine: Predictive modeling
- Decision Engine: Action mapping
- Risk Orchestrator: Coordination

### Level 5: Practical Skills ✅
- Analyzing safe payments
- Detecting risky transactions
- Blocking fraud attempts
- Real-world examples

### Level 6: Advanced Topics ✅
- Trust scoring algorithms
- Caching strategies
- Performance optimization
- Security best practices

## Next Steps

### To Practice:
1. Run the test suite: `python test_complete_flow.py`
2. Try different payment amounts
3. Modify trust scores and see effects
4. Add your own fraud rules

### To Extend:
1. Add more ML features
2. Implement device fingerprinting
3. Build user dashboard
4. Create admin panel
5. Add real-time alerts

### To Learn More:
1. FastAPI documentation
2. Machine learning courses
3. Redis caching patterns
4. Cybersecurity fundamentals
5. System design interviews

---

## Quick Reference Card

### Risk Levels
```
LOW (0-0.30): ✅ Allow
MODERATE (0.30-0.60): ⚠️ Soft Challenge (OTP)
HIGH (0.60-0.80): ⚠️ Hard Challenge (OTP + Call)
VERY_HIGH (0.80-1.00): 🚫 Block
```

### Trust Tiers
```
BRONZE (0-30): New users, more friction
SILVER (31-70): Regular users, normal flow
GOLD (71-100): Trusted users, less friction
```

### Key Formulas
```
Combined Score = (Rules * 0.6) + (ML * 0.4)
Trust Score = 50 + age + txns + success - fraud
Cache Hit Time = 2ms vs DB Query Time = 50ms
```

### API Endpoints
```
POST /api/auth/signup - Create account
POST /api/auth/login - Get JWT token
POST /api/payment/intent - Analyze payment
POST /api/payment/confirm - Process payment
GET /health - System status
GET /metrics - Performance stats
```

---

**You're now a fraud detection expert! 🎉**

Questions? Review any section above or experiment with the code!
