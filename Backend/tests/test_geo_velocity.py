"""
Test Suite for Geo-Velocity Fraud Detection Module
Run this to verify the implementation works correctly.
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from datetime import datetime, timedelta
from app.utils.geo_velocity import geo_velocity_check, haversine_distance


def test_haversine_formula():
    """Test Haversine distance calculation accuracy."""
    print("\n" + "=" * 60)
    print("TEST SUITE 1: Haversine Distance Calculation")
    print("=" * 60)
    
    # Test 1: Chennai to Bangalore
    print("\nTest 1.1: Chennai → Bangalore")
    dist = haversine_distance(13.0827, 80.2707, 12.9716, 77.5946)
    print(f"  Calculated: {dist:.2f} km")
    print(f"  Expected: ~290 km")
    print(f"  ✓ PASS" if 280 < dist < 300 else "  ✗ FAIL")
    
    # Test 2: Delhi to Mumbai
    print("\nTest 1.2: Delhi → Mumbai")
    dist = haversine_distance(28.6139, 77.2090, 19.0760, 72.8777)
    print(f"  Calculated: {dist:.2f} km")
    print(f"  Expected: ~1150 km")
    print(f"  ✓ PASS" if 1100 < dist < 1200 else "  ✗ FAIL")
    
    # Test 3: Same location
    print("\nTest 1.3: Same Location (Chennai)")
    dist = haversine_distance(13.0827, 80.2707, 13.0827, 80.2707)
    print(f"  Calculated: {dist:.2f} km")
    print(f"  Expected: 0 km")
    print(f"  ✓ PASS" if dist < 0.01 else "  ✗ FAIL")


def test_normal_scenarios():
    """Test normal travel patterns."""
    print("\n" + "=" * 60)
    print("TEST SUITE 2: Normal Travel Scenarios")
    print("=" * 60)
    
    # Test 1: Local travel (within city)
    print("\nTest 2.1: Local Travel (Within Chennai)")
    prev = {
        "lat": 13.0827,
        "lon": 80.2707,
        "timestamp": datetime(2024, 1, 1, 10, 0)
    }
    curr = {
        "lat": 13.0600,
        "lon": 80.2500,
        "timestamp": datetime(2024, 1, 1, 10, 15)
    }
    result = geo_velocity_check(prev, curr)
    print(f"  Distance: {result['distance_km']} km")
    print(f"  Time: {result['time_hours']} hours")
    print(f"  Speed: {result['speed_kmh']} km/h")
    print(f"  Risk: {result['risk_score']} ({result['flag']})")
    print(f"  ✓ PASS" if result['risk_score'] == 0.0 else "  ✗ FAIL")
    
    # Test 2: Car travel (Chennai to Bangalore)
    print("\nTest 2.2: Car Travel (Chennai → Bangalore)")
    prev = {
        "lat": 13.0827,
        "lon": 80.2707,
        "timestamp": datetime(2024, 1, 1, 10, 0)
    }
    curr = {
        "lat": 12.9716,
        "lon": 77.5946,
        "timestamp": datetime(2024, 1, 1, 16, 0)
    }
    result = geo_velocity_check(prev, curr)
    print(f"  Distance: {result['distance_km']} km")
    print(f"  Time: {result['time_hours']} hours")
    print(f"  Speed: {result['speed_kmh']} km/h")
    print(f"  Risk: {result['risk_score']} ({result['flag']})")
    print(f"  ✓ PASS" if result['risk_score'] == 0.0 else "  ✗ FAIL")


def test_suspicious_scenarios():
    """Test suspicious but possible patterns."""
    print("\n" + "=" * 60)
    print("TEST SUITE 3: Suspicious Travel Scenarios")
    print("=" * 60)
    
    # Test 1: Flight travel (Mumbai to Kolkata)
    print("\nTest 3.1: Flight Travel (Mumbai → Kolkata)")
    prev = {
        "lat": 19.0760,
        "lon": 72.8777,
        "timestamp": datetime(2024, 1, 1, 10, 0)
    }
    curr = {
        "lat": 22.5726,
        "lon": 88.3639,
        "timestamp": datetime(2024, 1, 1, 13, 30)
    }
    result = geo_velocity_check(prev, curr)
    print(f"  Distance: {result['distance_km']} km")
    print(f"  Time: {result['time_hours']} hours")
    print(f"  Speed: {result['speed_kmh']} km/h")
    print(f"  Risk: {result['risk_score']} ({result['flag']})")
    print(f"  ✓ PASS" if result['risk_score'] == 0.20 else "  ✗ FAIL")


def test_fraud_scenarios():
    """Test impossible travel (fraud indicators)."""
    print("\n" + "=" * 60)
    print("TEST SUITE 4: Fraud/Impossible Travel Scenarios")
    print("=" * 60)
    
    # Test 1: Supersonic speed (Delhi to Mumbai in 1 hour)
    print("\nTest 4.1: Supersonic Travel (Delhi → Mumbai in 1 hour)")
    prev = {
        "lat": 28.6139,
        "lon": 77.2090,
        "timestamp": datetime(2024, 1, 1, 10, 0)
    }
    curr = {
        "lat": 19.0760,
        "lon": 72.8777,
        "timestamp": datetime(2024, 1, 1, 11, 0)
    }
    result = geo_velocity_check(prev, curr)
    print(f"  Distance: {result['distance_km']} km")
    print(f"  Time: {result['time_hours']} hours")
    print(f"  Speed: {result['speed_kmh']} km/h")
    print(f"  Risk: {result['risk_score']} ({result['flag']})")
    print(f"  ✓ PASS" if result['risk_score'] == 0.40 else "  ✗ FAIL")
    
    # Test 2: Simultaneous transactions (same timestamp, different cities)
    print("\nTest 4.2: Simultaneous Transactions (Chennai & Delhi)")
    prev = {
        "lat": 13.0827,
        "lon": 80.2707,
        "timestamp": datetime(2024, 1, 1, 10, 0, 0)
    }
    curr = {
        "lat": 28.6139,
        "lon": 77.2090,
        "timestamp": datetime(2024, 1, 1, 10, 0, 0)  # Same time!
    }
    result = geo_velocity_check(prev, curr)
    print(f"  Distance: {result['distance_km']} km")
    print(f"  Time: {result['time_hours']} hours")
    print(f"  Speed: {result['speed_kmh']} km/h")
    print(f"  Risk: {result['risk_score']} ({result['flag']})")
    print(f"  ✓ PASS" if result['risk_score'] == 0.50 else "  ✗ FAIL")
    
    # Test 3: Teleportation (Chennai to Bangalore in 2 minutes)
    print("\nTest 4.3: Teleportation (Chennai → Bangalore in 2 mins)")
    prev = {
        "lat": 13.0827,
        "lon": 80.2707,
        "timestamp": datetime(2024, 1, 1, 10, 0)
    }
    curr = {
        "lat": 12.9716,
        "lon": 77.5946,
        "timestamp": datetime(2024, 1, 1, 10, 2)
    }
    result = geo_velocity_check(prev, curr)
    print(f"  Distance: {result['distance_km']} km")
    print(f"  Time: {result['time_hours']} hours")
    print(f"  Speed: {result['speed_kmh']} km/h")
    print(f"  Risk: {result['risk_score']} ({result['flag']})")
    print(f"  ✓ PASS" if result['risk_score'] == 0.40 else "  ✗ FAIL")


def test_edge_cases():
    """Test edge cases."""
    print("\n" + "=" * 60)
    print("TEST SUITE 5: Edge Cases")
    print("=" * 60)
    
    # Test 1: Same location, different time
    print("\nTest 5.1: Same Location, Different Time")
    prev = {
        "lat": 13.0827,
        "lon": 80.2707,
        "timestamp": datetime(2024, 1, 1, 10, 0)
    }
    curr = {
        "lat": 13.0827,
        "lon": 80.2707,
        "timestamp": datetime(2024, 1, 1, 14, 0)
    }
    result = geo_velocity_check(prev, curr)
    print(f"  Distance: {result['distance_km']} km")
    print(f"  Speed: {result['speed_kmh']} km/h")
    print(f"  Risk: {result['risk_score']} ({result['flag']})")
    print(f"  ✓ PASS" if result['risk_score'] == 0.0 else "  ✗ FAIL")
    
    # Test 2: Very small distance (100m walk)
    print("\nTest 5.2: Very Small Distance (100m walk)")
    prev = {
        "lat": 13.0827,
        "lon": 80.2707,
        "timestamp": datetime(2024, 1, 1, 10, 0)
    }
    curr = {
        "lat": 13.0830,  # ~33m north
        "lon": 80.2707,
        "timestamp": datetime(2024, 1, 1, 10, 5)
    }
    result = geo_velocity_check(prev, curr)
    print(f"  Distance: {result['distance_km']} km")
    print(f"  Speed: {result['speed_kmh']} km/h")
    print(f"  Risk: {result['risk_score']} ({result['flag']})")
    print(f"  ✓ PASS" if result['risk_score'] == 0.0 else "  ✗ FAIL")


def run_all_tests():
    """Run all test suites."""
    print("\n" + "=" * 60)
    print("GEO-VELOCITY FRAUD DETECTION - TEST SUITE")
    print("=" * 60)
    
    test_haversine_formula()
    test_normal_scenarios()
    test_suspicious_scenarios()
    test_fraud_scenarios()
    test_edge_cases()
    
    print("\n" + "=" * 60)
    print("TEST SUITE COMPLETE")
    print("=" * 60)
    print("\n✓ All tests completed!")
    print("\nNext steps:")
    print("1. Run database migration: python migrations/add_location_fields.py")
    print("2. Update Flutter app to send GPS coordinates")
    print("3. Restart backend server")
    print("4. Test with real transactions\n")


if __name__ == "__main__":
    run_all_tests()
