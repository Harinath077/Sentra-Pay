# 🏗️ Sentra Pay - System Design Document

## 1. Executive Summary
**Sentra Pay** (also known as DeepBlue Shield) is a next-generation UPI payment application focused on **real-time fraud detection**. Unlike traditional payment apps that treat security as a background process, Sentra Pay makes risk analysis transparent and interactive for the user. 

The system uses a **Risk Orchestration Engine** that combines deterministic rules, machine learning (CatBoost), and behavioral analysis to provide a granular risk score (< 200ms) before a payment is processed.

---

## 2. High-Level Architecture

The system follows a **Microservices-ready Layered Architecture** powered by Docker.

```mermaid
graph TD
    subgraph "Client Layer (Frontend)"
        FlutterApp[📱 Flutter Mobile App]
    end

    subgraph "API Layer (Backend)"
        LB[⚖️ Load Balancer / Nginx]
        FastAPI[🚀 FastAPI Gateway]
    end

    subgraph "Intelligence Layer (Risk Engine)"
        Orchestrator[🧠 Risk Orchestrator]
        Rules[📏 Rules Engine]
        ML[🤖 ML Engine (CatBoost)]
        Gemini[🍌 GenAI (Gemini Banana)]
        Context[busts_in_silhouette Context Engine]
    end

    subgraph "Data Layer"
        Postgres[(🗄️ PostgreSQL\nPrimary DB)]
        Redis[(⚡ Redis\nCache & Pub/Sub)]
        Firebase[(🔥 Firebase\nAuth & Legacy)]
    end

    %% Data Flow
    FlutterApp -- HTTPS/JSON --> FastAPI
    FastAPI -- Auth Token --> Firebase
    FastAPI -- Risk Analysis --> Orchestrator
    
    Orchestrator --> Rules
    Orchestrator --> ML
    Orchestrator --> Gemini
    Orchestrator --> Context
    
    Context -.-> Redis
    Context -- Fallback --> Postgres
    
    FastAPI -- Store Txn --> Postgres
```

---

## 3. Core Components

### 📱 3.1 Client: Flutter Mobile App
- **Tech Stack**: Flutter (Dart), Provider (State Management).
- **Key Modules**:
  - **Transaction Interface**: Input amount/VPA, QR Scanner.
  - **Visual Risk Engine**: Animated gauges, factor breakdown bars.
  - **Trust System**: Gamified user trust score (Bronze/Silver/Gold/Platinum).
  - **Dark Mode**: Adaptive UI theming.
- **Responsibility**:  Captures user intent, displays risk analysis, handles biometric auth.

### 🚀 3.2 Backend: FastAPI Gateway
- **Tech Stack**: Python 3.10+, FastAPI, Uvicorn.
- **Responsibility**: 
  - Validates incoming requests (Pydantic).
  - Handles Authentication (JWT + Firebase Admin).
  - Managing Transaction Lifecycle (Intent -> Confirm).
  - Exposure of API documentation (Swagger UI).

### 🧠 3.3 Intelligence: Risk Orchestration Engine
This is the core differentiator of Sentra Pay. It does not output a simple Yes/No.
1.  **Context Engine**: Fetches user history and profile from **Redis** (rendering < 10ms latency).
2.  **Rules Engine**: Applies deterministic checks (e.g., "Amount > 10x average", "New Receiver").
3. **ML Engine**: Runs a pre-trained **CatBoost** model on 14 engineered features to predict fraud probability.
4. **GenAI Layer (Project "Gemini Banana")**: 
    - Uses **Gemini Nano** (on-device) and **Gemini 1.5 Pro** (cloud) for advanced reasoning.
    - **Visual Fraud Explainer**: Generates dynamic diagrams showing *why* a transaction is blocked (e.g., "Money mule path detected").
    - **Natural Language Interaction**: Chatbot interface for users to ask "Is this receiver safe?".
