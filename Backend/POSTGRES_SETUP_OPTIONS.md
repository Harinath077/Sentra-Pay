# 🚀 PostgreSQL Setup Options (Docker Not Available)

Since Docker is not installed on your system, here are your options to run PostgreSQL:

---

## ✅ **Option 1: Install PostgreSQL Directly on Windows** (RECOMMENDED)

### Download and Install:

1. **Download PostgreSQL 14 for Windows:**
   - Visit: https://www.postgresql.org/download/windows/
   - Or direct download: https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
   - Choose: PostgreSQL 14.x (Windows x86-64)

2. **Install PostgreSQL:**
   - Run the installer
   - Set password: `sentra_secure_2026` (or your choice)
   - Port: `5432` (default)
   - Create database: `fraud_detection`

3. **Update .env file:**
   ```bash
   # If you used a different password, update it here:
   DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/fraud_detection
   ```

4. **Initialize Database:**
   ```bash
   python scripts/setup_database.py --action init
   ```

5. **Done!** PostgreSQL is now running locally.

---

## ✅ **Option 2: Use SQLite (Temporary - For Development)**

If you want to start immediately without installing PostgreSQL:

### Keep using SQLite for now:

1. **Update .env file:**
   ```bash
   DATABASE_URL=sqlite:///./fraud_detection.db
   ```

2. **Initialize Database:**
   ```bash
   python -c "from app.database.connection import init_db; init_db()"
   ```

3. **Start Server:**
   ```bash
   uvicorn app.main:app --reload
   ```

**Note:** SQLite works fine for development but PostgreSQL is recommended for production.

---

## ✅ **Option 3: Install Docker Desktop** (Future-proof)

### Install Docker:

1. **Download Docker Desktop for Windows:**
   - Visit: https://www.docker.com/products/docker-desktop/
   - Download and install

2. **After installation, run:**
   ```bash
   docker compose -f docker-compose-postgres.yml up -d
   ```

3. **Initialize Database:**
   ```bash
   python scripts/setup_database.py --action init
   ```

---

## 🎯 **What I Recommend:**

**For now:** Use **Option 2 (SQLite)** to start immediately.

**This week:** Install **Option 1 (PostgreSQL directly)** or **Option 3 (Docker)** for production-ready setup.

---

## 🧪 **Current Status:**

✅ Firebase files removed  
✅ Code ready for PostgreSQL  
✅ Can run with SQLite now  
⏳ Need to install PostgreSQL or Docker  

---

## 🚀 **Quick Start (Using SQLite for now):**

```bash
# 1. Update .env to use SQLite
# DATABASE_URL=sqlite:///./fraud_detection.db

# 2. Initialize database
python -c "from app.database.connection import init_db; init_db()"

# 3. Start server
uvicorn app.main:app --reload
```

**Your backend will work perfectly with SQLite!** When you're ready, you can migrate to PostgreSQL later using the migration guide.

---

**Next Steps?** Choose an option above and let me know if you need help with installation! 🚀
