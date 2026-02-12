# 🚀 QUICK START - PostgreSQL Migration

## 🎯 For the Impatient (TL;DR)

```bash
# 1️⃣ Start PostgreSQL
docker-compose -f docker-compose-postgres.yml up -d

# 2️⃣ Setup everything automatically
python scripts/quick_start.py

# 3️⃣ Done! Backend is running on http://localhost:8000
```

---

## 📋 STEP-BY-STEP (If You Want Details)

### **Step 1: Start PostgreSQL Database**

```bash
cd Backend
docker-compose -f docker-compose-postgres.yml up -d
```

**Verify it's running:**
```bash
docker ps | findstr sentra-pay-postgres
```

---

### **Step 2: Initialize Database**

```bash
# Test connection
python -c "from app.database.connection import test_db_connection; test_db_connection()"

# Create tables
python -c "from app.database.connection import init_db; init_db()"

# Create sample data (optional)
python scripts/setup_database.py --action sample
```

---

### **Step 3: Start Backend Server**

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

### **Step 4: Test It!**

Open browser: **http://localhost:8000/docs**

Try the signup endpoint:
```bash
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@sentra.com\",\"password\":\"Test123!\",\"full_name\":\"Test User\",\"phone\":\"+919876543210\"}"
```

---

## 🛠️ UTILITY COMMANDS

### Database Management

```bash
# Test connection
python scripts/setup_database.py --action test

# Initialize database
python scripts/setup_database.py --action init

# Create sample data
python scripts/setup_database.py --action sample

# Reset database (⚠️ deletes all data)
python scripts/setup_database.py --action reset

# Migrate from SQLite (if you have existing data)
python scripts/setup_database.py --action migrate
```

### Docker Commands

```bash
# Start services
docker-compose -f docker-compose-postgres.yml up -d

# Stop services
docker-compose -f docker-compose-postgres.yml down

# View logs
docker logs sentra-pay-postgres
docker logs sentra-pay-redis

# Enter PostgreSQL shell
docker exec -it sentra-pay-postgres psql -U postgres -d fraud_detection

# Backup database
docker exec sentra-pay-postgres pg_dump -U postgres fraud_detection > backup.sql

# Restore database
cat backup.sql | docker exec -i sentra-pay-postgres psql -U postgres -d fraud_detection
```

---

## 🧪 VERIFY MIGRATION SUCCESS

### Check 1: Database Connection
```bash
python -c "from app.database.connection import test_db_connection; print(test_db_connection())"
# Expected: True
```

### Check 2: Tables Created
```bash
docker exec -it sentra-pay-postgres psql -U postgres -d fraud_detection -c "\dt"
# Expected: List of tables (users, transactions, risk_events, etc.)
```

### Check 3: API Health
```bash
curl http://localhost:8000/api/auth/health
# Expected: {"status":"ok","service":"authentication"}
```

### Check 4: Create User
```bash
curl -X POST http://localhost:8000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!","full_name":"Test User","phone":"+919876543210"}'
# Expected: Returns user object with JWT token
```

---

## 🚨 TROUBLESHOOTING

### ❌ "Connection refused" error

**Problem:** PostgreSQL not running

**Solution:**
```bash
docker-compose -f docker-compose-postgres.yml up -d
docker ps  # Verify it's running
```

---

### ❌ "relation does not exist" error

**Problem:** Tables not created

**Solution:**
```bash
python -c "from app.database.connection import init_db; init_db()"
```

---

### ❌ "password authentication failed"

**Problem:** Wrong password in DATABASE_URL

**Solution:** Check `.env` file:
```bash
DATABASE_URL=postgresql://postgres:sentra_secure_2026@localhost:5432/fraud_detection
```

---

### ❌ Docker won't start

**Problem:** Port 5432 already in use

**Solution:**
```bash
# Check what's using port 5432
netstat -ano | findstr :5432

# Kill existing PostgreSQL
taskkill /PID <process_id> /F

# Or change port in docker-compose-postgres.yml:
ports:
  - "5433:5432"  # Use port 5433 instead
```

---

## 📊 DATABASE SCHEMA

Your PostgreSQL database has these tables:

```
users                   → User accounts (email, password, trust_score)
transactions            → Payment transactions
risk_events             → Risk analysis logs
receiver_reputation     → UPI receiver reputation scores
qr_scans               → QR scan history
```

View schema:
```bash
docker exec -it sentra-pay-postgres psql -U postgres -d fraud_detection -c "\d+ users"
```

---

## 🎉 DONE!

Your backend is now running PostgreSQL instead of Firebase!

**Next Steps:**
1. Update Flutter app to use new backend API
2. Monitor PostgreSQL logs for performance
3. Set up regular database backups
4. After 1 week, remove old Firebase files

**API Documentation:** http://localhost:8000/docs
**Database:** postgresql://localhost:5432/fraud_detection
**Redis:** redis://localhost:6379/0

---

**Need help?** Check `FIREBASE_TO_POSTGRES_MIGRATION.md` for full documentation.
