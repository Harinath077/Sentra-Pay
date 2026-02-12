# 🏗️ Backend Architecture Guide - UPI Fraud Detection System

## 📊 Visual Flow Diagrams

This guide provides a visual understanding of the backend architecture for the UPI Risk Scoring application. Refer to the generated diagrams for a complete picture.

---

## 🎯 System Overview

The backend is a **FastAPI-based microservice** that provides:
1. **User Authentication** - Signup, login, and profile management
2. **Risk Analysis** - ML-powered fraud detection for UPI transactions
3. **Data Persistence** - PostgreSQL for storage, Redis for caching
4. **ML Pipeline** - CatBoost model training and real-time inference

---

## 📐 Architecture Layers

### **1. Client Layer**
- **Flutter Mobile App** communicates with backend via REST APIs
- All requests use JSON format
- CORS enabled for web/mobile access

### **2. API Layer (FastAPI)**
Three main endpoint groups:

#### **Authentication APIs**
```
POST /signup
POST /login
```
- Handles user registration and authentication
- Generates unique user IDs and security tokens
- Returns complete user profile

#### **Risk Analysis API**
```
POST /check-transaction
```
- Receives transaction details (user_id, receiver_upi, amount)
- Orchestrates feature engineering and ML prediction
- Returns risk score, category, and decision

#### **Services Layer**
- **Auth Service**: User management logic
- **User Service**: Profile and transaction history
- **ML Service**: Model loading and prediction

### **3. Data Layer**

#### **PostgreSQL Database**
Three main tables:
- **users**: User profiles, trust scores, behavioral data
- **transactions**: Transaction history and risk results
- **receiver_reputation**: UPI ID reputation scores

#### **Redis Cache**
- Caches user profiles (30 min TTL)
- Caches receiver reputation (1 hour TTL)
- Reduces database load by 70%+

#### **ML Model Storage**
- Trained CatBoost model saved as `.cbm` file
- Loaded once at startup (singleton pattern)
- Version controlled for model updates

---

## 🔄 Transaction Flow (Step-by-Step)

### **User Initiates Transaction**
1. User enters amount and receiver UPI in Flutter app
2. App calls `POST /check-transaction` with transaction data

### **Backend Processing**
3. Backend checks Redis cache for user profile
4. If cache miss, queries PostgreSQL for user data
5. Sends transaction data to Feature Engineering module

### **Feature Engineering**
6. Extracts 14 features:
   - **User Behavior**: login_count, transaction_count, trust_score, account_age
   - **Amount Analysis**: amount, avg_amount, amount_ratio, is_large_amount
   - **Receiver Analysis**: is_known_receiver, receiver_reputation, is_first_time
   - **Temporal**: hour_of_day, day_of_week, time_since_last_txn

### **ML Prediction**
7. Features fed to CatBoost model
8. Model returns fraud probability (0.0 to 1.0)
9. Backend categorizes risk:
   - **LOW** (< 0.35): Allow transaction
   - **MEDIUM** (0.35-0.65): Request verification
   - **HIGH** (> 0.65): Block transaction

### **Response**
10. Backend saves transaction result to PostgreSQL
11. Returns risk analysis to Flutter app:
```json
{
  "risk_level": "MEDIUM",
  "risk_score_numeric": 0.45,
  "factors": ["First-time receiver", "Large amount"],
  "decision": "VERIFY",
  "confidence": 0.87
}
```

---

## 🤖 ML Pipeline Workflow

### **Phase 1: Data Collection**
- Collect historical transaction data from PostgreSQL
- Gather user behavior patterns
- Aggregate receiver reputation scores

### **Phase 2: Data Processing**
- **Feature Engineering**: Extract 14 predictive features
- **Data Cleaning**: Handle missing values, outliers
- **Train/Test Split**: 80% training, 20% testing

### **Phase 3: Model Training**
- **Algorithm**: CatBoost Classifier
- **Hyperparameters**:
  - iterations: 1000
  - depth: 6
  - learning_rate: 0.1
- **Validation**: 5-fold cross-validation
- **Optimization**: Grid search for best parameters

