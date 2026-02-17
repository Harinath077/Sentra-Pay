
import sqlite3
import os

db_path = "fraud_detection.db"
if not os.path.exists(db_path):
    print(f"Error: {db_path} not found")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get existing columns
cursor.execute("PRAGMA table_info(transactions)")
columns = [row[1] for row in cursor.fetchall()]
print(f"Existing columns in transactions: {columns}")

missing_columns = [
    ("payment_timestamp", "DATETIME"),
    ("utr_number", "VARCHAR(20)"),
    ("psp_name", "VARCHAR(50)"),
    ("payment_method", "VARCHAR(255)"),
    ("current_hash", "VARCHAR(64)"),
    ("previous_hash", "VARCHAR(64)"),
    ("completed_at", "DATETIME"),
    ("device_id", "VARCHAR(100)")
]

for col_name, col_type in missing_columns:
    if col_name not in columns:
        print(f"Adding column {col_name} to transactions...")
        try:
            cursor.execute(f"ALTER TABLE transactions ADD COLUMN {col_name} {col_type}")
        except Exception as e:
            print(f"Failed to add {col_name}: {e}")

# Check if receiver_history exists
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='receiver_history'")
if not cursor.fetchone():
    print("Creating receiver_history table...")
    # This is a simplification, models.Base.metadata.create_all() in main.py will do this if it doesn't exist.
    pass

conn.commit()
conn.close()
print("Database schema update attempt complete.")
