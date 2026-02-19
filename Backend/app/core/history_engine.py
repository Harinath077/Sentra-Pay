"""
History Engine - load synthetic CSV memory and compute user history features.

This module reads a configured CSV once and provides helper methods to
retrieve a user's recent transactions and compute statistics used by the
behavioral feature engineering pipeline.
"""
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import csv
import threading
import logging
import os

from app.config import settings
from app.utils import geo_velocity

logger = logging.getLogger(__name__)

# In-memory cache
_loaded = False
_lock = threading.Lock()
_rows: List[Dict] = []


def _load_csv_once():
    global _loaded, _rows
    with _lock:
        if _loaded:
            return
        path = getattr(settings, "HISTORY_CSV_PATH", "./synthetic_upi_behavior_100.csv")
        if not os.path.exists(path):
            logger.warning(f"History CSV not found at {path}; history engine will be empty.")
            _rows = []
            _loaded = True
            return

        rows = []
        try:
            with open(path, newline='', encoding='utf-8') as fh:
                reader = csv.DictReader(fh)
                for r in reader:
                    # Parse timestamp
                    try:
                        r_ts = datetime.strptime(r.get('timestamp', ''), '%Y-%m-%d %H:%M:%S')
                    except Exception:
                        # skip malformed
                        continue
                    r['timestamp'] = r_ts
                    # normalize amount
                    try:
                        r['amount'] = float(r.get('amount', 0) or 0)
                    except Exception:
                        r['amount'] = 0.0
                    # normalize status
                    r['status'] = (r.get('status') or '').upper()
                    rows.append(r)
            # sort by timestamp asc
            rows.sort(key=lambda x: x['timestamp'])
            _rows = rows
            logger.info(f"Loaded {len(_rows)} history rows from {path}")
        except Exception as e:
            logger.error(f"Failed to load history CSV: {e}")
            _rows = []
        _loaded = True


def get_user_history(sender_upi: str, limit: int = 100) -> List[Dict]:
    """Return recent history rows for `sender_upi`, newest first."""
    if not _loaded:
        _load_csv_once()
    if not sender_upi or not _rows:
        return []
    filtered = [r for r in _rows if r.get('sender_upi') == sender_upi]
    # return last `limit` rows, newest first
    return list(reversed(filtered[-limit:]))


