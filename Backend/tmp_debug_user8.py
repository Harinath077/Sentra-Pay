import os
import importlib
import json

# Ensure minimal environment so Settings validation passes during local debug
os.environ.setdefault('DATABASE_URL', 'sqlite:///:memory:')
os.environ.setdefault('REDIS_URL', 'redis://localhost')
os.environ.setdefault('SECRET_KEY', 'dev')

# reload modules to pick up latest edits
import app.core.risk_orchestrator as ro
import app.core.ml_engine as ml_engine
import app.core.rules_engine as rules_engine
importlib.reload(ro)
importlib.reload(ml_engine)
importlib.reload(rules_engine)

from app.core.history_engine import compute_user_stats, get_receiver_summary_for_user
from app.core.context_engine import UserContext
from app.core.rules_engine import evaluate
from app.core.ml_engine import predict
from app.core.risk_orchestrator import RiskOrchestrator

stats = compute_user_stats('user8@upi')
rec = get_receiver_summary_for_user('user8@upi','recv6@upi')
profile = {'user_id':'user8@upi','known_devices':[], 'trust_score':0, 'risk_tier':'BRONZE'}
ctx = UserContext(profile, stats, rec)

txn = {'amount':1000, 'receiver':'recv6@upi', 'device_id':'dev-test-2', 'ip_city':'Delhi'}

rule_res = evaluate(txn, ctx)
ml_res = predict(txn, ctx)
orc = RiskOrchestrator()

# compute intermediate values here (must match logic in risk_orchestrator)
amount = float(txn['amount'])
avg_amount = ctx.txn_stats.get('avg_amount_30d', 1000.0)
receiver_history = ctx.receiver_info or {}
recv_score = float(receiver_history.get('reputation_score', 0.5))
behavior_score = max(float(ml_res.ml_score or 0.0), float(rule_res.rule_score or 0.0))
final_raw = (0.55 * behavior_score + 0.25 * float(rule_res.rule_score or 0.0) + 0.10 * (1.0 - recv_score))
ratio = amount / (avg_amount + 1.0)
if ratio < 0.3:
    damage_multiplier = 0.25
elif ratio < 1.0:
    damage_multiplier = 0.5
elif ratio < 3.0:
    damage_multiplier = 0.8
else:
    damage_multiplier = 1.0
final = final_raw * damage_multiplier

print(json.dumps({
    'ml_score': round(ml_res.ml_score,3),
    'rule_score': round(rule_res.rule_score,3),
    'behavior_score': round(behavior_score,3),
    'final_raw': round(final_raw,4),
    'ratio': round(ratio,4),
    'damage_multiplier': damage_multiplier,
    'final': round(final,4),
    'impossible_travel_flag': ctx.txn_stats.get('impossible_travel_flag')
}, indent=2))

# Now run orchestrator combine (applies impossible-travel min floor etc)
orc_final = orc._combine_scores(rule_score=rule_res.rule_score, ml_score=ml_res.ml_score, flags=rule_res.flags, context=ctx, txn_data=txn)
from app.core.decision_engine import get_action
action = get_action(risk_score=orc_final, flags=rule_res.flags, user_tier=profile.get('risk_tier','BRONZE'))
print('\nOrchestrator final (after policy overrides):', round(orc_final,4))
print('Decision:', action.action, action.risk_level)
