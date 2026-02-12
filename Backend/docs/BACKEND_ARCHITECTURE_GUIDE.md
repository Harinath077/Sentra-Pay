# 🏗️ Backend Architecture Guide
## Fraud Detection System - Complete Architecture

---

## 🧠 Core Principle (CRITICAL)

### ❌ What This Backend is NOT:
```
"ML predicts fraud = block payment"
```

### ✅ What This Backend IS:
```
A risk-orchestration engine that combines:
  - Rules Engine (deterministic fraud patterns)
  - ML Engine (probabilistic risk scoring)
  - Context Engine (user behavior, device, history)
  - Decision Engine (friction-based actions)
```

**This aligns with the UI:** Risk score screen, risk breakdown, trust score, transaction history, warnings before payment.

---

## 🏛️ 5-Layer Architecture

```
┌─────────────────────────────────────┐
│   Frontend (Flutter App)            │
│   - Send Money Screen                │
│   - Risk Analysis Screen             │
│   - Transaction History              │
│   - Profile & Trust Score            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   API Gateway (FastAPI)              │
│   - POST /api/payment/intent         │
│   - POST /api/payment/confirm        │
│   - POST /api/risk/analyze           │
│   - GET  /api/user/profile           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Risk Orchestrator (THE BRAIN)      │
│   - Coordinates all risk checks      │
│   - Combines multiple signals        │
│   - Produces unified risk score      │
└──────────────┬──────────────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
┌─────────────┐ ┌─────────────┐
│ Rules Engine│ │  ML Engine  │
│ (Fast/Hard) │ │  (Soft)     │
└──────┬──────┘ └──────┬──────┘
       │               │
       └───────┬───────┘
               ▼
┌─────────────────────────────────────┐
│   Decision Engine                    │
│   - Maps risk → action               │
│   - Determines friction level        │
└──────────────┬──────────────────────┘
               ▼
┌─────────────────────────────────────┐
│   Data Layer                         │
│   - PostgreSQL (users, txns, events) │
│   - Redis Cache (profiles, scores)   │
│   - ML Model Storage (CatBoost)      │
└─────────────────────────────────────┘
```

---

## 🔄 Transaction Flow (12 Steps)

### Step 1-2: User Initiates Transaction
```
1. User enters ₹9,000,000 to "SriRam@upi" (Unknown Receiver)
2. Flutter App → POST /api/payment/intent
```

### Step 3-6: User Context Retrieval
```
3. Backend → Redis Cache: GET user:12345
4. Redis → Backend: cached_data or null
5. [If cache miss] Backend → PostgreSQL: SELECT * FROM users WHERE id = 12345
6. PostgreSQL → Backend: user_profile (trust_score, known_devices, txn_history)
```

### Step 7-10: Risk Analysis
```
7. Backend → Feature Engineering: extract_features(transaction, user_profile)
8. Feature Engineering → ML Model: 14 features
   - amount_to_avg_ratio
   - is_new_receiver
   - txn_velocity_5min
   - device_change_flag
   - hour_of_day
   - ... (11 more)
9. ML Model → Backend: {"probability": 0.55, "prediction": 0}
10. Rules Engine → Backend: 
    - New receiver: +0.15
    - High amount: +0.20
    - Velocity spike: +0.10
```

### Step 11-12: Final Decision
```
11. Backend → PostgreSQL: INSERT INTO transactions (risk_score=0.55, risk_bucket="MODERATE")
12. Backend → Flutter App: 
    {
      "risk_score": 0.55,
      "risk_level": "MODERATE",
      "risk_breakdown": {
        "behavior_analysis": 30,
        "amount_analysis": 100,
        "receiver_analysis": 40
      },
      "action": "WARNING",
      "message": "This transaction has moderate risk. Review before proceeding."
    }
```

---

## 🎯 Component Details

### 1. API Gateway (FastAPI)
**File:** `app/main.py`, `app/routers/`

**Endpoints:**
```python
# Payment Flow
POST /api/payment/intent       # Analyze transaction risk
POST /api/payment/confirm      # Finalize payment after user confirmation

# Risk Analysis
POST /api/risk/analyze         # Get detailed risk breakdown

# User Management
GET  /api/user/profile         # User profile + trust score
GET  /api/user/trust-score     # Trust score evolution

# Transaction History
GET  /api/transactions         # Recent transactions with risk scores
GET  /api/risk/trend           # Risk trend over time
```

---

### 2. Risk Orchestrator (THE BRAIN)
**File:** `app/core/risk_orchestrator.py`

**Responsibilities:**
1. Receive transaction intent
2. Gather user context (cache → DB)
3. Run rules engine checks
4. Run ML model prediction
5. Combine scores (weighted)
6. Map to risk bucket
7. Determine action (ALLOW/WARNING/OTP/BLOCK)
8. Return structured response

