# 📚 Backend Documentation
## Fraud Detection System - Complete Architecture & Design

---

## 📖 Overview

This folder contains comprehensive documentation for the fraud detection backend system. The backend is a **Risk Orchestration Engine** that combines rules-based fraud detection, machine learning predictions, and user context to make intelligent, friction-based decisions.

---

## 📑 Documentation Index

### 1. [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md) 🏗️
**The most important document - start here!**

**What's inside:**
- 🧠 Core architectural principle (Risk Orchestrator, not simple ML blocking)
- 🏛️ 5-layer architecture breakdown
- 🔄 Complete transaction flow (12 steps)
- 🎯 Component details (API Gateway, Risk Orchestrator, Rules Engine, ML Engine, Decision Engine)
- 🗄️ Database design overview
- 🏆 Trust score system
- 🎬 Demo flow for judges
- 🚀 Performance optimizations
- 🧪 Testing strategy

**Who should read:** Everyone - developers, architects, judges

**Reading time:** 20 minutes

---

### 2. [API Specifications](./API_SPECIFICATIONS.md) 📡
**Complete REST API reference**

**What's inside:**
- 🔐 Authentication endpoints (`/signup`, `/login`)
- 💳 Payment endpoints (`/payment/intent`, `/payment/confirm`)
- 📊 Risk analysis endpoints
- 👤 User profile endpoints
- 📜 Transaction history endpoints
- All request/response examples with JSON
- Error codes and handling
- Rate limiting details
- Security headers
- Sample cURL commands

**Who should read:** Backend developers, frontend developers

**Reading time:** 15 minutes

**Use for:** API integration, testing, Postman collection creation

---

### 3. [Risk Orchestrator Design](./RISK_ORCHESTRATOR_DESIGN.md) 🧠
**Deep dive into the core engine**

**What's inside:**
- 🏗️ Detailed architecture diagram
- 📝 Complete pseudo-code implementation
- 🎛️ Score combination logic
- 🔍 Response construction logic
- ⚙️ Configuration (weights, thresholds, action mapping)
- 🧪 Testing strategy
- 📊 Performance metrics
- 🔍 Debugging & observability

**Who should read:** Backend developers implementing core logic

**Reading time:** 25 minutes

**Use for:** Implementing `risk_orchestrator.py`, understanding decision logic

---

### 4. [Database Schema](./DATABASE_SCHEMA.md) 🗄️
**PostgreSQL database design**

**What's inside:**
- 📊 Entity-relationship diagram
- 📋 All table definitions with SQL
- 🔄 Stored procedures (trust score update, receiver reputation)
- 🔍 Common queries (user profile, transaction history, velocity calculation)
- 🚀 Migrations guide (Alembic)
- 📊 Performance considerations (indexing, partitioning, archiving)
- 🔒 Security (row-level security, encryption)

**Who should read:** Backend developers, database administrators

**Reading time:** 20 minutes

**Use for:** Database setup, implementing `models.py`, writing queries

---

## 🎯 Quick Navigation

### By Role

**👨‍💻 Backend Developer:**
1. Read [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md) (overview)
2. Read [Risk Orchestrator Design](./RISK_ORCHESTRATOR_DESIGN.md) (implementation)
3. Read [Database Schema](./DATABASE_SCHEMA.md) (data layer)
4. Refer to [API Specifications](./API_SPECIFICATIONS.md) (endpoints)

**👩‍💻 Frontend Developer:**
1. Read [API Specifications](./API_SPECIFICATIONS.md) (all endpoints)
2. Skim [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md) (understand flow)

**🎓 Hackathon Judge:**
1. Read [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md) (complete system)
2. Look at demo flow section in architecture guide

**🏗️ System Architect:**
1. Read all documents in order
2. Focus on architecture diagrams and decision rationales

---

### By Task

**Setting up database:**
→ [Database Schema](./DATABASE_SCHEMA.md)

**Implementing risk analysis:**
→ [Risk Orchestrator Design](./RISK_ORCHESTRATOR_DESIGN.md)

