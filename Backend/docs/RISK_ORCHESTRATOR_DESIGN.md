# 🧠 Risk Orchestrator Design
## The Brain of the Fraud Detection System

---

## 🎯 Purpose

The Risk Orchestrator is the **central decision-making component** that:
1. Coordinates all risk assessment modules
2. Combines multiple signals (rules + ML + context)
3. Produces a unified risk score
4. Determines the appropriate action

**It is NOT a simple "if ML > 0.5 then block" system.**

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│         Transaction Request                 │
│   { amount, receiver, user_id }             │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│      RISK ORCHESTRATOR (risk_orchestrator.py)│
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ 1. Context Gathering                │   │
│  │    - User profile (Redis → DB)      │   │
│  │    - Transaction history            │   │
│  │    - Device fingerprint             │   │
│  │    - Receiver reputation            │   │
│  └─────────────────────────────────────┘   │
│                   │                         │
│                   ▼                         │
│  ┌─────────────────────────────────────┐   │
│  │ 2. Rules Engine Check               │   │
│  │    - Velocity rules                 │   │
│  │    - Blacklist check                │   │
│  │    - Amount anomaly rules           │   │
│  │    - Device change rules            │   │
│  │    → Returns: rule_score, flags     │   │
│  └─────────────────────────────────────┘   │
│                   │                         │
│                   ▼                         │
│  ┌─────────────────────────────────────┐   │
│  │ 3. ML Engine Prediction             │   │
│  │    - Feature engineering            │   │
│  │    - CatBoost inference             │   │
│  │    → Returns: ml_probability        │   │
│  └─────────────────────────────────────┘   │
│                   │                         │
│                   ▼                         │
│  ┌─────────────────────────────────────┐   │
│  │ 4. Score Combination                │   │
│  │    - Weighted average               │   │
│  │    - Rule overrides                 │   │
│  │    → Returns: final_score           │   │
│  └─────────────────────────────────────┘   │
│                   │                         │
│                   ▼                         │
│  ┌─────────────────────────────────────┐   │
│  │ 5. Decision Mapping                 │   │
│  │    - Map score → action             │   │
│  │    - Determine friction level       │   │
│  │    → Returns: action, message       │   │
│  └─────────────────────────────────────┘   │
│                   │                         │
│                   ▼                         │
│  ┌─────────────────────────────────────┐   │
│  │ 6. Response Construction            │   │
│  │    - Risk breakdown                 │   │
│  │    - Factors explanation            │   │
│  │    - Recommendations                │   │
│  └─────────────────────────────────────┘   │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│         Risk Analysis Response              │
│   { risk_score, risk_level, action, ... }   │
└─────────────────────────────────────────────┘
```

---

## 📝 Pseudo-code Implementation

```python
class RiskOrchestrator:
    def __init__(self):
        self.rules_engine = RulesEngine()
        self.ml_engine = MLEngine()
        self.context_engine = ContextEngine()
        self.decision_engine = DecisionEngine()
    
    def analyze_transaction(self, txn_data: dict, user_id: str) -> dict:
        """
        Main orchestration method.
        
        Args:
            txn_data: { amount, receiver, note, ... }
            user_id: Authenticated user ID
        
        Returns:
            Complete risk analysis response
        """
        
        # ────────────────────────────────────────────────
        # STEP 1: GATHER CONTEXT
        # ────────────────────────────────────────────────
        context = self.context_engine.get_user_context(user_id)
        # Returns:
        # {
        #   user_profile: { trust_score, risk_tier, ... }
        #   txn_history: [ ... last 30 days ... ]
        #   known_devices: [ ... ]
        #   receiver_reputation: 0.5
        # }
        
        # ────────────────────────────────────────────────
        # STEP 2: RUN RULES ENGINE
        # ────────────────────────────────────────────────
        rule_result = self.rules_engine.evaluate(txn_data, context)
        # Returns:
        # {
        #   rule_score: 0.35,
        #   flags: ["NEW_RECEIVER_HIGH_AMOUNT", "VELOCITY_OK"],
        #   hard_block: False
        # }
        
        # Check for hard blocks (override everything)
        if rule_result.hard_block:
            return self._create_blocked_response(
                reason=rule_result.block_reason,
                txn_data=txn_data
            )
        
        # ────────────────────────────────────────────────
        # STEP 3: RUN ML ENGINE
        # ────────────────────────────────────────────────
        ml_result = self.ml_engine.predict(txn_data, context)
        # Returns:
        # {
        #   ml_score: 0.20,
        #   features: { ... 14 features ... },
        #   model_version: "v1.1"
        # }
        
        # ────────────────────────────────────────────────
        # STEP 4: COMBINE SCORES
        # ────────────────────────────────────────────────
        final_score = self._combine_scores(
            rule_score=rule_result.rule_score,
            ml_score=ml_result.ml_score,
            flags=rule_result.flags,
            context=context
        )
        # Returns: 0.55 (weighted combination)
        
        # ────────────────────────────────────────────────
        # STEP 5: DETERMINE ACTION
        # ────────────────────────────────────────────────
        action = self.decision_engine.get_action(
            risk_score=final_score,
            flags=rule_result.flags,
            user_tier=context.user_profile.risk_tier
        )
        # Returns: { action: "WARNING", requires_otp: False, ... }
        
        # ────────────────────────────────────────────────
        # STEP 6: BUILD RESPONSE
        # ────────────────────────────────────────────────
        response = self._build_response(
            final_score=final_score,
            rule_result=rule_result,
            ml_result=ml_result,
            action=action,
            txn_data=txn_data,
            context=context
        )
        
        # ────────────────────────────────────────────────
        # STEP 7: LOG EVENT
        # ────────────────────────────────────────────────
        self._log_risk_event(
            user_id=user_id,
            txn_data=txn_data,
            final_score=final_score,
            action=action,
            rule_result=rule_result,
            ml_result=ml_result
        )
        
        return response
    
    # ────────────────────────────────────────────────────
    # SCORE COMBINATION LOGIC
    # ────────────────────────────────────────────────────
    def _combine_scores(self, rule_score, ml_score, flags, context):
        """
        Combine rule score and ML score intelligently.
        
        Strategy:
        1. If hard flags present → use rule score primarily
        2. If user is new → weight rules higher
        3. If user is trusted → weight ML higher
        4. Use weighted average
        """
        
        # Base weights
        rule_weight = 0.6
        ml_weight = 0.4
        
        # Adjust weights based on context
        if context.user_profile.risk_tier == "GOLD":
            rule_weight = 0.4
            ml_weight = 0.6  # Trust ML more for good users
        
        if "NEW_USER" in flags:
            rule_weight = 0.8
            ml_weight = 0.2  # Trust rules more for new users
        
        # Weighted combination
        combined = (rule_score * rule_weight) + (ml_score * ml_weight)
        
        # Cap at 1.0
        return min(1.0, combined)
    
    # ────────────────────────────────────────────────────
    # RESPONSE CONSTRUCTION
    # ────────────────────────────────────────────────────
    def _build_response(self, final_score, rule_result, ml_result, 
                        action, txn_data, context):
        """
        Build comprehensive risk analysis response.
        """
        
        # Determine risk level
        risk_level = self._get_risk_level(final_score)
        
        # Build risk breakdown (matches UI)
        risk_breakdown = {
            "behavior_analysis": {
                "score": self._calculate_behavior_score(context),
                "weight": 30,
                "factors": self._get_behavior_factors(context)
            },
            "amount_analysis": {
                "score": self._calculate_amount_score(txn_data, context),
                "weight": 30,
                "factors": self._get_amount_factors(txn_data, context)
            },
            "receiver_analysis": {
                "score": self._calculate_receiver_score(txn_data, context),
                "weight": 40,
                "factors": self._get_receiver_factors(txn_data, context)
            }
        }
        
        # Build response
        return {
            "transaction_id": self._generate_txn_id(),
            "risk_score": final_score,
            "risk_level": risk_level,
            "risk_percentage": int(final_score * 100),
            "action": action.action,
            "message": action.message,
            
            "risk_breakdown": risk_breakdown,
            "factors": self._extract_top_factors(rule_result, ml_result),
            
            "receiver_info": {
                "name": self._get_receiver_name(txn_data.receiver),
                "verified": False,
                "reputation_score": context.receiver_reputation,
                "total_transactions": 0
            },
            
            "recommendations": self._get_recommendations(
                final_score, rule_result.flags
            ),
            
            "can_proceed": action.can_proceed,
            "requires_otp": action.requires_otp,
            "estimated_delay": action.estimated_delay
        }
    
    # ────────────────────────────────────────────────────
    # HELPER METHODS
    # ────────────────────────────────────────────────────
    def _get_risk_level(self, score):
        if score < 0.30:
            return "LOW"
        elif score < 0.60:
            return "MODERATE"
        elif score < 0.80:
            return "HIGH"
        else:
            return "VERY_HIGH"
    
    def _calculate_behavior_score(self, context):
        """Calculate behavior analysis score (0-100)"""
        # Based on:
        # - Transaction velocity
        # - Device consistency
        # - Time patterns
        # - User tenure
        return 30  # Example
    
    def _calculate_amount_score(self, txn_data, context):
        """Calculate amount analysis score (0-100)"""
        # Based on:
        # - Amount vs. average
        # - Amount vs. max historical
        # - Percentile in user's history
        
        avg_amount = context.txn_history.avg_amount_30d
        amount_ratio = txn_data.amount / avg_amount
        
        if amount_ratio > 10:
            return 100  # Very high risk
        elif amount_ratio > 5:
            return 80
        elif amount_ratio > 3:
            return 60
        elif amount_ratio > 1.5:
            return 40
        else:
            return 20
    
    def _calculate_receiver_score(self, txn_data, context):
        """Calculate receiver analysis score (0-100)"""
        # Based on:
        # - New vs. known receiver
        # - Receiver reputation
        # - Transaction frequency with receiver
        
        if txn_data.receiver not in context.known_receivers:
            return 40  # New receiver
        else:
            return 10  # Known receiver
    
    def _extract_top_factors(self, rule_result, ml_result):
        """Extract top 3-5 risk factors for user explanation"""
        factors = []
        
        for flag in rule_result.flags:
            if flag == "NEW_RECEIVER_HIGH_AMOUNT":
                factors.append("New receiver with high amount")
            elif flag == "VELOCITY_SPIKE":
                factors.append("Unusual transaction frequency")
            # ... more mappings
        
        return factors[:5]  # Top 5
    
    def _get_recommendations(self, score, flags):
        """Provide actionable recommendations to user"""
        recommendations = []
        
        if "NEW_RECEIVER" in flags:
            recommendations.append("Verify receiver identity before proceeding")
        
        if score > 0.60:
            recommendations.append("Consider breaking into smaller amounts")
        
        if "HIGH_AMOUNT" in flags:
            recommendations.append("Contact receiver through alternate channel")
        
        return recommendations