def compute_user_stats(sender_upi: str, now: Optional[datetime] = None) -> Dict:
    """Compute transaction statistics used by ML features for a user."""
    if now is None:
        now = datetime.utcnow()
    txns = get_user_history(sender_upi, limit=1000)

    thirty_days_ago = now - timedelta(days=30)
    seven_days_ago = now - timedelta(days=7)
    one_day_ago = now - timedelta(days=1)
    one_hour_ago = now - timedelta(hours=1)
    five_min_ago = now - timedelta(minutes=5)

    txns_30d = [t for t in txns if t['timestamp'] >= thirty_days_ago]
    txn_count_30d = len(txns_30d)
    amounts_30d = [t['amount'] for t in txns_30d]
    avg_amount_30d = sum(amounts_30d) / len(amounts_30d) if amounts_30d else 0.0
    max_amount_30d = max(amounts_30d) if amounts_30d else 0.0

    txns_7d = [t for t in txns_30d if t['timestamp'] >= seven_days_ago]
    avg_amount_7d = sum([t['amount'] for t in txns_7d]) / len(txns_7d) if txns_7d else 0.0
    max_amount_7d = max([t['amount'] for t in txns_7d]) if txns_7d else 0.0

    txn_count_24h = len([t for t in txns if t['timestamp'] >= one_day_ago])
    txn_count_1h = len([t for t in txns if t['timestamp'] >= one_hour_ago])
    txn_count_5min = len([t for t in txns if t['timestamp'] >= five_min_ago])

    night_txns = len([t for t in txns_30d if t['timestamp'].hour >= 23 or t['timestamp'].hour <= 5])
    night_txn_ratio = night_txns / max(txn_count_30d, 1)

    failed_txn_count_7d = len([t for t in txns_7d if t['status'] == 'FAILED'])

    last_txn = txns[0] if txns else None
    days_since_last_txn = (now - last_txn['timestamp']).days if last_txn else 999

    # Fallback: if there are no transactions in the rolling windows (e.g. CSV older than 30 days)
    # compute stats relative to the most recent transaction so demo CSVs still produce meaningful features.
    if txn_count_30d == 0 and txns:
        ref = txns[0]['timestamp']
        ref_thirty_days_ago = ref - timedelta(days=30)
        ref_seven_days_ago = ref - timedelta(days=7)
        ref_one_day_ago = ref - timedelta(days=1)
        ref_one_hour_ago = ref - timedelta(hours=1)
        ref_five_min_ago = ref - timedelta(minutes=5)

        txns_30d = [t for t in txns if t['timestamp'] >= ref_thirty_days_ago]
        txn_count_30d = len(txns_30d)
        amounts_30d = [t['amount'] for t in txns_30d]
        avg_amount_30d = sum(amounts_30d) / len(amounts_30d) if amounts_30d else 0.0
        max_amount_30d = max(amounts_30d) if amounts_30d else 0.0

        txns_7d = [t for t in txns_30d if t['timestamp'] >= ref_seven_days_ago]
        avg_amount_7d = sum([t['amount'] for t in txns_7d]) / len(txns_7d) if txns_7d else 0.0
        max_amount_7d = max([t['amount'] for t in txns_7d]) if txns_7d else 0.0

        txn_count_24h = len([t for t in txns if t['timestamp'] >= ref_one_day_ago])
        txn_count_1h = len([t for t in txns if t['timestamp'] >= ref_one_hour_ago])
        txn_count_5min = len([t for t in txns if t['timestamp'] >= ref_five_min_ago])

        night_txns = len([t for t in txns_30d if t['timestamp'].hour >= 23 or t['timestamp'].hour <= 5])
        night_txn_ratio = night_txns / max(txn_count_30d, 1)

    # Receiver aggregates
    receiver_map = {}
    for t in txns:
        r = t.get('receiver_upi') or t.get('receiver')
        if not r:
            continue
        if r not in receiver_map:
            receiver_map[r] = {'count': 0, 'amounts': []}
        receiver_map[r]['count'] += 1
        receiver_map[r]['amounts'].append(t['amount'])
    # Frequent hours (top 3 hours by count) based on 30d window (fallback to all txns)
    hours = [t['timestamp'].hour for t in txns_30d] if txns_30d else [t['timestamp'].hour for t in txns]
    hour_counts = {}
    for h in hours:
        hour_counts[h] = hour_counts.get(h, 0) + 1
    # sort by frequency desc
    frequent_hours = [h for h, _ in sorted(hour_counts.items(), key=lambda x: -x[1])][:3]

    # Last city and impossible travel heuristic (use coordinates when possible)
    last_city = None
    impossible_travel_flag = False
    # Small map of common city -> (lat, lon). Extend as needed.
    CITY_COORDS = {
        "chennai": (13.0827, 80.2707),
        "delhi": (28.6139, 77.2090),
        "new delhi": (28.6139, 77.2090),
        "hyderabad": (17.3850, 78.4867),
        "bangalore": (12.9716, 77.5946),
        "bengaluru": (12.9716, 77.5946),
        "mumbai": (19.0760, 72.8777),
        "pune": (18.5204, 73.8567),
        "kolkata": (22.5726, 88.3639)
    }

    def _coords_for_city(name: Optional[str]):
        if not name:
            return None
        key = name.strip().lower()
        return CITY_COORDS.get(key)

    if txns:
        last_city = txns[0].get('ip_city') or txns[0].get('city')
        # Prefer coordinate-based impossible-travel detection if we can map cities
        if len(txns) > 1:
            prev_city = txns[1].get('ip_city') or txns[1].get('city')
            last_ts = txns[0]['timestamp']
            prev_ts = txns[1]['timestamp']

            last_coords = _coords_for_city(last_city)
            prev_coords = _coords_for_city(prev_city)

            if last_coords and prev_coords:
                prev_tx = {"lat": prev_coords[0], "lon": prev_coords[1], "timestamp": prev_ts}
                curr_tx = {"lat": last_coords[0], "lon": last_coords[1], "timestamp": last_ts}
                try:
                    gv = geo_velocity.geo_velocity_check(prev_tx, curr_tx)
                    # mark impossible travel only for explicit IMPOSSIBLE_TRAVEL
                    if gv.get("flag") == "IMPOSSIBLE_TRAVEL":
                        impossible_travel_flag = True
                except Exception:
                    # fallback to simple heuristic if geo check fails
                    hours_diff = abs((last_ts - prev_ts).total_seconds()) / 3600.0
                    if last_city and prev_city and last_city != prev_city and hours_diff < 4.0:
                        impossible_travel_flag = True
            else:
                # Fallback: if we don't have coords, use old city-name heuristic
                hours_diff = abs((last_ts - prev_ts).total_seconds()) / 3600.0
                if last_city and prev_city and last_city != prev_city and hours_diff < 4.0:
                    impossible_travel_flag = True

    return {
        "avg_amount_30d": avg_amount_30d,
        "avg_amount_7d": avg_amount_7d,
        "max_amount_30d": max_amount_30d,
        "max_amount_7d": max_amount_7d,
        "txn_count_30d": txn_count_30d,
        "txn_count_24h": txn_count_24h,
        "txn_count_1hour": txn_count_1h,
        "txn_count_5min": txn_count_5min,
        "night_txn_ratio": night_txn_ratio,
        "failed_txn_count_7d": failed_txn_count_7d,
        "days_since_last_txn": days_since_last_txn,
        "receiver_map": receiver_map,
        "frequent_hours": frequent_hours,
        "last_city": last_city,
        "impossible_travel_flag": impossible_travel_flag,
        "history_count": len(txns)
    }