**Building API endpoints:**
→ [API Specifications](./API_SPECIFICATIONS.md)

**Understanding overall system:**
→ [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md)

**Preparing demo:**
→ [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md) → Demo Flow section

---

## 🔑 Key Concepts

### Risk Orchestration (Not Simple ML Blocking)
```
❌ WRONG: if ML > 0.5 then BLOCK
✅ RIGHT: Combine(Rules + ML + Context) → Friction Level → User Decision
```

### 5-Layer Architecture
```
1. Frontend (Flutter App)
2. API Gateway (FastAPI)
3. Risk Orchestrator (Coordinator)
4. Engines (Rules + ML + Context + Decision)
5. Data Layer (PostgreSQL + Redis)
```

### Score Combination
```
final_score = (rule_score × 0.6) + (ml_score × 0.4)
# Adjusted by user tier and flags
```

### Risk → Action Mapping
```
0.00-0.30 → ALLOW
0.30-0.60 → WARNING (show risk screen)
0.60-0.80 → OTP_REQUIRED
0.80-1.00 → BLOCK
```

---

## 🎨 Visual Aids

All diagrams are included in the attachments folder and referenced in documents:
- Architecture diagram (system components)
- Sequence diagram (transaction flow)
- ML pipeline diagram
- UI mockups (Flutter screens)

---

## 🔗 External Resources

### Code Repository
- Main repo: `d:\fraud-detection-backend\`
- Implementation checklist: [`../PIPELINE.md`](../PIPELINE.md)

### Related Documents
- Project README: [`../README.md`](../README.md)
- Requirements: [`../requirements.txt`](../requirements.txt)
- Docker setup: [`../docker-compose.yml`](../docker-compose.yml)

---

## 📊 Implementation Status

**Documentation:** ✅ Complete (February 3, 2026)

**Code Implementation:** 
- Foundation: 🔨 In Progress
- Core Engine: 📝 Planned
- APIs: 📝 Planned
- Testing: 📝 Planned

**See [PIPELINE.md](../PIPELINE.md) for detailed implementation checklist**

---

## 🤝 Contributing

When adding new documentation:
1. Follow the same structure (emoji headers, code blocks, tables)
2. Include practical examples
3. Link related documents
4. Update this README index

---

## ❓ FAQ

**Q: Where do I start implementing?**
A: Follow [PIPELINE.md](../PIPELINE.md) - Phase 1 (Database) → Phase 2 (Auth) → Phase 3 (Risk Engine)

**Q: How do I test the APIs?**
A: See [API Specifications](./API_SPECIFICATIONS.md) → Testing Endpoints section

**Q: What makes this different from other fraud detection systems?**
A: We use a **Risk Orchestrator** pattern that combines multiple signals and provides friction-based decisions rather than hard blocks. See [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md) → Core Principle

**Q: Can I use this architecture for other fraud detection projects?**
A: Yes! The Risk Orchestrator pattern is general-purpose. Adapt the rules, features, and thresholds to your domain.

**Q: How do I explain this to judges in 2 minutes?**
A: Use the demo flow in [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md) → Demo Flow section

---

## 📞 Quick Reference

| Document | Lines of Code | Key Sections |
|----------|---------------|--------------|
| Architecture Guide | ~600 | Core Principle, 5-Layer Architecture, Transaction Flow |
| API Specifications | ~700 | All endpoints, Request/Response examples |
| Risk Orchestrator | ~500 | Pseudo-code, Score combination, Testing |
| Database Schema | ~600 | Table definitions, Queries, Performance |

**Total Documentation:** ~2,400 lines

---

## 🏆 What Makes This Documentation Special

✅ **Production-Ready** - Not just theory, ready to implement  
✅ **Complete Examples** - Every concept has code samples  
✅ **Interconnected** - Documents reference each other  
✅ **Practical** - Includes testing, validation, debugging  
✅ **Explainable** - Written for judges to understand  
✅ **Honest** - Admits ML limitations, shows real-world approach  

---

**Last Updated:** February 3, 2026  
**Documentation Version:** 2.0  
**Status:** Complete ✅
