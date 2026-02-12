# 🚀 Development Pipeline
## Fraud Detection Backend - Implementation Guide

---

## 🧠 Core Architecture Principle

**This backend is a Risk Orchestration Engine that:**
- Combines Rules Engine (deterministic) + ML Engine (probabilistic) + Context Engine (user behavior)
- Produces unified risk scores with detailed breakdowns
- Determines friction-based actions (not just block/allow)
- Provides explainable risk analysis to users

📖 **See [Backend Architecture Guide](./docs/BACKEND_ARCHITECTURE_GUIDE.md) for complete details**

---

## ✅ Structure Created
- [x] Directory structure
- [x] Config files
- [x] All module files with TODO comments
- [x] Complete architecture documentation
- [x] API specifications
- [x] Database schema design
- [x] Risk orchestrator design

---

## 📋 Implementation Checklist

### Phase 1: Foundation & Database
**Files:** `app/config.py`, `app/database/`

- [ ] Implement `app/config.py` - Load environment variables
- [ ] Implement `app/database/connection.py` - PostgreSQL setup with connection pooling
- [ ] Implement `app/database/models.py` - SQLAlchemy models (users, transactions, risk_events, receiver_reputation)
- [ ] Implement `app/database/redis_client.py` - Redis connection with TTL configuration
- [ ] Run Alembic migrations to create database schema

**Documentation:** [Database Schema](./docs/DATABASE_SCHEMA.md)

**Validation:**
```bash
# Test database connection
python -c "from app.database.connection import get_db; print('DB Connected')"

# Test Redis connection
python -c "from app.database.redis_client import redis_client; redis_client.ping()"
```

---

### Phase 2: Authentication & User Management
**Files:** `app/services/auth_service.py`, `app/routers/auth.py`

- [ ] Implement `app/utils/security.py` - Password hashing (bcrypt), JWT token generation/validation
- [ ] Implement `app/services/auth_service.py` - User signup, login, token validation
- [ ] Implement `app/routers/auth.py` - `/signup`, `/login` endpoints
- [ ] Implement `app/models/auth.py` - Pydantic models for requests/responses

**API Endpoints:**
- `POST /api/auth/signup` - Register new user
- `POST /api/auth/login` - Authenticate and get JWT token

