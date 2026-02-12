@echo off
echo Starting Fraud Detection Backend Server...
echo.
python -m uvicorn app.main:app --port 8000 --reload