### **Phase 4: Model Evaluation**
Target metrics:
- **AUC Score**: > 0.90 (excellent discrimination)
- **Precision**: > 0.85 (minimize false positives)
- **Recall**: > 0.80 (catch most fraud cases)
- **F1 Score**: > 0.82 (balanced performance)

### **Phase 5: Model Deployment**
- Export model as `fraud_classifier.cbm`
- Version control (v1.0, v1.1, etc.)
- Load into FastAPI backend at startup
- Monitor performance in production

### **Phase 6: Continuous Improvement**
- Collect new transaction data
- Retrain model monthly with updated data
- A/B test new model versions
- Deploy best-performing model

---

## 🔐 Security Architecture

### **Input Validation**
- All requests validated with Pydantic schemas
- Type checking and constraint enforcement
- Prevents injection attacks

### **Database Security**
- SQLAlchemy ORM (parameterized queries)
- No raw SQL execution
- Connection pooling with encryption

### **CORS Configuration**
```python
origins = [
    "http://localhost:3000",
    "http://localhost:5173",
    "https://yourdomain.com"
]
```

### **Rate Limiting**
- 100 requests per minute per IP
- Prevents DDoS and abuse
- Uses `slowapi` middleware

### **Environment Variables**
- All secrets in `.env` file
- Never committed to Git
- Different configs for dev/prod

---

## ⚡ Performance Optimizations

### **1. Caching Strategy**
```
Request → Check Redis → If miss → Query PostgreSQL → Cache result
```
- **Hit Rate Target**: > 80%
- **Response Time**: < 50ms for cache hits

### **2. Database Indexing**
```sql
CREATE INDEX idx_users_mobile ON users(mobile);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
```
- Speeds up lookups by 10-100x

### **3. Async Operations**
- All I/O operations use `async`/`await`
- Non-blocking database queries
- Concurrent request handling

### **4. Model Optimization**
- Load model once at startup (singleton)
- Keep in memory (no disk I/O per request)
- Batch predictions if possible

### **5. Connection Pooling**
- PostgreSQL: 20 connections max
- Redis: 10 connections max
- Reuse connections across requests

---

## 📊 API Response Times (Target)

| Endpoint | Target | Optimized |
|----------|--------|-----------|
| POST /signup | < 200ms | < 150ms |
| POST /login | < 100ms | < 50ms (cached) |
| POST /check-transaction | < 300ms | < 200ms |

---

## 🧪 Testing Strategy

### **Unit Tests**
- Test individual functions (feature extraction, risk calculation)
- Mock database and ML model
- Coverage target: > 80%

### **Integration Tests**
- Test API endpoints end-to-end
- Use test database
- Verify request/response formats

### **Load Tests**
- Simulate 100+ concurrent users
- Measure response times under load
- Identify bottlenecks

### **ML Model Tests**
- Test prediction accuracy on holdout set
- Verify feature engineering logic
- Check edge cases (missing data, extreme values)

---

## 🐳 Deployment Architecture

### **Development Environment**
```bash
# Local development
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### **Production Environment (Docker)**
```yaml
services:
  - FastAPI Backend (port 8000)
  - PostgreSQL Database (port 5432)
  - Redis Cache (port 6379)
```

### **Scaling Strategy**
- **Horizontal Scaling**: Multiple FastAPI instances behind load balancer
- **Database Replication**: Read replicas for queries
- **Redis Cluster**: Distributed caching
- **CDN**: Static assets and API responses

---

## 📈 Monitoring & Logging

### **Metrics to Track**
- Request count per endpoint
- Average response time
- Error rate (4xx, 5xx)
- ML model accuracy in production
- Database query performance
- Cache hit rate

### **Logging**
```python
import logging

