from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, Dict
from sqlalchemy.orm import Session
from datetime import datetime

from app.services.mock_upi_service import mock_upi_service
from app.database.connection import get_db
from app.database.models import ReceiverReputation
from app.database.redis_client import redis_client

router = APIRouter(prefix="/api/receiver", tags=["receiver"])


class ReceiverValidationResponse(BaseModel):
    """Response model for receiver validation"""
    status: str
    vpa: str
    name: Optional[str] = None
    bank: Optional[str] = None
    verified: bool
    reputation_score: Optional[float] = 0.5
    
    # 🔥 New Behavioral Risk Fields
    risk_score: Optional[int] = 0
    risk_level: Optional[str] = "Low"
    risk_factors: Optional[list] = []
    micro_tip: Optional[str] = None
    
    # New UI Fields
    icon: Optional[str] = None
    color: Optional[str] = None
    background: Optional[str] = None
    label: Optional[str] = None
    can_proceed: Optional[bool] = True
    action: Optional[str] = None
    message: Optional[str] = None
    warning: Optional[str] = None
    recommendation: Optional[str] = None
    
    metadata: Dict = {}
    error: Optional[str] = None


@router.get("/validate/{vpa}", response_model=ReceiverValidationResponse)
async def validate_receiver(vpa: str):
    """
    Validate UPI VPA and return receiver details
    
    **Demo UPI IDs you can try:**
    - `sachin@paytm` - Famous cricket player
    - `swiggy@paytm` - Food delivery merchant
    - `scammer@paytm` - Suspicious account
    - `invalid@test` - Unknown receiver
    
    **Example:**
```
    GET /api/receiver/validate/sachin@paytm
```
    
    **Response:**
```json
    {
      "status": "success",
      "vpa": "sachin@paytm",
      "name": "Sachin Ramesh Tendulkar",
      "bank": "Paytm Payments Bank",
      "verified": true,
      "reputation_score": 0.95
    }
```
    """
    
    # Call mock UPI service
    result = await mock_upi_service.validate_vpa(vpa)
    
    return result


@router.post("/add-test-user")
async def add_test_user(
    vpa: str,
    name: str,
    bank: str = "Test Bank",
    reputation_score: float = 0.5
):
    """
    Add a test user during demo (useful for judges)
    
    **Example:**
```
    POST /api/receiver/add-test-user
    {
      "vpa": "judge@sbi",
      "name": "Hackathon Judge",
      "bank": "State Bank of India",
      "reputation_score": 0.9
    }
```
    """
    message = mock_upi_service.add_test_user(
        vpa=vpa,
        name=name,
        bank=bank,
        reputation_score=reputation_score
    )
    
    return {"message": message}


class ReportRequest(BaseModel):
    vpa: str
    reason: Optional[str] = "Fraud"


@router.post("/report")
async def report_receiver(report: ReportRequest, db: Session = Depends(get_db)):
    """
    Report a receiver as fraudulent.
    Updates reputation score and invalidates cache.
    """
    receiver = db.query(ReceiverReputation).filter(
        ReceiverReputation.receiver == report.vpa
    ).first()
    
    if receiver:
        receiver.fraud_count += 1
        receiver.last_updated = datetime.utcnow()
    else:
        receiver = ReceiverReputation(
            receiver=report.vpa,
            total_transactions=1,
            fraud_count=1,
            last_updated=datetime.utcnow()
        )
        db.add(receiver)
    
    db.commit()
    
    # Invalidate Cache (Crucial for instant update)
    redis_key = f"receiver_reputation:{report.vpa}"
    redis_client.delete(redis_key)
    
    return {
        "status": "success",
        "message": f"Receiver reported. Analytics updated.",
        "fraud_count": receiver.fraud_count
    }
