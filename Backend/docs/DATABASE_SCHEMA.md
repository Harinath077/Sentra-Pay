# 🗄️ Database Schema
## PostgreSQL Database Design

---

## 📊 Entity-Relationship Overview

```
┌─────────────┐
│    users    │
└──────┬──────┘
       │ 1
       │
       │ *
┌──────┴──────────┐
│  transactions   │
└──────┬──────────┘
       │ 1
       │
       │ *
┌──────┴──────────┐
│  risk_events    │
└─────────────────┘

       ┌─────────────────────┐
       │receiver_reputation  │
       └─────────────────────┘
```

---

## 📋 Tables

### 1. `users`
Stores user account information and trust metrics.

```sql
CREATE TABLE users (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- Authentication
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Profile
    full_name VARCHAR(255) NOT NULL,
    
    -- Trust & Risk Metrics
    trust_score FLOAT DEFAULT 0.0,
    risk_tier VARCHAR(20) DEFAULT 'BRONZE',
    
    -- Device Tracking
    known_devices JSONB DEFAULT '[]'::jsonb,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    
    -- Constraints
    CONSTRAINT valid_risk_tier CHECK (risk_tier IN ('BRONZE', 'SILVER', 'GOLD')),
    CONSTRAINT valid_trust_score CHECK (trust_score >= 0 AND trust_score <= 100)
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_risk_tier ON users(risk_tier);
```

**Sample Data:**
```sql
INSERT INTO users (email, phone, password_hash, full_name, trust_score, risk_tier)
VALUES 
('gopal@gmail.com', '+919876543210', '$2b$12$...', 'Gopal Kumar', 0, 'BRONZE'),
('john@example.com', '+919876543211', '$2b$12$...', 'John Doe', 45, 'SILVER'),
('alice@example.com', '+919876543212', '$2b$12$...', 'Alice Smith', 85, 'GOLD');
```

---

### 2. `transactions`
Stores all payment transactions with risk analysis results.

```sql
CREATE TABLE transactions (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- User Reference
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Transaction Details
    amount DECIMAL(15, 2) NOT NULL,
    receiver VARCHAR(255) NOT NULL,
    note TEXT,
    
    -- Risk Analysis
    risk_score FLOAT,
    risk_level VARCHAR(20),
    ml_score FLOAT,
    rule_score FLOAT,
    
    -- Decision
    action_taken VARCHAR(20),
    status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Payment Details
    payment_method VARCHAR(255),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    
    -- Constraints
    CONSTRAINT valid_risk_level CHECK (risk_level IN ('LOW', 'MODERATE', 'HIGH', 'VERY_HIGH')),
    CONSTRAINT valid_action CHECK (action_taken IN ('ALLOW', 'WARNING', 'OTP_REQUIRED', 'BLOCK')),
    CONSTRAINT valid_status CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'BLOCKED'))
);

-- Indexes
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_receiver ON transactions(receiver);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);
CREATE INDEX idx_transactions_risk_level ON transactions(risk_level);
CREATE INDEX idx_transactions_status ON transactions(status);

-- Composite Index for transaction history queries
CREATE INDEX idx_transactions_user_created ON transactions(user_id, created_at DESC);
```

**Sample Data:**
```sql
INSERT INTO transactions (transaction_id, user_id, amount, receiver, risk_score, risk_level, ml_score, rule_score, action_taken, status)
VALUES 
('UPI-2938491029', 1, 9000000.00, 'SriRam@upi', 0.55, 'MODERATE', 0.20, 0.35, 'WARNING', 'SUCCESS'),
('UPI-2938491028', 1, 6000000.00, 'Merchant@upi', 0.55, 'MODERATE', 0.25, 0.30, 'WARNING', 'SUCCESS'),
('UPI-2938491027', 1, 600000.00, 'Shop@upi', 0.55, 'MODERATE', 0.30, 0.25, 'WARNING', 'SUCCESS');
```

---

### 3. `risk_events`
Detailed log of risk analysis events for auditing and ML training.

```sql
CREATE TABLE risk_events (
    -- Primary Key
    id SERIAL PRIMARY KEY,
    
    -- References
    transaction_id INTEGER NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Risk Analysis Details
    rule_triggered VARCHAR(50),
    ml_score FLOAT,
    rule_score FLOAT,
    final_score FLOAT,
    
    -- Action
    action VARCHAR(20),
    
    -- Features (for ML training)
    features JSONB,
    
    -- Flags
    flags JSONB DEFAULT '[]'::jsonb,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_risk_events_transaction_id ON risk_events(transaction_id);
CREATE INDEX idx_risk_events_user_id ON risk_events(user_id);
CREATE INDEX idx_risk_events_created_at ON risk_events(created_at);
CREATE INDEX idx_risk_events_rule_triggered ON risk_events(rule_triggered);
```

