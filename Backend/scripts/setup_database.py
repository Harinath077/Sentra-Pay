"""
Database Setup and Migration Utility for Sentra Pay
Handles PostgreSQL database initialization and data migration
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.orm import Session
from app.database.connection import SessionLocal, init_db, test_db_connection, engine
from app.database.models import User, Transaction, RiskEvent, ReceiverReputation, QRScan
from app.utils.security import hash_password
from datetime import datetime, timedelta
import random
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def create_sample_data(db: Session):
    """Create sample data for testing"""
    logger.info("🔄 Creating sample data...")
    
    # Create sample users
    sample_users = [
        {
            "email": "alice@example.com",
            "phone": "+919876543210",
            "full_name": "Alice Smith",
            "password": "Test123!",
            "trust_score": 75.0,
            "risk_tier": "GOLD"
        },
        {
            "email": "bob@example.com",
            "phone": "+919876543211",
            "full_name": "Bob Johnson",
            "password": "Test123!",
            "trust_score": 50.0,
            "risk_tier": "SILVER"
        },
        {
            "email": "charlie@example.com",
            "phone": "+919876543212",
            "full_name": "Charlie Brown",
            "password": "Test123!",
            "trust_score": 25.0,
            "risk_tier": "BRONZE"
        }
    ]
    
    created_users = []
    for user_data in sample_users:
        # Check if user exists
        existing = db.query(User).filter(User.email == user_data["email"]).first()
        if existing:
            logger.info(f"  User {user_data['email']} already exists, skipping...")
            created_users.append(existing)
            continue
        
        # Create user
        user = User(
            email=user_data["email"],
            phone=user_data["phone"],
            full_name=user_data["full_name"],
            password_hash=hash_password(user_data["password"]),
            trust_score=user_data["trust_score"],
            risk_tier=user_data["risk_tier"],
            known_devices=["device_001", "device_002"]
        )
        db.add(user)
        created_users.append(user)
        logger.info(f"  ✓ Created user: {user.email}")
    
    db.commit()
    
    # Create sample transactions
    logger.info("🔄 Creating sample transactions...")
    receivers = [
        "merchant@paytm",
        "shop@phonepe",
        "store@gpay",
        "vendor@upi",
        "suspicious@upi"
    ]
    
    for i, user in enumerate(created_users):
        # Create 5-10 transactions per user
        num_txns = random.randint(5, 10)
        for j in range(num_txns):
            amount = round(random.uniform(100, 5000), 2)
            risk_score = random.uniform(0.1, 0.9)
            
            # Determine risk level
            if risk_score < 0.3:
                risk_level = "LOW"
                action = "ALLOW"
            elif risk_score < 0.6:
                risk_level = "MODERATE"
                action = "WARNING"
            elif risk_score < 0.8:
                risk_level = "HIGH"
                action = "OTP_REQUIRED"
            else:
                risk_level = "VERY_HIGH"
                action = "BLOCK"
            
            txn = Transaction(
                user_id=user.id,
                amount=amount,
                receiver=random.choice(receivers),
                note=f"Sample transaction {j+1}",
                risk_score=risk_score,
                risk_level=risk_level,
                ml_score=random.uniform(0, 1),
                rule_score=random.uniform(0, 1),
                action_taken=action,
                status="success" if action in ["ALLOW", "WARNING"] else "pending",
                payment_method="UPI",
                device_id=f"device_{random.randint(1, 3):03d}",
                created_at=datetime.utcnow() - timedelta(days=random.randint(0, 30))
            )
            db.add(txn)
    
    db.commit()
    logger.info(f"✓ Created sample transactions")
    
    # Create receiver reputations
    logger.info("🔄 Creating receiver reputations...")
    for receiver in receivers:
        existing_rep = db.query(ReceiverReputation).filter(
            ReceiverReputation.receiver == receiver
        ).first()
        
        if not existing_rep:
            is_suspicious = "suspicious" in receiver
            rep = ReceiverReputation(
                receiver=receiver,
                total_transactions=random.randint(10, 100),
                successful_transactions=random.randint(8, 95),
                fraud_count=random.randint(5, 20) if is_suspicious else random.randint(0, 2),
                chargeback_count=0,
                reputation_score=0.2 if is_suspicious else random.uniform(0.7, 1.0)
            )
            db.add(rep)
            logger.info(f"  ✓ Created reputation for: {receiver}")
    
    db.commit()
    logger.info("✅ Sample data creation complete!")


def migrate_from_sqlite():
    """
    Migrate data from SQLite to PostgreSQL
    (If you have existing SQLite database)
    """
    import sqlite3
    
    sqlite_path = "fraud_detection.db"
    if not os.path.exists(sqlite_path):
        logger.warning("No SQLite database found to migrate")
        return
    
    logger.info("🔄 Migrating from SQLite to PostgreSQL...")
    
    # Connect to SQLite
    sqlite_conn = sqlite3.connect(sqlite_path)
    sqlite_conn.row_factory = sqlite3.Row
    cursor = sqlite_conn.cursor()
    
    # Get PostgreSQL session
    db = SessionLocal()
    
    try:
        # Migrate users
        cursor.execute("SELECT * FROM users")
        users = cursor.fetchall()
        logger.info(f"Found {len(users)} users in SQLite")
        
        for row in users:
            user_dict = dict(row)
            existing = db.query(User).filter(User.email == user_dict.get('email')).first()
            if not existing:
                user = User(**{k: v for k, v in user_dict.items() if k != 'id'})
                db.add(user)
        
        db.commit()
        logger.info("✓ Users migrated")
        
        # Migrate transactions
        cursor.execute("SELECT * FROM transactions")
        transactions = cursor.fetchall()
        logger.info(f"Found {len(transactions)} transactions in SQLite")
        
        for row in transactions:
            txn_dict = dict(row)
            # Map user_id from SQLite to PostgreSQL
            # This requires matching email or user_id
            db.add(Transaction(**{k: v for k, v in txn_dict.items() if k != 'id'}))
        
        db.commit()
        logger.info("✓ Transactions migrated")
        
        logger.info("✅ Migration complete!")
        
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        db.rollback()
    finally:
        db.close()
        sqlite_conn.close()


def reset_database():
    """Drop all tables and recreate them"""
    logger.warning("⚠️  RESETTING DATABASE - All data will be lost!")
    
    from app.database.models import Base
    
    # Drop all tables
    Base.metadata.drop_all(bind=engine)
    logger.info("✓ All tables dropped")
    
    # Recreate tables
    Base.metadata.create_all(bind=engine)
    logger.info("✓ All tables recreated")


def main():
    """Main setup function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Database setup utility")
    parser.add_argument(
        "--action",
        choices=["init", "sample", "migrate", "reset", "test"],
        default="init",
        help="Action to perform"
    )
    
    args = parser.parse_args()
    
    if args.action == "test":
        logger.info("🔍 Testing database connection...")
        if test_db_connection():
            logger.info("✅ Database connection successful!")
        else:
            logger.error("❌ Database connection failed!")
            sys.exit(1)
    
    elif args.action == "init":
        logger.info("🚀 Initializing database...")
        init_db()
        logger.info("✅ Database initialized!")
    
    elif args.action == "sample":
        logger.info("🎲 Creating sample data...")
        db = SessionLocal()
        try:
            create_sample_data(db)
        finally:
            db.close()
    
    elif args.action == "migrate":
        logger.info("🔄 Migrating from SQLite...")
        migrate_from_sqlite()
    
    elif args.action == "reset":
        confirm = input("⚠️  Are you sure you want to reset the database? (yes/no): ")
        if confirm.lower() == "yes":
            reset_database()
            logger.info("✅ Database reset complete!")
        else:
            logger.info("Cancelled")


if __name__ == "__main__":
    main()
