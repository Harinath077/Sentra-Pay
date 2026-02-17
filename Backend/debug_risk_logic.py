
from typing import Dict, Optional, List
from dataclasses import dataclass

# --- MOCK CONTEXT CLASSES ---
@dataclass
class UserContext:
    user_profile: dict
    txn_stats: dict
    receiver_info: dict

# --- COPY OF LOGIC FROM risk_orchestrator.py ---
def combine_scores(rule_score: float, ml_score: float, flags: list, context, txn_data: Dict) -> float:
    score = 0.0
    
    # 1. Receiver History Analysis (STRICT LOGIC)
    receiver_history = context.receiver_info
    is_new = receiver_history.get("is_new", True)
    is_good = receiver_history.get("good_history", False)
    is_risky = receiver_history.get("risky_history", False)
    
    print(f"DEBUG: is_new={is_new}, is_good={is_good}, is_risky={is_risky}")
    
    # 2. Add Base Signals
    amount = float(txn_data.get("amount", 0.0))
    avg_amount = context.txn_stats.get("avg_amount_30d", 1000.0)
    if avg_amount > 0 and amount > (avg_amount * 5):
        score += 0.15
        
    if "DEVICE_CHANGE" in flags:
        score += 0.15
    
    score += (ml_score * 0.15)
    score += (rule_score * 0.10)
    
    # 3. APPLY HISTORY WEIGHTS LAST
    if is_new:
        score += 0.20
        # If after addition total risk > 0.70, boost it to 0.95 + 0.01 (STRICT REQ)
        if score > 0.70:
            score = 0.96
    
    elif is_good:
        score -= 0.05
        
    elif is_risky:
        score += 0.25

    return max(0.0, min(1.0, score))


# --- COPY OF LOGIC FROM context_engine.py ---
def analyze_receiver_history_logic(txn_count: int, history_record_exists: bool, failed_count: int, blocked_count: int, high_risk_flags: int, avg_risk: float):
    # A receiver is "NEW" if no COMPLETED transactions exist in history table OR transaction table
    # Logic in code: is_new = (txn_count == 0) and (history_record is None)
    is_new = (txn_count == 0) and (not history_record_exists)
    
    # Case 2: Good History
    is_good = (
        txn_count >= 2 and 
        blocked_count == 0 and 
        high_risk_flags == 0 and 
        avg_risk < 0.50
    )
    
    # Case 3: Risky History
    is_risky = (
        failed_count >= 2 or 
        blocked_count > 0 or 
        high_risk_flags > 0 or 
        avg_risk > 0.70
    )
    
    return {
        "is_new": is_new,
        "good_history": is_good,
        "risky_history": is_risky
    }

# --- TEST CASES ---
print("\n--- TEST CASE 1: True New Receiver ---")
# No history, 0 txns
hist_analysis = analyze_receiver_history_logic(txn_count=0, history_record_exists=False, failed_count=0, blocked_count=0, high_risk_flags=0, avg_risk=0.0)
ctx = UserContext(user_profile={}, txn_stats={}, receiver_info=hist_analysis)
score = combine_scores(rule_score=0.4, ml_score=0.4, flags=[], context=ctx, txn_data={"amount": 500})
print(f"Result Score: {score:.2f}")

print("\n--- TEST CASE 2: One Successful Transaction (Real-time update) ---")
# User just made 1 transaction. history_record_exists=True (because /execute creates it) OR txn_count=1
hist_analysis = analyze_receiver_history_logic(txn_count=1, history_record_exists=True, failed_count=0, blocked_count=0, high_risk_flags=0, avg_risk=0.1)
ctx = UserContext(user_profile={}, txn_stats={}, receiver_info=hist_analysis)
score = combine_scores(rule_score=0.4, ml_score=0.4, flags=[], context=ctx, txn_data={"amount": 500})
print(f"Result Score: {score:.2f}")