```

---

## 🎛️ Configuration

### Score Weights
```python
SCORE_WEIGHTS = {
    "rule_weight": 0.6,
    "ml_weight": 0.4,
    
    # Adjust for user tiers
    "BRONZE": {"rule_weight": 0.8, "ml_weight": 0.2},
    "SILVER": {"rule_weight": 0.6, "ml_weight": 0.4},
    "GOLD": {"rule_weight": 0.4, "ml_weight": 0.6}
}
```

### Risk Thresholds
```python
RISK_THRESHOLDS = {
    "LOW": (0.0, 0.30),
    "MODERATE": (0.30, 0.60),
    "HIGH": (0.60, 0.80),
    "VERY_HIGH": (0.80, 1.0)
}
```

### Action Mapping
```python
ACTION_MAPPING = {
    "LOW": {
        "action": "ALLOW",
        "can_proceed": True,
        "requires_otp": False,
        "estimated_delay": 0,
        "message": "Transaction approved"
    },
    "MODERATE": {
        "action": "WARNING",
        "can_proceed": True,
        "requires_otp": False,
        "estimated_delay": 0,
        "message": "This transaction has moderate risk. Review before proceeding."
    },
    "HIGH": {
        "action": "OTP_REQUIRED",
        "can_proceed": True,
        "requires_otp": True,
        "estimated_delay": 30,
        "message": "High risk detected. OTP verification required."
    },
    "VERY_HIGH": {
        "action": "BLOCK",
        "can_proceed": False,
        "requires_otp": False,
        "estimated_delay": 0,
        "message": "Transaction blocked due to very high risk."
    }
}
```

---

## 🧪 Testing Strategy

### Unit Tests
```python
def test_score_combination():
    orchestrator = RiskOrchestrator()
    
    # Test case 1: High rule score, low ML score
    result = orchestrator._combine_scores(
        rule_score=0.80,
        ml_score=0.20,
        flags=["NEW_RECEIVER"],
        context=Context(risk_tier="BRONZE")
    )
    assert result > 0.60  # Should be high
    
    # Test case 2: Both low
    result = orchestrator._combine_scores(
        rule_score=0.10,
        ml_score=0.15,
        flags=[],
        context=Context(risk_tier="GOLD")
    )
    assert result < 0.30  # Should be low
