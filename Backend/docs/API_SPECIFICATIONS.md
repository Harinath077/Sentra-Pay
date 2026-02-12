# 📡 API Specifications
## Complete REST API Documentation

---

## 🔐 Authentication

All protected endpoints require JWT token in header:
```
Authorization: Bearer <jwt_token>
```

---

## 1️⃣ Authentication APIs

### POST `/api/auth/signup`
Register a new user.

**Request:**
```json
{
  "email": "gopal@gmail.com",
  "phone": "+919876543210",
  "password": "SecurePass123!",
  "full_name": "Gopal Kumar"
}
```

**Response (201 Created):**
```json
{
  "user_id": "USER-12345",
  "email": "gopal@gmail.com",
  "full_name": "Gopal Kumar",
  "trust_score": 0,
  "risk_tier": "BRONZE",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Errors:**
- `400` - Email already exists
- `422` - Validation error

---

### POST `/api/auth/login`
Authenticate user and get JWT token.

**Request:**
```json
{
  "email": "gopal@gmail.com",
  "password": "SecurePass123!"
}
```

**Response (200 OK):**
```json
{
  "user_id": "USER-12345",
  "email": "gopal@gmail.com",
  "full_name": "Gopal Kumar",
  "trust_score": 0,
  "risk_tier": "BRONZE",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

**Errors:**
- `401` - Invalid credentials
- `404` - User not found

---

## 2️⃣ Payment APIs

### POST `/api/payment/intent`
Analyze transaction risk **before** payment.

**Request:**
```json
{
  "amount": 9000000,
  "receiver": "SriRam@upi",
  "note": "Payment for property"
}
```

**Response (200 OK):**
```json
{
  "transaction_id": "TXN-29384910",
  "risk_score": 0.55,
  "risk_level": "MODERATE",
  "risk_percentage": 55,
  "action": "WARNING",
  "message": "This transaction has moderate risk. Review before proceeding.",
  
  "risk_breakdown": {
    "behavior_analysis": {
      "score": 30,
      "weight": 30,
      "factors": [
        "Transaction velocity within normal range",
        "Consistent device usage"
      ]
    },
    "amount_analysis": {
      "score": 100,
      "weight": 30,
      "factors": [
        "Amount is 15x your average transaction",
        "Largest transaction in 90 days"
      ]
    },
    "receiver_analysis": {
      "score": 40,
      "weight": 40,
      "factors": [
        "New receiver - first transaction",
        "Receiver has neutral reputation"
      ]
    }
  },
  
  "factors": [
    "New receiver",
    "High amount compared to history",
    "First transaction above ₹5,00,000"
  ],
  
  "receiver_info": {
    "name": "Unknown Receiver",
    "verified": false,
    "reputation_score": 0.5,
    "total_transactions": 0
  },
  
  "recommendations": [
    "Verify receiver identity before proceeding",
    "Consider breaking into smaller amounts",
    "Contact receiver through alternate channel"
  ],
  
  "can_proceed": true,
  "requires_otp": false,
  "estimated_delay": 0
}
```

**Response (200 OK - HIGH RISK):**
```json
{
  "transaction_id": "TXN-29384911",
  "risk_score": 0.75,
  "risk_level": "HIGH",
  "risk_percentage": 75,
  "action": "OTP_REQUIRED",
  "message": "High risk detected. OTP verification required.",
  
  "can_proceed": true,
  "requires_otp": true,
  "estimated_delay": 30
}
```

**Response (200 OK - BLOCKED):**
```json
{
  "transaction_id": "TXN-29384912",
  "risk_score": 0.95,
  "risk_level": "VERY_HIGH",
  "risk_percentage": 95,
  "action": "BLOCK",
  "message": "Transaction blocked due to very high risk.",
  
  "can_proceed": false,
  "block_reason": "Blacklisted receiver",
  "support_contact": "support@fraudguard.com"
}
```

**Errors:**
- `401` - Unauthorized
- `400` - Invalid amount
- `429` - Rate limit exceeded

---

### POST `/api/payment/confirm`
Finalize payment after user reviews risk.

**Request:**
```json
{
  "transaction_id": "TXN-29384910",
  "otp": "123456"
}
```

**Response (200 OK):**
```json
{
  "transaction_id": "UPI-2938491029",
  "status": "SUCCESS",
  "amount": 9000000,
  "receiver": "SriRam@upi",
  "payment_method": "State Bank of India •••• 9812",
  "timestamp": "2026-01-30T14:30:00Z",
  "risk_score": 0.55,
  "trust_score_change": 0
}
```

**Errors:**
- `401` - Unauthorized
- `404` - Transaction not found
- `400` - Invalid OTP
- `403` - Transaction blocked

---

## 3️⃣ Risk Analysis APIs

### POST `/api/risk/analyze`
Get detailed risk analysis (same as `/payment/intent`).

**Request:**
```json
{
  "amount": 600000,
  "receiver": "merchant@upi"
}
```

**Response:** Same as `/payment/intent`

---

### GET `/api/risk/trend`
Get user's risk trend over time.

**Response (200 OK):**
```json
{
  "user_id": "USER-12345",
  "current_risk_trend": 0.0,
  "trend_direction": "INCREASING",
  "risk_history": [
    { "date": "2026-01-30", "avg_risk": 0.45 },
    { "date": "2026-01-29", "avg_risk": 0.50 },
    { "date": "2026-01-28", "avg_risk": 0.55 },
    { "date": "2026-01-27", "avg_risk": 0.48 },
    { "date": "2026-01-26", "avg_risk": 0.42 }
  ],
  "warning": "Risk levels are increasing"
}
```

---

## 4️⃣ User Profile APIs

### GET `/api/user/profile`
Get user profile with trust score.

**Response (200 OK):**
```json
{
  "user_id": "USER-12345",
  "security_id": "USER-12345",
  "full_name": "Gopal",
  "email": "gopal@gmail.com",
  "phone": "+919876543210",
  
  "trust_score": 0,
  "trust_percentage": 0,
  "risk_tier": "BRONZE",
  "membership": "BRONZE",
  
  "account_age_days": 1,
  "total_transactions": 5,
  "successful_transactions": 5,
  "failed_transactions": 0,
  
  "average_transaction_amount": 600000,
  "total_amount_transacted": 3000000,
  
  "known_devices": [
    {
      "device_id": "DEV-ABC123",
      "device_name": "iPhone 14 Pro",
      "last_used": "2026-01-30T14:30:00Z"
    }
  ],
  
  "created_at": "2026-01-29T10:00:00Z",
  "updated_at": "2026-01-30T14:30:00Z"
}
```

---

### GET `/api/user/trust-score`
Get trust score evolution.

**Response (200 OK):**
```json
{
  "current_score": 0,
  "current_tier": "BRONZE",
  "next_tier": "SILVER",
  "points_to_next_tier": 31,
  
  "history": [
    { "date": "2026-01-30", "score": 0, "event": "Successful transaction" },
    { "date": "2026-01-29", "score": 0, "event": "Account created" }
  ],
  
  "benefits": {
    "BRONZE": [
      "Standard security checks",
      "Transaction limits: ₹1,00,000/day"
    ],
    "SILVER": [
      "Reduced friction on known receivers",
      "Transaction limits: ₹5,00,000/day",
      "Priority support"
    ],
    "GOLD": [
      "Fast-track transactions",
      "Transaction limits: ₹10,00,000/day",
      "VIP support",
      "No OTP for trusted receivers"
    ]
  }
}
```

---

## 5️⃣ Transaction History APIs

### GET `/api/transactions`
Get recent transactions with risk scores.

**Query Parameters:**
- `limit` (default: 10, max: 100)
- `offset` (default: 0)
- `risk_level` (optional: LOW, MODERATE, HIGH, VERY_HIGH)

**Response (200 OK):**
```json
{
  "total": 5,
  "transactions": [
    {
      "transaction_id": "UPI-2938491029",
      "amount": 9000000,
      "receiver": "Unknown Receiver",
      "receiver_upi": "SriRam@upi",
      "status": "SUCCESS",
      "risk_score": 0.55,
      "risk_level": "MODERATE",
      "risk_percentage": 55,
      "timestamp": "2026-01-30T14:30:00Z",
      "time_ago": "3m ago"
    },
    {
      "transaction_id": "UPI-2938491028",
      "amount": 6000000,
      "receiver": "Unknown Receiver",
      "receiver_upi": "Merchant@upi",
      "status": "SUCCESS",
      "risk_score": 0.55,
      "risk_level": "MODERATE",
      "risk_percentage": 55,
      "timestamp": "2026-01-30T14:27:00Z",
      "time_ago": "3m ago"
    },
    {
      "transaction_id": "UPI-2938491027",
      "amount": 600000,
      "receiver": "Unknown Receiver",
      "receiver_upi": "Shop@upi",
      "status": "SUCCESS",
      "risk_score": 0.55,
      "risk_level": "MODERATE",
      "risk_percentage": 55,
      "timestamp": "2026-01-30T14:26:00Z",
      "time_ago": "4m ago"
    }
  ]
}
```

---

### GET `/api/transactions/:id`
Get detailed transaction information.

**Response (200 OK):**
```json
{
  "transaction_id": "UPI-2938491029",
  "amount": 9000000,
  "receiver": "Unknown Receiver",
  "receiver_upi": "SriRam@upi",
  "status": "SUCCESS",
  "payment_method": "State Bank of India •••• 9812",
  
  "risk_analysis": {
    "risk_score": 0.55,
    "risk_level": "MODERATE",
    "risk_breakdown": {
      "behavior_analysis": 30,
      "amount_analysis": 100,
      "receiver_analysis": 40
    },
    "factors": [
      "New receiver",
      "High amount compared to history"
    ]
  },
  
  "ml_analysis": {
    "ml_score": 0.20,
    "model_version": "v1.1",
    "features_used": 14
  },
  
  "rules_triggered": [
    "NEW_RECEIVER_HIGH_AMOUNT",
    "AMOUNT_ABOVE_AVERAGE"
  ],
  
  "timestamp": "2026-01-30T14:30:00Z",
  "created_at": "2026-01-30T14:29:45Z",
  "updated_at": "2026-01-30T14:30:15Z"
}
```

---

## 📊 Response Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful request |
| 201 | Created | Resource created (signup) |
| 400 | Bad Request | Invalid input |
| 401 | Unauthorized | Missing/invalid token |
| 403 | Forbidden | Action not allowed |
| 404 | Not Found | Resource doesn't exist |
| 422 | Validation Error | Input validation failed |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

---

## 🔒 Security Headers

All responses include:
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self'
```

---

## 🚀 Rate Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/auth/login` | 5 requests | 15 minutes |
| `/payment/*` | 10 requests | 1 minute |
| `/risk/*` | 20 requests | 1 minute |
| `/transactions` | 100 requests | 1 minute |

**Rate Limit Headers:**
```
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 7
X-RateLimit-Reset: 1706630400
```

---

## 🧪 Testing Endpoints

### Postman Collection
Import from: `docs/postman/fraud-detection-api.json`

### Sample cURL Commands

**Signup:**
```bash
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "phone": "+919876543210",
    "password": "Test123!",
    "full_name": "Test User"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!"
  }'
```

**Check Transaction:**
```bash
curl -X POST http://localhost:8000/api/payment/intent \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "amount": 9000000,
    "receiver": "SriRam@upi"
  }'
```

---

## 📚 Related Documents
- [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md)
- [Risk Orchestrator Design](./RISK_ORCHESTRATOR_DESIGN.md)
- [Database Schema](./DATABASE_SCHEMA.md)

---

**Last Updated:** February 3, 2026  
**API Version:** 2.0  
**Base URL:** `http://localhost:8000` (development)
