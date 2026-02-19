import os
import json
os.environ.setdefault('DATABASE_URL', 'sqlite:///:memory:')
os.environ.setdefault('REDIS_URL', 'redis://localhost')
os.environ.setdefault('SECRET_KEY', 'dev')

from app.core.history_engine import compute_user_stats, get_receiver_summary_for_user
from app.core.context_engine import UserContext
from app.core.rules_engine import evaluate
from app.core.ml_engine import predict
from app.core.risk_orchestrator import RiskOrchestrator
from app.core.decision_engine import get_action, generate_message, generate_recommendations
from app.config import settings

# Build context from CSV/demo
sender = 'user10@upi'
receiver = 'recv16@upi'
amount = 1000

stats = compute_user_stats(sender)
rec = get_receiver_summary_for_user(sender, receiver)
profile = {'user_id': sender, 'known_devices': [], 'trust_score': 0, 'risk_tier': 'BRONZE'}
ctx = UserContext(profile, stats, rec)

txn = {'amount': amount, 'receiver': receiver, 'device_id': 'dev-run-1', 'ip_city': 'Mumbai'}

# Run rules + ML
rule_res = evaluate(txn, ctx)
ml_res = predict(txn, ctx)

orc = RiskOrchestrator()
final = orc._combine_scores(rule_score=rule_res.rule_score, ml_score=ml_res.ml_score, flags=rule_res.flags, context=ctx, txn_data=txn)

# Apply orchestrator post-decision identity policy (same logic as in analyze_transaction)
action_result = get_action(risk_score=final, flags=rule_res.flags, user_tier=ctx.user_profile.get('risk_tier', 'BRONZE'))
identity_flags = {"IMPOSSIBLE_TRAVEL", "DEVICE_CHANGE", "NEW_DEVICE"}
identity_risk = bool(set(rule_res.flags) & identity_flags) or bool(ctx.txn_stats.get('impossible_travel_flag', False))

low_thr = settings.RISK_THRESHOLD_MODERATE
high_thr = settings.RISK_THRESHOLD_HIGH

if identity_risk and final < low_thr:
    action_result.action = "OTP_REQUIRED"
    action_result.requires_otp = True
    action_result.risk_level = "HIGH"
    action_result.message = generate_message(action_result.risk_level, action_result.action, rule_res.flags)
    action_result.recommendations = generate_recommendations(action_result.risk_level, rule_res.flags)

elif final >= high_thr and not identity_risk:
    action_result.action = "WARNING"
    action_result.requires_otp = False
    action_result.risk_level = "HIGH"
    action_result.message = generate_message(action_result.risk_level, action_result.action, rule_res.flags)
    action_result.recommendations = generate_recommendations(action_result.risk_level, rule_res.flags)

elif identity_risk and final >= high_thr:
    action_result.action = "BLOCK"
    action_result.requires_otp = False
    action_result.risk_level = "VERY_HIGH"
    action_result.message = generate_message(action_result.risk_level, action_result.action, rule_res.flags)
    action_result.recommendations = generate_recommendations(action_result.risk_level, rule_res.flags)

out = {
    'sender': sender,
    'receiver': receiver,
    'amount': amount,
    'ml_score': round(ml_res.ml_score,3),
    'rule_score': round(rule_res.rule_score,3),
    'rule_flags': rule_res.flags,
    'behavior_score': round(max(ml_res.ml_score, rule_res.rule_score),3),
    'final_raw': round(final,4),
    'impossible_travel_flag': ctx.txn_stats.get('impossible_travel_flag'),
    'identity_risk': identity_risk,
    'action': action_result.action,
    'risk_level': action_result.risk_level,
    'requires_otp': action_result.requires_otp
}

print(json.dumps(out, indent=2))