**Pseudo-code:**
```python
def analyze_transaction(txn_data, user_id):
    # 1. Get user context
    user = get_user_context(user_id)
    
    # 2. Rules engine (fast checks)
    rule_score, rule_flags = rules_engine.evaluate(txn_data, user)
    
    # 3. ML engine (if needed)
    ml_score = ml_engine.predict(txn_data, user)
    
    # 4. Combine scores
    final_score = combine_scores(rule_score, ml_score, rule_flags)
    
    # 5. Determine action
    action = decision_engine.get_action(final_score, rule_flags)
    
    # 6. Return risk analysis
    return {
        "risk_score": final_score,
        "risk_level": get_risk_level(final_score),
        "risk_breakdown": get_breakdown(rule_score, ml_score),
        "action": action,
        "factors": get_risk_factors(rule_flags)
    }
```

---

### 3. Rules Engine (Deterministic)
**File:** `app/core/rules_engine.py`

**Key Rules:**

#### Rule 1: Velocity Check
```python
if txn_count_last_5min >= 5 and days_since_last_txn > 7:
    risk += 0.25
    flags.append("VELOCITY_SPIKE")
```

#### Rule 2: New Receiver + High Amount
```python
if is_new_receiver and amount > 3 * avg_amount_30d:
    risk += 0.30
    flags.append("NEW_RECEIVER_HIGH_AMOUNT")
```

#### Rule 3: Blacklisted Receiver
```python
if receiver in blacklist:
    return HARD_BLOCK  # Override everything
```

#### Rule 4: Device/SIM Change
```python
if device_id not in known_devices:
    require_otp = True
    risk += 0.15
```

#### Rule 5: Unusual Time
```python
if hour_of_day in [0, 1, 2, 3, 4]:
    risk += 0.10
    flags.append("UNUSUAL_TIME")
```

**📌 Important:** Rules can override ML scores. This is how real banks work.

---

### 4. ML Engine (Probabilistic)
**File:** `app/core/ml_engine.py`

**What ML Does:**
- Receives 14 engineered features
- Returns risk probability (0.0 - 1.0)
- **Does NOT make final decision**

**Features (14):**
1. `amount_to_avg_ratio`
2. `is_new_receiver`
3. `txn_velocity_5min`
4. `txn_velocity_1hour`
5. `days_since_last_txn`
6. `hour_of_day`
7. `day_of_week`
8. `device_change_flag`
9. `receiver_reputation_score`
10. `avg_amount_30d`
11. `max_amount_30d`
12. `failed_txn_count_7d`
13. `user_tenure_days`
14. `trust_score`

**Model:** CatBoost Classifier
- `iterations=1000`
- `depth=6`
- `learning_rate=0.1`

**Usage:**
```python
ml_score = model.predict_proba(features)[1]  # Probability of fraud
```

**📌 ML does NOT decide, ML does NOT block**

---

### 5. Decision Engine (Maps to UI)
**File:** `app/core/decision_engine.py`

**Risk Buckets:**
| Risk Score | Bucket | Color | UI Treatment |
|------------|--------|-------|--------------|
| 0.00 - 0.30 | LOW | Green | Allow |
| 0.30 - 0.60 | MODERATE | Orange | Show Warning |
| 0.60 - 0.80 | HIGH | Red | Require OTP + Delay |
| 0.80 - 1.00 | VERY HIGH | Dark Red | Block |

**Actions:**
```python
def get_action(risk_score, rule_flags):
    # Hard blocks override everything
    if "BLACKLISTED" in rule_flags:
        return "BLOCK"
    
    # Risk-based actions
    if risk_score < 0.30:
        return "ALLOW"
    elif risk_score < 0.60:
        return "WARNING"
    elif risk_score < 0.80:
        return "OTP_REQUIRED"
    else:
        return "BLOCK"
```

---

### 6. Context Engine
**File:** `app/core/context_engine.py`

**Responsibilities:**
- Fetch user profile (cache-first)
- Calculate transaction velocity
- Check device fingerprint
- Retrieve receiver reputation
- Build user behavior history

**Cache Strategy:**
```python
def get_user_context(user_id):
    # Try Redis first (fast)
    cached = redis.get(f"user:{user_id}")
    if cached:
        return cached
    
    # Fallback to PostgreSQL
    user = db.query(User).filter(User.id == user_id).first()
    
    # Cache for next time (TTL: 5 minutes)
    redis.setex(f"user:{user_id}", 300, user)
    
    return user
```

---

## 🗄️ Database Design

### Table: `users`
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    trust_score FLOAT DEFAULT 0.0,
    risk_tier VARCHAR(20) DEFAULT 'BRONZE',
    known_devices JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Table: `transactions`
