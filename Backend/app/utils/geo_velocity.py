"""
Geo-Velocity Fraud Detection Module
Detects impossible travel patterns between consecutive transactions.
"""

from datetime import datetime
from typing import Dict
import math
import logging

logger = logging.getLogger(__name__)


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points on Earth.
    
    Uses the Haversine formula:
    a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
    c = 2 ⋅ atan2(√a, √(1−a))
    d = R ⋅ c
    
    Args:
        lat1: Latitude of point 1 in decimal degrees
        lon1: Longitude of point 1 in decimal degrees
        lat2: Latitude of point 2 in decimal degrees
        lon2: Longitude of point 2 in decimal degrees
    
    Returns:
        Distance in kilometers
    
    Example:
        >>> haversine_distance(13.0827, 80.2707, 12.9716, 77.5946)
        290.17  # Chennai to Bangalore ~290 km
    """
    # Earth's radius in kilometers
    R = 6371.0
    
    # Convert latitude and longitude from degrees to radians
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)
    
    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    a = math.sin(dlat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    distance = R * c
    
    return distance


def geo_velocity_check(previous_txn: dict, current_txn: dict) -> dict:
    """
    Check for impossible travel between two transactions.
    
    Args:
        previous_txn: Dictionary with 'lat', 'lon', 'timestamp'
        current_txn: Dictionary with 'lat', 'lon', 'timestamp'
    
    Returns:
        Dictionary with distance, time, speed, risk_score, and flag
    
    Example:
        >>> prev = {"lat": 13.0827, "lon": 80.2707, "timestamp": datetime(2024, 1, 1, 10, 0)}
        >>> curr = {"lat": 28.6139, "lon": 77.2090, "timestamp": datetime(2024, 1, 1, 11, 0)}
        >>> result = geo_velocity_check(prev, curr)
        >>> result["flag"]
        'IMPOSSIBLE_TRAVEL'  # Delhi-Chennai in 1 hour = 1755 km/h
    """
    
    # Extract coordinates
    prev_lat = previous_txn["lat"]
    prev_lon = previous_txn["lon"]
    curr_lat = current_txn["lat"]
    curr_lon = current_txn["lon"]
    
    # Extract timestamps
    prev_time = previous_txn["timestamp"]
    curr_time = current_txn["timestamp"]
    
    # Calculate distance using Haversine formula
    distance_km = haversine_distance(prev_lat, prev_lon, curr_lat, curr_lon)
    
    # Calculate time difference in hours
    time_diff = curr_time - prev_time
    time_hours = time_diff.total_seconds() / 3600.0
    
    # Calculate speed (km/h)
    if time_hours > 0:
        speed_kmh = distance_km / time_hours
    else:
        # Same timestamp - impossible if different locations
        speed_kmh = float('inf')
    
    # Apply risk rules
    if time_hours == 0.0 and distance_km > 0.1:
        # Same timestamp but different location (>100m apart)
        risk_score = 0.50
        flag = "IMPOSSIBLE_TRAVEL"
        details = f"Simultaneous transactions {distance_km:.1f} km apart"
        logger.warning(f"⚠️ IMPOSSIBLE_TRAVEL: Same timestamp, {distance_km:.1f} km apart")
        
    # Explicit impossible travel: very long distance in short time
    elif distance_km > 800 and time_hours < 1.0:
        # e.g., >800 km within 1 hour => high risk
        risk_score = 0.35
        flag = "IMPOSSIBLE_TRAVEL"
        details = f"Long-distance rapid travel: {distance_km:.0f} km in {time_hours:.2f} hrs"
        logger.warning(f"⚠️ IMPOSSIBLE_TRAVEL: {distance_km:.0f} km in {time_hours:.2f} hrs")

    elif speed_kmh > 900:
        # Supersonic speed (impossible for ground/air travel)
        risk_score = 0.40
        flag = "IMPOSSIBLE_TRAVEL"
        details = f"Supersonic speed: {speed_kmh:.0f} km/h ({distance_km:.0f} km in {time_hours:.1f} hrs)"
        logger.warning(f"⚠️ HIGH_RISK_TRAVEL: {speed_kmh:.0f} km/h ({distance_km:.0f} km in {time_hours:.1f} hrs)")
        
    elif speed_kmh > 300:
        # High-speed travel (possible with flight, but suspicious)
        risk_score = 0.20
        flag = "SUSPICIOUS"
        details = f"High-speed travel: {speed_kmh:.0f} km/h (flight?)"
        logger.info(f"ℹ️ SUSPICIOUS_TRAVEL: {speed_kmh:.0f} km/h")
        
    else:
        # Normal travel speed
        risk_score = 0.0
        flag = "NORMAL"
        details = f"Normal travel: {speed_kmh:.1f} km/h"
    
    return {
        "distance_km": round(distance_km, 2),
        "time_hours": round(time_hours, 4),
        "speed_kmh": round(speed_kmh, 2) if speed_kmh != float('inf') else float('inf'),
        "risk_score": risk_score,
        "flag": flag,
        "details": details
    }
