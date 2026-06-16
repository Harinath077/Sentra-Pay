# 🛡️ SentraPay - Real-Time UPI Fraud Prevention System

## Overview

SentraPay is a behavioral fraud prevention system designed to identify risky UPI transactions before money leaves the user's account.

Unlike traditional fraud detection systems that rely on fixed thresholds, SentraPay builds a personalized behavioral profile for each user and evaluates transaction risk in real time.

The system combines:

- Relationship Analysis
- Amount Analysis
- Machine Learning
- Receiver Intelligence

to generate a unified fraud risk score.

---

# Why Machine Learning?

Rule-based systems are effective at detecting known fraud patterns.

However, modern fraud often appears as a combination of weak signals:

- Slightly unusual amount
- Slightly unusual timing
- Slightly suspicious receiver
- Increased transaction velocity

Individually these signals appear normal.

Together they may indicate fraud.

Machine Learning helps identify these hidden relationships and improves risk estimation beyond static rules.

---

# Dataset Strategy

## Why Not Use Real UPI Data?

Real UPI transaction data is protected by:

- RBI regulations
- NPCI compliance policies
- Banking privacy requirements
- User data protection laws

Because access to real banking transaction histories is restricted, a synthetic dataset was created.

---

# Synthetic Dataset Design

The dataset simulates realistic UPI transaction behavior.

Two independent datasets are used.

## 1. Sender History Dataset

This dataset represents historical user behavior.

Fields include:

- sender_upi
- receiver_upi
- amount
- timestamp
- location
- device information
- transaction status

Purpose:

- User behavior profiling
- Relationship analysis
- Amount analysis

---

## 2. Receiver History Dataset

This dataset represents receiver intelligence.

Fields include:

- receiver_upi
- fraud_flag_ratio
- receiver transaction history
- receiver reputation
- impossible travel events
- historical fraud indicators

Purpose:

- Receiver risk evaluation
- Fraud pattern detection
- Receiver behavior analysis

---

# Why Synthetic Data Is Suitable

The goal of the project is not to memorize transaction records.

The goal is to learn behavioral patterns.

The model learns relationships between:

- Amount deviations
- Velocity anomalies
- Time-based anomalies
- Receiver behavior

These relationships can be realistically simulated using synthetic transaction histories while preserving privacy.

---

# Why CatBoost?

Several machine learning models were evaluated conceptually.

| Model | Advantages | Limitations |
|---------|------------|------------|
| Logistic Regression | Simple and interpretable | Limited nonlinear modeling |
| Random Forest | Strong baseline | Requires tuning |
| XGBoost | High accuracy | More preprocessing |
| Neural Networks | Powerful on large datasets | Requires large training data |
| CatBoost | Strong tabular performance, minimal preprocessing, robust on smaller datasets | Slightly slower training |

CatBoost was selected because:

- Works exceptionally well on structured transaction data
- Handles mixed numerical and categorical features
- Requires minimal preprocessing
- Performs well on relatively small datasets
- Reduces overfitting risk
- Produces stable probability estimates

These properties make CatBoost suitable for fraud detection systems based on transactional data.

---

# Features Used By The Model

## Amount Features

- amount
- avg_amount_7d
- avg_amount_30d
- max_amount_7d
- amount_deviation

## Activity Features

- txn_count_1h
- txn_count_24h
- velocity_ratio
- days_since_last_txn

## Time Features

- txn_hour
- is_night
- unusual_hour
- night_txn_ratio

## Location Features

- location_mismatch
- impossible_travel_count

## Receiver Features

- fraud_flag_ratio
- receiver_risk_history
- receiver_impossible_travel

---

# Three-Layer Risk Architecture

The ML model is only one component of the fraud prevention system.

The final risk score is generated using three independent layers.

---

## Layer 1 - Relationship Analysis

Purpose:

Determine how familiar the sender is with the receiver.

Questions answered:

- Is this a first-time receiver?
- How many times has the sender paid this receiver?
- When was the last interaction?

Output:

Relationship Risk Score (0-100)

---

## Layer 2 - Amount Analysis

Purpose:

Determine how unusual the transaction amount is for the sender.

Questions answered:

- Is the amount abnormal?
- Does it exceed historical spending behavior?

Output:

Amount Risk Score (0-100)

---

## Layer 3 - Receiver Intelligence

Purpose:

Evaluate receiver risk using Machine Learning and receiver history.

Questions answered:

- Does the receiver exhibit suspicious behavior?
- Has the receiver been associated with previous fraud indicators?
- Does the receiver show impossible travel patterns?

Output:

Receiver Risk Score (0-100)

---

# Final Risk Engine

The final fraud score is calculated using three independent risk signals.

## Suspicion Score

Receiver Intelligence: 60%

Relationship Analysis: 25%

Amount Analysis: 15%

The amount score is additionally used as a damage multiplier.

This allows large suspicious transactions to receive higher risk scores while preventing small harmless transactions from being blocked unnecessarily.

---

# Risk Actions

| Risk Score | Action |
|------------|---------|
| 0 - 24 | ALLOW |
| 25 - 44 | WARNING |
| 45 - 69 | OTP REQUIRED |
| 70+ | BLOCK |

---

# Key Principle

SentraPay does not attempt to identify fraudsters directly.

Instead, it evaluates:

- User behavior
- Transaction abnormality
- Receiver intelligence

to determine whether a payment moment is risky before money leaves the user's account.

This approach reduces false positives while providing real-time fraud protection.
