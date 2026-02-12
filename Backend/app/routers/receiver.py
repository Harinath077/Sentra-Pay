from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict
from app.services.mock_upi_service import mock_upi_service

router = APIRouter(prefix="/api/receiver", tags=["receiver"])


class ReceiverValidationResponse(BaseModel):
    """Response model for receiver validation"""
    status: str
    vpa: str
    name: Optional[str] = None
    bank: Optional[str] = None
    verified: bool
    reputation_score: Optional[float] = 0.5
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
