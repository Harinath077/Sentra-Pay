"""
Payment Schemas - Request/Response models for payment APIs.
"""

from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict
from datetime import datetime


class PaymentIntentRequest(BaseModel):
    """
    Request to analyze payment before execution.
    """
    amount: float = Field(..., gt=0, description="Transaction amount in smallest currency unit (paise)")
    receiver: str = Field(..., min_length=3, description="Receiver UPI ID or identifier")
    note: Optional[str] = Field(None, max_length=500, description="Transaction note/description")
    device_id: Optional[str] = Field(None, description="Device fingerprint/identifier")
    
    @validator('amount')
    def validate_amount(cls, v):
        if v <= 0:
            raise ValueError('Amount must be positive')
        if v > 100000000:  # 10 crore limit
            raise ValueError('Amount exceeds maximum transaction limit')
        return v
    
    class Config:
        json_schema_extra = {
            "example": {
                "amount": 9000000,
                "receiver": "SriRam@upi",
                "note": "Payment for property",
                "device_id": "device-abc-123"
            }
        }


class RiskBreakdown(BaseModel):
    """
    Risk breakdown by analysis category.
    """
    behavior_analysis: Dict = Field(..., description="Behavior pattern analysis")
    amount_analysis: Dict = Field(..., description="Amount deviation analysis")
    receiver_analysis: Dict = Field(..., description="Receiver reputation analysis")


class RiskFactor(BaseModel):
    """
    Individual risk factor.
    """
    factor: str
    severity: str  # low, medium, high, critical
    detail: Optional[str] = None


class ReceiverInfo(BaseModel):
    """
    Receiver information.
    """
    identifier: str
    is_new: bool
    reputation_score: float
    total_transactions: int


class UserInfo(BaseModel):
    """
    User information in risk response.
    """
    trust_score: float
    risk_tier: str
    transaction_count_30d: int


class PaymentIntentResponse(BaseModel):
    """
    Response from payment intent analysis.
    """
    transaction_id: str
    timestamp: str
    
    # Risk scoring
    risk_score: float = Field(..., ge=0.0, le=1.0)
    risk_level: str  # LOW, MODERATE, HIGH, VERY_HIGH
    risk_percentage: int = Field(..., ge=0, le=100)
    
    # Action determination
    action: str  # ALLOW, WARNING, OTP_REQUIRED, BLOCK
    message: str
    can_proceed: bool
    requires_otp: bool
    
    # New UI Fields for Frontend Rendering
    icon: Optional[str] = None
    color: Optional[str] = None
    background: Optional[str] = None
    label: Optional[str] = None
    
    # Risk analysis
    risk_breakdown: RiskBreakdown
    risk_factors: List[RiskFactor]
    recommendations: List[str]
    
    # Additional info
    transaction_details: Dict
    user_info: UserInfo
    receiver_info: ReceiverInfo
    
    # Debug info (optional)
    debug: Optional[Dict] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "transaction_id": "TXN-20260203-A1B2C3D4",
                "timestamp": "2026-02-03T10:30:00Z",
                "risk_score": 0.55,
                "risk_level": "MODERATE",
                "risk_percentage": 55,
                "action": "WARNING",
                "message": "⚠️ Warning: This is a high amount to a new receiver.",
                "can_proceed": True,
                "requires_otp": False,
                "risk_breakdown": {
                    "behavior_analysis": {"score": 30, "weight": 30},
                    "amount_analysis": {"score": 100, "weight": 30},
                    "receiver_analysis": {"score": 40, "weight": 40}
                },
                "risk_factors": [
                    {"factor": "High amount to new receiver", "severity": "high"}
                ],
                "recommendations": ["Verify receiver details carefully"],
                "transaction_details": {"amount": 9000000, "receiver": "SriRam@upi"},
                "user_info": {"trust_score": 25.0, "risk_tier": "BRONZE", "transaction_count_30d": 5},
                "receiver_info": {"identifier": "SriRam@upi", "is_new": True, "reputation_score": 0.5, "total_transactions": 0}
            }
        }


class PaymentConfirmRequest(BaseModel):
    """
    Request to confirm and execute payment.
    """
    transaction_id: str = Field(..., description="Transaction ID from payment intent")
    user_acknowledged: bool = Field(..., description="User acknowledged the risk")
    otp: Optional[str] = Field(None, min_length=6, max_length=6, description="OTP for verification")
    
    # For prototype simplicity, pass details here to persist them
    amount: Optional[float] = None
    receiver: Optional[str] = None
    device_id: Optional[str] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "transaction_id": "TXN-20260203-A1B2C3D4",
                "user_acknowledged": True,
                "otp": "123456"
            }
        }


class PaymentConfirmResponse(BaseModel):
    """
    Response from payment confirmation.
    """
    transaction_id: str
    status: str  # pending, success, failed, blocked, cancelled
    message: str
    timestamp: str
    amount: Optional[float] = None
    receiver: Optional[str] = None
    
    # Payment completion details (present on success)
    utr_number: Optional[str] = Field(None, description="Unique Transaction Reference (12 digits)")
    psp_name: Optional[str] = Field(None, description="Payment Service Provider (GPay, PhonePe, etc.)")
    error_code: Optional[str] = Field(None, description="Error code if payment failed")
    upi_link: Optional[str] = Field(None, description="UPI deep link for mobile PSP app integration")
    
    class Config:
        json_schema_extra = {
            "example": {
                "transaction_id": "TXN20260210123456",
                "status": "success",
                "message": "Payment completed successfully",
                "timestamp": "2026-02-10T10:35:00.000Z",
                "amount": 5000.0,
                "receiver": "sachin@paytm",
                "utr_number": "402912345678",
                "psp_name": "Google Pay"
            }
        }