def get_receiver_summary_for_user(sender_upi: str, receiver_upi: str) -> Dict:
    """Return basic receiver summary from the sender's history."""
    txns = get_user_history(sender_upi, limit=1000)
    recs = [t for t in txns if (t.get('receiver_upi') == receiver_upi) or (t.get('receiver') == receiver_upi)]
    if not recs:
        return {
            "is_new": True,
            "total_transactions": 0,
            "avg_amount": 0.0,
            "reputation_score": 0.1,
            "risky_history": False,
            "good_history": False,
            "avg_risk_score": 0.0,
            "last_impossible_travel": None
        }

    amounts = [t['amount'] for t in recs]
    success_count = len([t for t in recs if t['status'] in ('SUCCESS', 'COMPLETED')])
    reputation = success_count / len(recs)

    # Risk signals from receiver history
    failed_count = len([t for t in recs if t.get('status') == 'FAILED'])
    blocked_count = len([t for t in recs if t.get('status') == 'BLOCKED'])
    # avg_risk_score: simple proxy = failed_count / total
    avg_risk = failed_count / len(recs)

    # risky_history: heuristic
    is_risky = (failed_count >= 2) or (blocked_count > 0) or (avg_risk > 0.3)
    # good_history: heuristic
    is_good = (reputation >= 0.9 and len(recs) >= 3 and failed_count == 0)

    # last_impossible_travel: if CSV contains ip_city, detect recent city mismatch for this receiver
    last_impossible = None
    try:
        # sort recs by timestamp desc
        recs_sorted = sorted(recs, key=lambda x: x['timestamp'], reverse=True)
        for i in range(len(recs_sorted) - 1):
            curr = recs_sorted[i]
            prev = recs_sorted[i+1]
            curr_city = curr.get('ip_city') or curr.get('city')
            prev_city = prev.get('ip_city') or prev.get('city')
            if curr_city and prev_city and curr_city != prev_city:
                hours_diff = abs((curr['timestamp'] - prev['timestamp']).total_seconds()) / 3600.0
                if hours_diff < 4.0:
                    last_impossible = curr['timestamp'].isoformat()
                    break
    except Exception:
        last_impossible = None

    return {
        "is_new": False,
        "total_transactions": len(recs),
        "avg_amount": sum(amounts)/len(amounts),
        "reputation_score": reputation,
        "risky_history": is_risky,
        "good_history": is_good,
        "avg_risk_score": round(avg_risk, 3),
        "last_impossible_travel": last_impossible
    }
