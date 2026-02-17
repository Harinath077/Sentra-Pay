
from app.config import settings
import os

print(f"Loaded DATABASE_URL: {settings.DATABASE_URL}")
print(f"Environment Variable DATABASE_URL: {os.environ.get('DATABASE_URL')}")
