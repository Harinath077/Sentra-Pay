#!/usr/bin/env python3
"""
Quick Start Script for Sentra Pay Backend
Automates the complete setup process
"""

import subprocess
import sys
import os
import time

def run_command(cmd, description, check=True):
    """Run a command and display status"""
    print(f"\n{'='*60}")
    print(f"🔄 {description}")
    print(f"{'='*60}")
    
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=check,
            capture_output=False,
            text=True
        )
        print(f"✅ {description} - COMPLETE")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} - FAILED")
        if check:
            sys.exit(1)
        return False


def main():
    """Main setup orchestration"""
    
    print("""
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🚀 SENTRA PAY BACKEND - QUICK START                    ║
║   PostgreSQL + FastAPI + Redis                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
    """)
    
    # Step 1: Start Docker containers
    run_command(
        "docker-compose -f docker-compose-postgres.yml up -d",
        "Starting PostgreSQL + Redis containers"
    )
    
    # Wait for PostgreSQL to be ready
    print("\n⏳ Waiting for PostgreSQL to be ready...")
    time.sleep(5)
    
    # Step 2: Test database connection
    run_command(
        'python -c "from app.database.connection import test_db_connection; test_db_connection()"',
        "Testing database connection"
    )
    
    # Step 3: Initialize database tables
    run_command(
        'python -c "from app.database.connection import init_db; init_db()"',
        "Creating database tables"
    )
    
    # Step 4: Create sample data (optional)
    create_sample = input("\n📊 Create sample data for testing? (y/n): ").lower()
    if create_sample == 'y':
        run_command(
            "python scripts/setup_database.py --action sample",
            "Creating sample data"
        )
    
    # Step 5: Start the backend server
    print(f"\n{'='*60}")
    print("✅ Setup complete! You can now start the backend server:")
    print(f"{'='*60}\n")
    print("   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000")
    print()
    print("📊 Database URLs:")
    print("   PostgreSQL: postgresql://postgres:sentra_secure_2026@localhost:5432/fraud_detection")
    print("   Redis:      redis://localhost:6379/0")
    print()
    print("🌐 API Docs (after starting server):")
    print("   http://localhost:8000/docs")
    print()
    
    # Option to start server now
    start_server = input("🚀 Start the backend server now? (y/n): ").lower()
    if start_server == 'y':
        print("\n🚀 Starting FastAPI server...")
        print("   Press Ctrl+C to stop\n")
        subprocess.run(
            "uvicorn app.main:app --reload --host 0.0.0.0 --port 8000",
            shell=True
        )


if __name__ == "__main__":
    main()