**Documentation:** [API Specifications - Authentication](./docs/API_SPECIFICATIONS.md#1️⃣-authentication-apis)

**Validation:**
```bash
# Test signup
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com", "password":"Test123!", "full_name":"Test User"}'

# Test login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com", "password":"Test123!"}'
```

---

### Phase 3: Core Risk Engine (🔥 MOST IMPORTANT)
**Files:** `app/core/`

This is the brain of the system. Implement in this order:

#### 3.1 Context Engine
**File:** `app/core/context_engine.py`

- [ ] Implement `get_user_context(user_id)` - Fetch user profile (Redis → PostgreSQL fallback)
- [ ] Implement `get_transaction_history(user_id, days)` - Get recent transactions
- [ ] Implement `calculate_velocity(user_id)` - Count transactions in last 5min/1hour
- [ ] Implement `get_receiver_reputation(receiver)` - Fetch receiver reputation score
- [ ] Implement `check_new_receiver(user_id, receiver)` - Check if receiver is new

**Key Functions:**
```python
def get_user_context(user_id: str) -> UserContext:
    """
    Returns:
    - user_profile (trust_score, risk_tier, known_devices)
    - txn_history (last 30 days)
    - avg_amount_30d, max_amount_30d
    - txn_count_5min, txn_count_1hour
    """
```

---

#### 3.2 Rules Engine
**File:** `app/core/rules_engine.py`

- [ ] Implement velocity rules (5min, 1hour)
- [ ] Implement new receiver + high amount rule
- [ ] Implement blacklist check (hard block)
- [ ] Implement device change detection
- [ ] Implement unusual time pattern detection
- [ ] Implement amount anomaly detection (vs. user's avg)

**Key Rules:**
```python
# Rule 1: Velocity Spike
if txn_count_5min >= 5 and days_since_last_txn > 7:
    rule_score += 0.25
    flags.append("VELOCITY_SPIKE")

# Rule 2: New Receiver + High Amount
if is_new_receiver and amount > 3 * avg_amount_30d:
    rule_score += 0.30
    flags.append("NEW_RECEIVER_HIGH_AMOUNT")

# Rule 3: Blacklist (HARD BLOCK)
if receiver in blacklist:
    return {"hard_block": True, "reason": "BLACKLISTED"}
```

**Documentation:** [Backend Architecture - Rules Engine](./docs/BACKEND_ARCHITECTURE_GUIDE.md#3-rules-engine-deterministic)

---

#### 3.3 ML Engine
**File:** `app/core/ml_engine.py`

- [ ] Load CatBoost model on startup
- [ ] Implement feature engineering (14 features)
- [ ] Implement `predict(txn_data, context)` - Return ML probability
- [ ] Cache feature engineering for performance

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

**Key Function:**
```python
def predict(txn_data: dict, context: UserContext) -> MLResult:
    features = engineer_features(txn_data, context)
    ml_score = model.predict_proba(features)[1]
    return {"ml_score": ml_score, "features": features}
```

**Documentation:** [Backend Architecture - ML Engine](./docs/BACKEND_ARCHITECTURE_GUIDE.md#4-ml-engine-probabilistic)

---

#### 3.4 Decision Engine
**File:** `app/core/decision_engine.py`

- [ ] Implement risk bucket mapping (LOW, MODERATE, HIGH, VERY_HIGH)
- [ ] Implement action determination (ALLOW, WARNING, OTP_REQUIRED, BLOCK)
- [ ] Implement tier-based adjustments (BRONZE, SILVER, GOLD)

**Risk Buckets:**
| Score | Bucket | Action |
|-------|--------|--------|
| 0.00-0.30 | LOW | ALLOW |
| 0.30-0.60 | MODERATE | WARNING |
| 0.60-0.80 | HIGH | OTP_REQUIRED |
| 0.80-1.00 | VERY_HIGH | BLOCK |

**Documentation:** [Backend Architecture - Decision Engine](./docs/BACKEND_ARCHITECTURE_GUIDE.md#5-decision-engine-maps-to-ui)

---

#### 3.5 Risk Orchestrator (THE BRAIN)
**File:** `app/core/risk_orchestrator.py`

- [ ] Implement `analyze_transaction(txn_data, user_id)` - Main orchestration method
- [ ] Coordinate: Context → Rules → ML → Decision
- [ ] Implement score combination logic (weighted average with rule overrides)
- [ ] Build risk breakdown (behavior, amount, receiver analysis)
- [ ] Generate risk factors and recommendations
- [ ] Log risk events to database

**Flow:**
```
1. Get user context
2. Run rules engine → rule_score, flags
3. Run ML engine → ml_score
4. Combine scores (weighted)
5. Map to action (decision engine)
6. Build response (risk breakdown, factors, recommendations)
7. Log event
```

**Documentation:** [Risk Orchestrator Design](./docs/RISK_ORCHESTRATOR_DESIGN.md)

**Validation:**
```python
# Test orchestrator
result = orchestrator.analyze_transaction(
    txn_data={"amount": 9000000, "receiver": "unknown@upi"},
    user_id="USER-123"
)
print(result["risk_score"])  # Should be 0.55
print(result["action"])      # Should be "WARNING"
```

---

### Phase 4: Payment Flow APIs
**Files:** `app/routers/payment.py`, `app/models/payment.py`

- [ ] Implement `POST /api/payment/intent` - Analyze transaction before payment
- [ ] Implement `POST /api/payment/confirm` - Finalize payment after user review
- [ ] Implement payment status tracking
- [ ] Save transaction to database with risk analysis

**API Endpoints:**
- `POST /api/payment/intent` - Returns risk analysis
- `POST /api/payment/confirm` - Processes payment

**Documentation:** [API Specifications - Payment APIs](./docs/API_SPECIFICATIONS.md#2️⃣-payment-apis)

**Validation:**
```bash
# Test payment intent
curl -X POST http://localhost:8000/api/payment/intent \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"amount": 9000000, "receiver": "SriRam@upi"}'
```

---

### Phase 5: Services Layer
**Files:** `app/services/`

#### 5.1 Trust Service
**File:** `app/services/trust_service.py`

- [ ] Implement `update_trust_score(user_id, event)` - Update trust based on events
- [ ] Implement `calculate_trust_tier(trust_score)` - Map score to tier (BRONZE/SILVER/GOLD)
- [ ] Implement trust score history tracking

**Events:**
- `SUCCESSFUL_TXN`: +1
- `FRAUD_REPORTED`: -10
- `FREQUENT_HIGH_RISK`: -2
- `OTP_FAILED`: -1
- `KYC_VERIFIED`: +5

---

#### 5.2 Cache Service
**File:** `app/services/cache_service.py`

- [ ] Implement user profile caching (TTL: 5 min)
- [ ] Implement receiver reputation caching (TTL: 10 min)
- [ ] Implement cache invalidation on updates
- [ ] Monitor cache hit rate (target: 80%+)

---

### Phase 6: User & Transaction APIs
**Files:** `app/routers/user.py`, `app/routers/transaction.py`

#### 6.1 User Profile APIs
- [ ] `GET /api/user/profile` - Get user profile with trust score
- [ ] `GET /api/user/trust-score` - Get trust score evolution

#### 6.2 Transaction History APIs
- [ ] `GET /api/transactions` - Get recent transactions with risk scores
- [ ] `GET /api/transactions/:id` - Get detailed transaction info
- [ ] `GET /api/risk/trend` - Get risk trend over time

**Documentation:** [API Specifications - User & Transaction APIs](./docs/API_SPECIFICATIONS.md#4️⃣-user-profile-apis)

---

### Phase 7: Main Application Setup
**File:** `app/main.py`

- [ ] Wire all routers together
- [ ] Add CORS middleware for Flutter app
- [ ] Add authentication middleware
- [ ] Add rate limiting middleware
- [ ] Load ML model on startup
- [ ] Add health check endpoint
- [ ] Add API documentation (Swagger)

**Startup Tasks:**
```python
@app.on_event("startup")
async def startup_event():
    # Load ML model
    global ml_model
    ml_model = load_catboost_model("ml_models/fraud_model.cbm")
    
    # Test database connection
    test_db_connection()
    
    # Test Redis connection
    test_redis_connection()
```

---

### Phase 8: Testing & Validation
**Files:** `tests/`

- [ ] Write unit tests for rules engine
- [ ] Write unit tests for ML feature engineering
- [ ] Write unit tests for score combination logic
- [ ] Write integration tests for API endpoints
- [ ] Write end-to-end tests for payment flow
- [ ] Load testing (1000 req/sec)

**Run Tests:**
```bash
pytest tests/ -v
pytest tests/test_payment.py -v
```

---

## 🎯 Priority Order (CRITICAL PATH)

**Week 1: Foundation**
1. Database setup (Phase 1)
2. Authentication (Phase 2)

**Week 2: Core Engine (Most Important)**
3. Context Engine (Phase 3.1)
4. Rules Engine (Phase 3.2)
5. ML Engine (Phase 3.3)
6. Decision Engine (Phase 3.4)
7. Risk Orchestrator (Phase 3.5)

**Week 3: APIs & Integration**
8. Payment APIs (Phase 4)
9. User/Transaction APIs (Phase 6)
10. Services Layer (Phase 5)
11. Main App (Phase 7)

**Week 4: Testing & Polish**
12. Testing (Phase 8)
13. Performance optimization
14. Documentation

---

## 🚀 Quick Start Commands

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Setup environment
cp .env.example .env
# Edit .env with your database credentials

# 3. Start PostgreSQL and Redis
docker-compose up -d

# 4. Run database migrations
alembic upgrade head

# 5. Start development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 6. Access API documentation
# http://localhost:8000/docs
```

---

## 📊 Key Decisions

| Component | Technology | Reason |
|-----------|-----------|---------|
| Framework | FastAPI | Modern, fast, auto-docs |
| Database | PostgreSQL | Relational, ACID, complex queries |
| Cache | Redis | In-memory, fast, TTL support |
| ML Model | CatBoost | High accuracy, fast inference |
| Auth | JWT | Stateless, scalable |
| Pattern | Risk Orchestrator | Flexible, explainable, production-ready |

---

## 📚 Documentation

All architecture details are in the `docs/` folder:

1. **[Backend Architecture Guide](./docs/BACKEND_ARCHITECTURE_GUIDE.md)** - Complete system architecture
2. **[API Specifications](./docs/API_SPECIFICATIONS.md)** - All API endpoints with examples
3. **[Risk Orchestrator Design](./docs/RISK_ORCHESTRATOR_DESIGN.md)** - Core engine design
4. **[Database Schema](./docs/DATABASE_SCHEMA.md)** - Database tables and queries

---

## 🏆 Success Metrics

**Performance Targets:**
- API Response Time: < 200ms (p95)
- ML Inference: < 50ms
- Cache Hit Rate: > 80%
- Database Query: < 30ms

**Quality Targets:**
- Test Coverage: > 80%
- API Documentation: 100%
- Zero P0 bugs before demo

---

## 🎬 Demo Flow (For Judges)

**Scenario:** User sends ₹9,000,000 to unknown receiver

1. **User enters transaction** in Flutter app
2. **Backend analyzes** via Risk Orchestrator:
   - Rules: New receiver (+0.15), High amount (+0.20)
   - ML: Score 0.20
   - Combined: 0.55 (MODERATE)
3. **Backend responds** with detailed risk breakdown
4. **UI shows Risk Analysis Screen** with:
   - 55% risk score
   - Behavior: 30%, Amount: 100%, Receiver: 40%
   - Recommendations
5. **User reviews and confirms**
6. **Payment proceeds** with warning

**Key Message to Judges:**
> "We prevent fraud through friction and transparency, not just blocking. Our Risk Orchestrator combines rule-based fraud detection with ML, giving users full visibility into why a transaction is risky."

---

**Last Updated:** February 3, 2026  
**Pipeline Version:** 2.0  
**Status:** Ready for Implementation 🚀
