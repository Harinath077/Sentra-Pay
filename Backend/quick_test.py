"""
Quick synchronous test - shows all test cases
"""
import subprocess
import time
import sys

print("="*70)
print("  FRAUD DETECTION BACKEND - ALL TEST CASES")
print("="*70)

# Start server
print("\n1. Starting server...")
server = subprocess.Popen(
    [sys.executable, "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000"],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE
)

# Wait for server
print("2. Waiting for server to be ready...")
time.sleep(3)

# Run tests
print("3. Running all test cases...\n")
subprocess.run([sys.executable, "show_tests.py"])

# Cleanup
print("\n\n4. Stopping server...")
server.terminate()
server.wait()

print("Done!")
