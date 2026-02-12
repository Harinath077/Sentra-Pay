# 🚀 Quick Setup Script for Fraud Detection Backend

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Fraud Detection Backend Setup" -ForegroundColor Cyan
Write-Host "Phase 1: Foundation" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Python
Write-Host "Step 1: Checking Python..." -ForegroundColor Yellow
$pythonVersion = python --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Python not found. Please install Python 3.10+" -ForegroundColor Red
    exit 1
}

# Step 2: Create virtual environment (optional but recommended)
Write-Host ""
Write-Host "Step 2: Setting up virtual environment..." -ForegroundColor Yellow
if (-not (Test-Path "venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Gray
    python -m venv venv
    Write-Host "✓ Virtual environment created" -ForegroundColor Green
} else {
    Write-Host "✓ Virtual environment already exists" -ForegroundColor Green
}

# Step 3: Activate virtual environment instructions
Write-Host ""
Write-Host "Step 3: Virtual Environment" -ForegroundColor Yellow
Write-Host "To activate virtual environment, run:" -ForegroundColor Gray
Write-Host "  .\venv\Scripts\Activate" -ForegroundColor Cyan

# Step 4: Install dependencies
Write-Host ""
Write-Host "Step 4: Installing dependencies..." -ForegroundColor Yellow
Write-Host "Run this command:" -ForegroundColor Gray
Write-Host "  pip install -r requirements.txt" -ForegroundColor Cyan

# Step 5: Start services
Write-Host ""
Write-Host "Step 5: Start PostgreSQL and Redis" -ForegroundColor Yellow
Write-Host "Option A - Using Docker (Recommended):" -ForegroundColor Gray
Write-Host "  docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=fraud_detection postgres:14" -ForegroundColor Cyan
Write-Host "  docker run -d -p 6379:6379 redis:7" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option B - Using docker-compose:" -ForegroundColor Gray
Write-Host "  docker-compose up -d" -ForegroundColor Cyan

# Step 6: Test setup
Write-Host ""
Write-Host "Step 6: Test the setup" -ForegroundColor Yellow
Write-Host "Run the test script:" -ForegroundColor Gray
Write-Host "  python test_phase1.py" -ForegroundColor Cyan

# Summary
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Setup Commands Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "1. .\venv\Scripts\Activate" -ForegroundColor White
Write-Host "2. pip install -r requirements.txt" -ForegroundColor White
Write-Host "3. docker-compose up -d" -ForegroundColor White
Write-Host "4. python test_phase1.py" -ForegroundColor White
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