**Sample Data:**
```sql
INSERT INTO risk_events (transaction_id, user_id, rule_triggered, ml_score, rule_score, final_score, action, features, flags)
VALUES 
(1, 1, 'NEW_RECEIVER_HIGH_AMOUNT', 0.20, 0.35, 0.55, 'WARNING', 
 '{"amount_to_avg_ratio": 15.0, "is_new_receiver": 1, "txn_velocity_5min": 1}'::jsonb,
 '["NEW_RECEIVER", "HIGH_AMOUNT"]'::jsonb);
```

---

### 4. `receiver_reputation`
Tracks reputation scores for payment receivers.

```sql
CREATE TABLE receiver_reputation (
    -- Primary Key
    receiver VARCHAR(255) PRIMARY KEY,
    
    -- Reputation Metrics
    total_transactions INTEGER DEFAULT 0,
    successful_transactions INTEGER DEFAULT 0,
    fraud_count INTEGER DEFAULT 0,
    chargeback_count INTEGER DEFAULT 0,
    
    -- Calculated Score
    reputation_score FLOAT DEFAULT 0.5,
    
    -- Metadata
    first_seen TIMESTAMP DEFAULT NOW(),
    last_updated TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_reputation_score CHECK (reputation_score >= 0 AND reputation_score <= 1)
);

-- Indexes
CREATE INDEX idx_receiver_reputation_score ON receiver_reputation(reputation_score);
CREATE INDEX idx_receiver_fraud_count ON receiver_reputation(fraud_count);
```

**Sample Data:**
```sql
INSERT INTO receiver_reputation (receiver, total_transactions, successful_transactions, fraud_count, reputation_score)
VALUES 
('SriRam@upi', 0, 0, 0, 0.5),
('TrustedMerchant@upi', 1000, 980, 2, 0.95),
('SuspiciousUser@upi', 50, 30, 15, 0.10);
```

---

### 5. `user_stats` (Materialized View)
Pre-computed user statistics for fast queries.

```sql
CREATE MATERIALIZED VIEW user_stats AS
SELECT 
    u.id AS user_id,
    u.email,
    u.trust_score,
    u.risk_tier,
    COUNT(t.id) AS total_transactions,
    COUNT(CASE WHEN t.status = 'SUCCESS' THEN 1 END) AS successful_transactions,
    COUNT(CASE WHEN t.status = 'FAILED' THEN 1 END) AS failed_transactions,
    AVG(t.amount) AS avg_transaction_amount,
    SUM(t.amount) AS total_amount_transacted,
    AVG(t.risk_score) AS avg_risk_score,
    MAX(t.created_at) AS last_transaction_at
FROM users u
LEFT JOIN transactions t ON u.id = t.user_id
GROUP BY u.id, u.email, u.trust_score, u.risk_tier;

-- Refresh strategy
CREATE INDEX idx_user_stats_user_id ON user_stats(user_id);

-- Refresh periodically (every 5 minutes)
-- REFRESH MATERIALIZED VIEW user_stats;
```

---

## 🔄 Stored Procedures

### Update Trust Score
```sql
CREATE OR REPLACE FUNCTION update_trust_score(
    p_user_id INTEGER,
    p_event VARCHAR(50)
) RETURNS VOID AS $$
DECLARE
    v_current_score FLOAT;
BEGIN
    -- Get current trust score
    SELECT trust_score INTO v_current_score
    FROM users
    WHERE id = p_user_id;
    
    -- Update based on event
    CASE p_event
        WHEN 'SUCCESSFUL_TXN' THEN
            v_current_score := v_current_score + 1;
        WHEN 'FRAUD_REPORTED' THEN
            v_current_score := v_current_score - 10;
        WHEN 'FREQUENT_HIGH_RISK' THEN
            v_current_score := v_current_score - 2;
        WHEN 'OTP_FAILED' THEN
            v_current_score := v_current_score - 1;
        WHEN 'KYC_VERIFIED' THEN
            v_current_score := v_current_score + 5;
        ELSE
            -- Unknown event, do nothing
            NULL;
    END CASE;
    
    -- Clamp to 0-100
    v_current_score := GREATEST(0, LEAST(100, v_current_score));
    
    -- Update user
    UPDATE users
    SET 
        trust_score = v_current_score,
        risk_tier = CASE
            WHEN v_current_score >= 71 THEN 'GOLD'
            WHEN v_current_score >= 31 THEN 'SILVER'
            ELSE 'BRONZE'
        END,
        updated_at = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;
```

