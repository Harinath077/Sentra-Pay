import os
import json

# Ensure minimal env for local debug
os.environ.setdefault('DATABASE_URL', 'sqlite:///:memory:')
os.environ.setdefault('REDIS_URL', 'redis://localhost')
os.environ.setdefault('SECRET_KEY', 'dev')
from app.core.history_engine import compute_user_stats, get_receiver_summary_for_user
from app.core.context_engine import UserContext
from app.core.rules_engine import evaluate
from app.core.ml_engine import predict
from app.core.risk_orchestrator import RiskOrchestrator
from app.core.decision_engine import get_action

stats = compute_user_stats('user8@upi')
rec = get_receiver_summary_for_user('user8@upi','recv6@upi')
profile = {'user_id':'user8@upi','known_devices':[], 'trust_score':0, 'risk_tier':'BRONZE'}
ctx = UserContext(profile, stats, rec)

txn = {'amount':1000, 'receiver':'recv6@upi', 'device_id':'dev-test-2', 'ip_city':'Delhi'}

rule_res = evaluate(txn, ctx)
ml_res = predict(txn, ctx)
orc = RiskOrchestrator()
final = orc._combine_scores(rule_score=rule_res.rule_score, ml_score=ml_res.ml_score, flags=rule_res.flags, context=ctx, txn_data=txn)
action = get_action(risk_score=final, flags=rule_res.flags, user_tier=profile.get('risk_tier','BRONZE'))

out = {
    'rule_score': round(rule_res.rule_score,3),
    'rule_flags': rule_res.flags,
    'ml_score': round(ml_res.ml_score,3),
    'ml_model_version': ml_res.model_version,
    'final_score': round(final,3),
    'receiver_analysis': {
         'score': round(rec.get('reputation_score',0),3),
         'is_new': rec.get('is_new', True),
         'total_transactions': rec.get('total_transactions', 0),
         'avg_amount': rec.get('avg_amount', 0)
    },
    'action': {'action': action.action, 'risk_level': action.risk_level}
}
print(json.dumps(out, indent=2))
