"""
Dashboard API - Provides aggregated statistics for the Sentra Pay Dashboard.
"""

from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, case, cast, Float, extract
from datetime import datetime, timedelta
import logging

from app.database.connection import get_db
from app.database.models import User, Transaction, RiskEvent, ReceiverReputation

logger = logging.getLogger(__name__)

dashboard_router = APIRouter(tags=["Dashboard"])
router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])


@dashboard_router.get("/dashboard", response_class=HTMLResponse)
async def serve_dashboard():
    """Serve the analytics dashboard HTML page."""
    import os
    html_path = os.path.join(os.path.dirname(__file__), "..", "..", "static", "dashboard.html")
    html_path = os.path.abspath(html_path)
    try:
        with open(html_path, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    except FileNotFoundError:
        return HTMLResponse(content="<h1>Dashboard not found</h1>", status_code=404)


@router.get("/stats")
async def get_dashboard_stats(db: Session = Depends(get_db)):
    """
    Aggregated statistics for the admin dashboard.
    Returns KPIs, risk distribution, recent transactions, and trend data.
    """
    now = datetime.utcnow()
    last_30_days = now - timedelta(days=30)
    last_7_days = now - timedelta(days=7)

    # ── KPI Cards ──
    total_users = db.query(func.count(User.id)).scalar() or 0
    total_transactions = db.query(func.count(Transaction.id)).scalar() or 0
    total_volume = db.query(func.coalesce(func.sum(Transaction.amount), 0)).scalar()

    blocked_count = db.query(func.count(Transaction.id)).filter(
        Transaction.status == "BLOCKED"
    ).scalar() or 0

    completed_count = db.query(func.count(Transaction.id)).filter(
        Transaction.status == "COMPLETED"
    ).scalar() or 0

    # Fraud prevention rate
    fraud_prevention_rate = 0.0
    if total_transactions > 0:
        fraud_prevention_rate = round((blocked_count / total_transactions) * 100, 1)

    # Average risk score
    avg_risk = db.query(func.coalesce(func.avg(Transaction.risk_score), 0)).scalar()

    # ── Risk Distribution (for donut chart) ──
    low_risk = db.query(func.count(Transaction.id)).filter(
        Transaction.risk_level == "LOW"
    ).scalar() or 0
    moderate_risk = db.query(func.count(Transaction.id)).filter(
        Transaction.risk_level.in_(["MODERATE", "MEDIUM"])
    ).scalar() or 0
    high_risk = db.query(func.count(Transaction.id)).filter(
        Transaction.risk_level == "HIGH"
    ).scalar() or 0
    very_high_risk = db.query(func.count(Transaction.id)).filter(
        Transaction.risk_level == "VERY_HIGH"
    ).scalar() or 0

    # ── Action Distribution ──
    allowed = db.query(func.count(Transaction.id)).filter(
        Transaction.action_taken == "ALLOW"
    ).scalar() or 0
    warned = db.query(func.count(Transaction.id)).filter(
        Transaction.action_taken == "WARNING"
    ).scalar() or 0
    otp_required = db.query(func.count(Transaction.id)).filter(
        Transaction.action_taken == "OTP_REQUIRED"
    ).scalar() or 0
    blocked = db.query(func.count(Transaction.id)).filter(
        Transaction.action_taken == "BLOCK"
    ).scalar() or 0

    # ── Recent Transactions (last 10) ──
    recent_txns = db.query(Transaction).order_by(
        Transaction.created_at.desc()
    ).limit(10).all()

    recent_list = []
    for txn in recent_txns:
        recent_list.append({
            "id": txn.transaction_id,
            "amount": float(txn.amount) if txn.amount else 0,
            "receiver": txn.receiver,
            "risk_score": round(txn.risk_score, 2) if txn.risk_score else 0,
            "risk_level": txn.risk_level or "N/A",
            "action": txn.action_taken or "N/A",
            "status": txn.status,
            "date": txn.created_at.isoformat() if txn.created_at else ""
        })

    # ── Daily Transaction Volume (last 7 days) ──
    daily_volume = []
    for i in range(6, -1, -1):
        day = now - timedelta(days=i)
        day_start = day.replace(hour=0, minute=0, second=0, microsecond=0)
        day_end = day_start + timedelta(days=1)

        count = db.query(func.count(Transaction.id)).filter(
            Transaction.created_at >= day_start,
            Transaction.created_at < day_end
        ).scalar() or 0

        vol = db.query(func.coalesce(func.sum(Transaction.amount), 0)).filter(
            Transaction.created_at >= day_start,
            Transaction.created_at < day_end
        ).scalar()

        daily_volume.append({
            "date": day_start.strftime("%b %d"),
            "count": count,
            "volume": float(vol)
        })

    # ── User Trust Tier Distribution ──
    bronze = db.query(func.count(User.id)).filter(User.risk_tier == "BRONZE").scalar() or 0
    silver = db.query(func.count(User.id)).filter(User.risk_tier == "SILVER").scalar() or 0
    gold = db.query(func.count(User.id)).filter(User.risk_tier == "GOLD").scalar() or 0

    # ── Top Flagged Receivers ──
    top_receivers = db.query(ReceiverReputation).order_by(
        ReceiverReputation.reputation_score.desc()
    ).limit(5).all()

    flagged_receivers = []
    for r in top_receivers:
        flagged_receivers.append({
            "receiver": r.receiver,
            "score": round(r.reputation_score, 2),
            "total_txns": r.total_transactions,
            "fraud_count": r.fraud_count
        })

    return {
        "kpis": {
            "total_users": total_users,
            "total_transactions": total_transactions,
            "total_volume": float(total_volume),
            "blocked_count": blocked_count,
            "completed_count": completed_count,
            "fraud_prevention_rate": fraud_prevention_rate,
            "avg_risk_score": round(float(avg_risk), 2)
        },
        "risk_distribution": {
            "low": low_risk,
            "moderate": moderate_risk,
            "high": high_risk,
            "very_high": very_high_risk
        },
        "action_distribution": {
            "allowed": allowed,
            "warned": warned,
            "otp_required": otp_required,
            "blocked": blocked
        },
        "recent_transactions": recent_list,
        "daily_volume": daily_volume,
        "user_tiers": {
            "bronze": bronze,
            "silver": silver,
            "gold": gold
        },
        "flagged_receivers": flagged_receivers
    }