```sql
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    amount DECIMAL(15, 2) NOT NULL,
    receiver VARCHAR(255) NOT NULL,
    risk_score FLOAT,
    risk_bucket VARCHAR(20),
    action_taken VARCHAR(20),
    ml_score FLOAT,
    rule_score FLOAT,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Table: `risk_events`
```sql
CREATE TABLE risk_events (
    id SERIAL PRIMARY KEY,
    txn_id INTEGER REFERENCES transactions(id),
    rule_triggered VARCHAR(50),
    ml_score FLOAT,
    final_score FLOAT,
    action VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Table: `receiver_reputation`
```sql
CREATE TABLE receiver_reputation (
    receiver VARCHAR(255) PRIMARY KEY,
    total_transactions INTEGER DEFAULT 0,
    fraud_count INTEGER DEFAULT 0,
    reputation_score FLOAT DEFAULT 0.5,
    last_updated TIMESTAMP DEFAULT NOW()
);
```

---

## 🏆 Trust Score System

**Trust score is NOT ML.** It's a slow-moving user reputation metric.

### Calculation Logic:
```python
def update_trust_score(user_id, event):
    if event == "SUCCESSFUL_TXN":
        trust += 1
    elif event == "FRAUD_REPORTED":
        trust -= 10
    elif event == "FREQUENT_HIGH_RISK":
        trust -= 2
    elif event == "OTP_FAILED":
        trust -= 1
    elif event == "KYC_VERIFIED":
        trust += 5
    
    # Normalize to 0-100
    trust_score = max(0, min(100, trust))
```

### Trust Tiers:
| Score | Tier | Benefits |
|-------|------|----------|
| 0-30 | BRONZE | Standard checks |
| 31-70 | SILVER | Reduced friction |
| 71-100 | GOLD | Fast-track |

---

## 🎬 Demo Flow (For Judges)

### Scenario: ₹9,00,000 to Unknown Receiver

**Step 1:** User enters transaction
```json
{
  "amount": 9000000,
  "receiver": "SriRam@upi"
}
```

**Step 2:** Backend analyzes
```
Rules Engine:
- New receiver: +0.15
- Amount > 3x avg: +0.20
- No blacklist hit: 0

ML Engine:
- ML Score: 0.20

Combined: 0.55
```

**Step 3:** Backend responds
```json
{
  "risk_score": 0.55,
  "risk_level": "MODERATE",
  "risk_breakdown": {
    "behavior_analysis": 30,
    "amount_analysis": 100,
    "receiver_analysis": 40
  },
  "action": "WARNING",
  "message": "This transaction has moderate risk factors."
}
```

**Step 4:** UI shows Risk Analysis Screen

**Step 5:** User clicks "Proceed with Payment"
- OTP triggered
- 30-second delay
- Payment proceeds

**📌 Fraud prevented by friction, not ML perfection**

---

## 🚀 Performance Optimizations

1. **Redis Caching**: 80%+ cache hit rate
2. **Connection Pooling**: 20 PostgreSQL connections
3. **Async I/O**: FastAPI async endpoints
4. **ML Model Preloading**: Load on startup
5. **Feature Caching**: Cache engineered features for 5 min
6. **Database Indexing**: Index on user_id, receiver, created_at

**Target Performance:**
- API Response Time: < 200ms (p95)
- ML Inference: < 50ms
- Database Query: < 30ms
- Cache Lookup: < 5ms

---

## 🧪 Testing Strategy

### 1. Unit Tests
- Rules engine logic
- ML feature engineering
- Score combination
- Decision mapping

### 2. Integration Tests
- API endpoint flows
- Database operations
- Cache behavior
- ML model integration

### 3. Load Tests
- 1000 requests/sec
- Concurrent user sessions
- Cache hit rate validation

---

## 🏆 Why Judges Will Love This

✅ **Real backend thinking** - Not just CRUD APIs  
✅ **Correct fraud philosophy** - Friction > blocking  
✅ **Layered security** - Rules + ML + context  
✅ **Honest ML usage** - ML assists, doesn't decide  
✅ **Strong UI ↔ Backend alignment** - Every UI screen maps to backend logic  
✅ **Production-ready** - Caching, async, optimizations  
✅ **Explainable** - Risk breakdown visible to user  

---

## 📚 Related Documents
- [API Specifications](./API_SPECIFICATIONS.md)
- [Risk Orchestrator Design](./RISK_ORCHESTRATOR_DESIGN.md)
- [ML Pipeline](../PIPELINE.md)
- [Database Schema](./DATABASE_SCHEMA.md)

---

**Last Updated:** February 3, 2026  
**Architecture Version:** 2.0  
**Status:** Ready for Implementation 🚀