5. **Decision Engine**: Aggregates all scores into a final **Risk Score (0-100)** and determines friction (Warning/OTP/Block).

### 🗄️ 3.4 Data Persistence
- **PostgreSQL**: The source of truth. Stores User Profiles, Transactions, Fraud Reports, and Trust Scores.
- **Redis**: High-performance caching layer. Stores active user sessions, rate limits, and cached user profiles for the Context Engine.
- **Firebase**: Used for initial authentication (phone/Google) and syncing legacy data during migration.

---

## 4. Data Flow: "The Payment Journey"

When a user initiates a payment of **₹5,000** to `merchant@upi`:

1.  **Request**: App sends `POST /api/payment/intent` with Amount, Receiver VPA, Device ID.
2.  **Auth Check**: Backend validates JWT token.
3.  **Context Fetch**: 
    - *Is this receiver new?* (Redis Check)
    - *What is user's avg transaction size?* (Redis/DB Check)
4.  **Parallel Analysis**:
    - **Rules**: Checks for blacklisted VPAs or velocity spikes.
    - **ML Model**: Vectors input features and predicts probability (e.g., 0.12).
5.  **Aggregation**: 
    - Orchestrator weights the scores: `(Rule * 0.4) + (ML * 0.6)`.
    - Final Score: **15/100 (Low Risk)**.
6.  **Response**: Backend sends JSON with:
    - `risk_score`: 15
    - `risk_level`: "LOW"
    - `breakdown`: { "behavior": 5, "amount": 10, "receiver": 0 }
7.  **UI Update**: Flutter app animates the gauge to Green. User slides to pay.

---

## 5. Database Schema (Simplified)

### Users Table (`users`)
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key |
| `firebase_uid` | VARCHAR | Link to Firebase Auth |
| `trust_score` | INT | 0-100 Reputation |
| `risk_tier` | ENUM | BRONZE, SILVER, GOLD |
| `created_at` | TIMESTAMP | Account creation |

### Transactions Table (`transactions`)
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key |
| `user_id` | UUID | FK to Users |
| `amount` | DECIMAL | Transaction value |
| `receiver_vpa` | VARCHAR | UPI ID of recipient |
| `risk_score` | FLOAT | Calculated risk (0.0 - 1.0) |
| `status` | ENUM | PENDING, COMPLETED, BLOCKED |
| `ml_prediction`| JSONB | Stored model features |

### Fraud Reports (`fraud_reports`)
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary Key |
| `reporter_id` | UUID | User who reported |
| `suspect_vpa` | VARCHAR | The fraudulent ID |
| `report_type` | ENUM | SCAM, PHISHING, IMPERSONATION |

---

## 6. Security & Scalability

### 🛡️ Security Measures
- **JWT Authentication**: Stateless, secure token-based access.
- **End-to-End Encryption**: All sensitive payload data is encrypted over TLS.
- **Rate Limiting**: Redis-backed limiting to prevent DDOS / brute-forcing (e.g., max 10 transactions/min).
- **SQL Injection Protection**: Uses SQLAlchemy ORM to sanitize all database queries.

### 📈 Scalability Strategy
- **Containerization**: Entire backend stack is Dockerized.
- **Stateless API**: FastAPI instances can be horizontally scaled behind a load balancer.
- **Caching**: Heavy reliance on Redis reduces load on PostgreSQL for read-heavy operations (e.g., fetching profiles).
- **Async I/O**: Python's `asyncio` ensures high concurrency for I/O bound tasks.

---

## 7. Technology Stack Summary

| Layer | Technology |
| :--- | :--- |
| **Mobile** | Flutter (Dart) |
| **Backend** | Python (FastAPI) |
| **Database** | PostgreSQL 14 |
| **Cache** | Redis 7 |
| **ML Model** | CatBoost |
| **GenAI** | Gemini Banana (Nano & Pro) |
| **DevOps** | Docker, Docker Compose |
| **Cloud (Simulation)** | Localhost (Migration to AWS/GCP ready) |