### Update Receiver Reputation
```sql
CREATE OR REPLACE FUNCTION update_receiver_reputation(
    p_receiver VARCHAR(255),
    p_was_fraud BOOLEAN
) RETURNS VOID AS $$
DECLARE
    v_total INTEGER;
    v_fraud INTEGER;
BEGIN
    -- Insert or update receiver
    INSERT INTO receiver_reputation (receiver, total_transactions, fraud_count)
    VALUES (p_receiver, 1, CASE WHEN p_was_fraud THEN 1 ELSE 0 END)
    ON CONFLICT (receiver) DO UPDATE
    SET 
        total_transactions = receiver_reputation.total_transactions + 1,
        fraud_count = receiver_reputation.fraud_count + CASE WHEN p_was_fraud THEN 1 ELSE 0 END,
        last_updated = NOW();
    
    -- Recalculate reputation score
    SELECT total_transactions, fraud_count
    INTO v_total, v_fraud
    FROM receiver_reputation
    WHERE receiver = p_receiver;
    
    UPDATE receiver_reputation
    SET reputation_score = CASE
        WHEN v_total = 0 THEN 0.5
        ELSE 1.0 - (v_fraud::FLOAT / v_total::FLOAT)
    END
    WHERE receiver = p_receiver;
END;
$$ LANGUAGE plpgsql;
```

---

## 🔍 Common Queries

### Get User Profile
```sql
SELECT 
    u.id,
    u.email,
    u.full_name,
    u.trust_score,
    u.risk_tier,
    u.created_at,
    us.total_transactions,
    us.successful_transactions,
    us.avg_transaction_amount,
    us.avg_risk_score
FROM users u
LEFT JOIN user_stats us ON u.id = us.user_id
WHERE u.id = $1;
```

### Get Transaction History
```sql
SELECT 
    t.transaction_id,
    t.amount,
    t.receiver,
    t.risk_score,
    t.risk_level,
    t.status,
    t.created_at,
    EXTRACT(EPOCH FROM (NOW() - t.created_at)) / 60 AS minutes_ago
FROM transactions t
WHERE t.user_id = $1
ORDER BY t.created_at DESC
LIMIT 10;
```

### Calculate Transaction Velocity
```sql
SELECT COUNT(*) AS txn_count_5min
FROM transactions
WHERE user_id = $1
  AND created_at >= NOW() - INTERVAL '5 minutes';
```

### Get Average Transaction Amount (Last 30 Days)
```sql
SELECT 
    AVG(amount) AS avg_amount_30d,
    MAX(amount) AS max_amount_30d,
    COUNT(*) AS txn_count_30d
FROM transactions
WHERE user_id = $1
  AND created_at >= NOW() - INTERVAL '30 days'
  AND status = 'SUCCESS';
```

### Check if Receiver is New
```sql
SELECT NOT EXISTS (
    SELECT 1
    FROM transactions
    WHERE user_id = $1
      AND receiver = $2
) AS is_new_receiver;
```

---

## 🚀 Migrations (Alembic)

### Initial Migration
```python
# alembic/versions/001_initial_schema.py
def upgrade():
    # Create users table
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(255), nullable=False),
        # ... other columns
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create transactions table
    op.create_table(
        'transactions',
        sa.Column('id', sa.Integer(), nullable=False),
        # ... other columns
        sa.ForeignKeyConstraint(['user_id'], ['users.id']),
        sa.PrimaryKeyConstraint('id')
    )
    
    # ... other tables
```

---

## 📊 Performance Considerations

### Partitioning (For Scale)
```sql
-- Partition transactions by month
CREATE TABLE transactions_2026_01 PARTITION OF transactions
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE transactions_2026_02 PARTITION OF transactions
FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
```

### Archiving Old Data
```sql
-- Archive transactions older than 1 year
CREATE TABLE transactions_archive AS
SELECT * FROM transactions
WHERE created_at < NOW() - INTERVAL '1 year';

DELETE FROM transactions
WHERE created_at < NOW() - INTERVAL '1 year';
```

---

## 🔒 Security

### Row-Level Security
```sql
-- Users can only see their own transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_transactions_policy ON transactions
FOR ALL
TO authenticated_users
USING (user_id = current_user_id());
```

### Encryption
```sql
-- Encrypt sensitive fields
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Example: Encrypt phone numbers
UPDATE users
SET phone = pgp_sym_encrypt(phone, 'encryption_key');
```

---

## 📚 Related Documents
- [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md)
- [API Specifications](./API_SPECIFICATIONS.md)
- [Risk Orchestrator Design](./RISK_ORCHESTRATOR_DESIGN.md)

---

**Last Updated:** February 3, 2026  
**Schema Version:** 2.0  
**Database:** PostgreSQL 14+