logging.info(f"Transaction analyzed: user={user_id}, risk={risk_score}")
logging.error(f"Database error: {error}")
```

### **Alerting**
- Alert if error rate > 5%
- Alert if response time > 500ms
- Alert if ML accuracy drops below 85%

---

## 🚀 Quick Start Checklist

- [ ] Install Python 3.10+
- [ ] Create virtual environment
- [ ] Install dependencies (`pip install -r requirements.txt`)
- [ ] Setup PostgreSQL database
- [ ] Setup Redis server
- [ ] Create `.env` file with credentials
- [ ] Train ML model (`python -m app.ml.model_trainer`)
- [ ] Run migrations (if using Alembic)
- [ ] Start FastAPI server (`uvicorn app.main:app --reload`)
- [ ] Test endpoints at `http://localhost:8000/docs`
- [ ] Connect Flutter app to backend
- [ ] Run tests (`pytest`)
- [ ] Deploy with Docker Compose

---

## 🎯 Success Metrics

Your backend is production-ready when:
- ✅ All API endpoints return correct responses
- ✅ ML model achieves > 90% AUC score
- ✅ Average response time < 200ms
- ✅ Database queries use proper indexes
- ✅ Redis cache hit rate > 80%
- ✅ Test coverage > 80%
- ✅ Docker containers run successfully
- ✅ Flutter app integrates seamlessly
- ✅ Handles 100+ concurrent requests
- ✅ Error rate < 1%

---

## 📚 Key Technologies Summary

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Web Framework** | FastAPI | REST API endpoints |
| **Language** | Python 3.10+ | Backend logic |
| **Database** | PostgreSQL | Persistent storage |
| **Cache** | Redis | Performance optimization |
| **ML Model** | CatBoost | Fraud detection |
| **ORM** | SQLAlchemy | Database abstraction |
| **Validation** | Pydantic | Request/response schemas |
| **Server** | Uvicorn | ASGI server |
| **Containerization** | Docker | Deployment |

---

## 🔗 Integration with Flutter App

### **API Base URL Configuration**
```dart
// lib/services/api_service.dart
static const String baseUrl = "http://localhost:8000";
```

### **Expected Request/Response Format**

**Signup Request**:
```dart
{
  "name": "Gopal",
  "phone": "9876543210"
}
```

**Login Request**:
```dart
{
  "phone": "9876543210"
}
```

**Risk Check Request**:
```dart
{
  "user_id": "UID-DEMO-001",
  "receiver_upi": "merchant@upi",
  "amount": 5000.0
}
```

---

## 💡 Best Practices

1. **Always validate inputs** - Use Pydantic models
2. **Cache aggressively** - Reduce database load
3. **Log everything** - Debug issues quickly
4. **Monitor performance** - Catch problems early
5. **Version your APIs** - Support backward compatibility
6. **Document endpoints** - Auto-generated Swagger docs
7. **Test thoroughly** - Unit, integration, and load tests
8. **Secure by default** - HTTPS, rate limiting, input validation
9. **Optimize queries** - Use indexes, avoid N+1 queries
10. **Keep models updated** - Retrain with new data regularly

---

## 🎓 Learning Resources

- **FastAPI Docs**: https://fastapi.tiangolo.com/
- **CatBoost Docs**: https://catboost.ai/
- **SQLAlchemy Docs**: https://docs.sqlalchemy.org/
- **Redis Docs**: https://redis.io/documentation
- **PostgreSQL Docs**: https://www.postgresql.org/docs/

---

## 🤝 Support & Maintenance

### **Common Issues**

**Issue**: Database connection error
**Solution**: Check PostgreSQL is running, verify credentials in `.env`

**Issue**: ML model not found
**Solution**: Run `python -m app.ml.model_trainer` to train model

**Issue**: CORS error from Flutter
**Solution**: Add Flutter app URL to CORS origins in `main.py`

**Issue**: Slow response times
**Solution**: Check Redis is running, verify database indexes

---

## 📝 Next Steps

1. **Review the development prompt** (`BACKEND_DEVELOPMENT_PROMPT.md`)
2. **Study the flow diagrams** (architecture, sequence, ML pipeline)
3. **Setup development environment**
4. **Implement core APIs** (signup, login, check-transaction)
5. **Train ML model** with sample data
6. **Test with Flutter app**
7. **Optimize performance**
8. **Deploy to production**

---

**Built with ❤️ for secure UPI transactions**
