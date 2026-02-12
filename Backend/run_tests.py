"""
Run server and tests together.
This script starts the server in a subprocess and runs the tests.
"""

import subprocess
import time
import sys
import requests

print("=" * 70)
print("  STARTING FRAUD DETECTION BACKEND SERVER")
print("=" * 70)

# Start the server in a subprocess
server_process = subprocess.Popen(
    [sys.executable, "-m", "uvicorn", "app.main:app", "--port", "8000"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1
)

# Wait for server to start
print("\nWaiting for server to start...")
for i in range(30):  # Wait up to 30 seconds
    try:
        response = requests.get("http://localhost:8000/health", timeout=1)
        if response.status_code == 200:
            print("✓ Server is ready!\n")
            break
    except:
        pass
    time.sleep(1)
    print(f"  Waiting... ({i+1}s)")
else:
    print("\n✗ Server failed to start in time")
    server_process.terminate()
    sys.exit(1)

# Run the tests
print("=" * 70)
print("  RUNNING TESTS")
print("=" * 70)
print()

try:
    test_process = subprocess.run(
        [sys.executable, "test_complete_flow.py"],
        check=False
    )
    exit_code = test_process.returncode
finally:
    # Stop the server
    print("\n" + "=" * 70)
    print("  STOPPING SERVER")
    print("=" * 70)
    server_process.terminate()
    server_process.wait(timeout=5)
    print("✓ Server stopped")

sys.exit(exit_code)