```

### Integration Tests
```python
def test_full_transaction_flow():
    orchestrator = RiskOrchestrator()
    
    txn_data = {
        "amount": 9000000,
        "receiver": "unknown@upi"
    }
    
    result = orchestrator.analyze_transaction(
        txn_data=txn_data,
        user_id="USER-12345"
    )
    
    assert "risk_score" in result
    assert "action" in result
    assert "risk_breakdown" in result
```

---

## 📊 Performance Metrics

**Target Metrics:**
- Orchestration Time: < 200ms (p95)
- Rules Engine: < 20ms
- ML Engine: < 50ms
- Database Queries: < 30ms
- Cache Lookups: < 5ms

**Monitoring:**
```python
import time

def analyze_transaction(self, txn_data, user_id):
    start_time = time.time()
    
    # ... orchestration logic ...
    
    elapsed = time.time() - start_time
    
    # Log metrics
    logger.info(f"Orchestration completed in {elapsed*1000:.2f}ms")
    metrics.record("orchestration.duration", elapsed)
```

---

## 🔍 Debugging & Observability

### Logging
```python
logger.info(f"Risk analysis started for user {user_id}")
logger.debug(f"Context: {context}")
logger.debug(f"Rule result: {rule_result}")
logger.debug(f"ML result: {ml_result}")
logger.info(f"Final decision: {action} with score {final_score}")
```

### Tracing
```python
# Add transaction ID to all logs
with logger.contextualize(txn_id=txn_id):
    # All logs will include txn_id
    pass
```

---

## 📚 Related Documents
- [Backend Architecture Guide](./BACKEND_ARCHITECTURE_GUIDE.md)
- [Rules Engine Design](./RULES_ENGINE_DESIGN.md)
- [ML Engine Design](./ML_ENGINE_DESIGN.md)
- [Decision Engine Design](./DECISION_ENGINE_DESIGN.md)

---

**Last Updated:** February 3, 2026  
**Component Version:** 2.0  
**Status:** Design Complete ✅
