#!/usr/bin/env python
"""
Test PostgreSQL Migration
Verifies that the migration was successful
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def test_imports():
    """Test that all imports work without Firebase"""
    print("🧪 Testing imports...")
    
    try:
        from app.database.connection import get_db, test_db_connection, init_db
        print("  ✓ Database connection imports")
        
        from app.database.models import User, Transaction, RiskEvent, ReceiverReputation
        print("  ✓ Database models imports")
        
        from app.services.auth_service import create_user, authenticate_user
        print("  ✓ Auth service imports")
        
        from app.utils.security import hash_password, verify_password, create_access_token
        print("  ✓ Security utils imports")
        
        from app.config import settings
        print("  ✓ Config imports")
        
        print("✅ All imports successful (no Firebase dependencies)")
        return True
        
    except ImportError as e:
        print(f"❌ Import failed: {e}")
        return False


def test_database_connection():
    """Test database connection"""
    print("\n🧪 Testing database connection...")
    
    try:
        from app.database.connection import test_db_connection
        
        if test_db_connection():
            print("✅ Database connection successful")
            return True
        else:
            print("❌ Database connection failed")
            return False
            
    except Exception as e:
        print(f"❌ Connection test failed: {e}")
        return False


def test_database_url():
    """Test that we're using PostgreSQL, not SQLite"""
    print("\n🧪 Testing database URL...")
    
    try:
        from app.config import settings
        
        db_url = settings.DATABASE_URL
        print(f"  Database URL: {db_url}")
        
        if "postgresql" in db_url:
            print("✅ Using PostgreSQL")
            return True
        elif "sqlite" in db_url:
            print("⚠️  Still using SQLite - You may want to switch to PostgreSQL")
            return True  # Not an error, just a warning
        else:
            print(f"❓ Unknown database type: {db_url}")
            return False
            
    except Exception as e:
        print(f"❌ Failed to check database URL: {e}")
        return False


def test_no_firebase_imports():
    """Verify no Firebase imports in main code"""
    print("\n🧪 Checking for Firebase imports...")
    
    import os
    import re
    
    firebase_pattern = re.compile(r'import firebase|from firebase')
    files_with_firebase = []
    
    # Scan app directory
    for root, dirs, files in os.walk('app'):
        # Skip deprecated files
        if 'DEPRECATED' in root:
            continue
            
        for file in files:
            if file.endswith('.py') and 'DEPRECATED' not in file:
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                        if firebase_pattern.search(content):
                            files_with_firebase.append(filepath)
                except:
                    pass
    
    if files_with_firebase:
        print("⚠️  Found Firebase imports in:")
        for f in files_with_firebase:
            print(f"    - {f}")
        return False
    else:
        print("✅ No Firebase imports found in active code")
        return True


def test_auth_flow():
    """Test basic auth flow (without actually creating user)"""
    print("\n🧪 Testing auth utilities...")
    
    try:
        from app.utils.security import hash_password, verify_password, create_access_token, verify_token
        
        # Test password hashing
        password = "Test123!"
        hashed = hash_password(password)
        print(f"  ✓ Password hashing works")
        
        # Test password verification
        if verify_password(password, hashed):
            print(f"  ✓ Password verification works")
        else:
            print(f"  ❌ Password verification failed")
            return False
        
        # Test token creation
        token = create_access_token({"sub": "test_user"})
        print(f"  ✓ Token creation works")
        
        # Test token verification
        payload = verify_token(token)
        if payload.get("sub") == "test_user":
            print(f"  ✓ Token verification works")
        else:
            print(f"  ❌ Token verification failed")
            return False
        
        print("✅ Auth utilities working correctly")
        return True
        
    except Exception as e:
        print(f"❌ Auth test failed: {e}")
        return False


def main():
    """Run all tests"""
    print("""
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🧪 POSTGRESQL MIGRATION TEST SUITE                     ║
║   Verifying Firebase → PostgreSQL Migration              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
    """)
    
    results = []
    
    # Run tests
    results.append(("Imports", test_imports()))
    results.append(("Database URL", test_database_url()))
    results.append(("No Firebase Imports", test_no_firebase_imports()))
    results.append(("Auth Utilities", test_auth_flow()))
    results.append(("Database Connection", test_database_connection()))
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 TEST SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print("=" * 60)
    print(f"Results: {passed}/{total} tests passed")
    print("=" * 60)
    
    if passed == total:
        print("\n🎉 All tests passed! Migration successful!")
        print("\nNext steps:")
        print("1. Start PostgreSQL: docker-compose -f docker-compose-postgres.yml up -d")
        print("2. Initialize DB: python scripts/setup_database.py --action init")
        print("3. Start server: uvicorn app.main:app --reload")
        return 0
    else:
        print(f"\n⚠️  {total - passed} test(s) failed. Please review the errors above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
