"""
Database Migration: Add Location Fields for Geo-Velocity Detection
Adds latitude and longitude columns to transactions table.
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from sqlalchemy import text
from app.database.connection import engine
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def run_migration():
    """Add latitude and longitude columns to transactions table."""
    
    print("=" * 60)
    print("GEO-VELOCITY MIGRATION")
    print("=" * 60)
    print("\nThis will add location fields to the transactions table:")
    print("  - latitude (FLOAT)")
    print("  - longitude (FLOAT)")
    print("  - Index on (latitude, longitude)")
    print("\n⚠️  Make sure you have a database backup before proceeding!")
    
    response = input("\nContinue with migration? (yes/no): ")
    
    if response.lower() != 'yes':
        print("\n❌ Migration cancelled.")
        return
    
    print("\n🔄 Running migration...")
    
    try:
        with engine.connect() as conn:
            # Add latitude column
            logger.info("Adding latitude column...")
            conn.execute(text("""
                ALTER TABLE transactions 
                ADD COLUMN IF NOT EXISTS latitude FLOAT
            """))
            
            # Add longitude column
            logger.info("Adding longitude column...")
            conn.execute(text("""
                ALTER TABLE transactions 
                ADD COLUMN IF NOT EXISTS longitude FLOAT
            """))
            
            # Create index for faster location queries
            logger.info("Creating index on location fields...")
            conn.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_transactions_location 
                ON transactions (latitude, longitude)
                WHERE latitude IS NOT NULL AND longitude IS NOT NULL
            """))
            
            conn.commit()
        
        print("\n✅ Migration completed successfully!")
        print("\n📊 Next steps:")
        print("  1. Restart your backend server")
        print("  2. Update Flutter app to send GPS coordinates")
        print("  3. Test with: python tests/test_geo_velocity.py")
        
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        print(f"\n❌ Migration failed: {e}")
        print("\nTroubleshooting:")
        print("  - Make sure database is running")
        print("  - Check database connection settings")
        print("  - Verify you have ALTER TABLE permissions")
        sys.exit(1)


if __name__ == "__main__":
    run_migration()
