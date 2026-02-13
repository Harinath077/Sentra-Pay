"""
Payment Endpoints - Transaction intent and confirmation.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
import logging

from app.models.payment import (
    PaymentIntentRequest,
    PaymentIntentResponse,
    PaymentConfirmRequest,
    PaymentConfirmResponse
)
from pydantic import BaseModel

class QRScanRequest(BaseModel):
    qr_data: str
    amount: Optional[float] = None

from app.core.risk_orchestrator import orchestrator
from app.database.connection import get_db
from app.database.models import User, Transaction
from app.services.auth_service import get_current_user
from app.utils.security import verify_token
from app.utils.upi_qr_scanner import UPIReceiverValidator
from app.database.redis_client import redis_client

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/payment", tags=["Payment"])


def get_current_user_from_token(authorization: str = Header(...), db: Session = Depends(get_db)) -> User:
    """
    Dependency to extract current user from JWT token.
    
    Args:
        authorization: Authorization header with Bearer token
        db: Database session
    
    Returns:
        User object
    
    Raises:
        HTTPException: If token is invalid or user not found
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    token = authorization.replace("Bearer ", "")
    
    # DEMO MODE: Allow demo-token for testing
    if token == "demo-token":
        current_user = db.query(User).filter(User.email == "demo@sentra.app").first()
        if not current_user:
            # Create demo user if missing
            current_user = User(
                user_id=f"DEMO-{datetime.now().strftime('%Y%m%d%H%M%S')}",
                email="demo@sentra.app",
                phone="0000000000",
                password_hash="demo",
                full_name="Demo User",
                trust_score=0.5,
                risk_tier="BRONZE"
            )
            db.add(current_user)
            db.commit()
            db.refresh(current_user)
        return current_user
        
    return get_current_user(db, token)



@router.post("/intent", response_model=PaymentIntentResponse)
async def payment_intent(
    request: PaymentIntentRequest,
    db: Session = Depends(get_db),
    authorization: Optional[str] = Header(None)
):
    """
    Analyze transaction risk before payment execution.
    
    This endpoint:
    1. Receives payment intent from user
    2. Calls Risk Orchestrator for analysis
    3. Returns risk score, breakdown, and recommended action
    4. Does NOT execute payment - just analysis
    
    Args:
        request: Payment intent details
        db: Database session
        authorization: Optional JWT token
    
    Returns:
        PaymentIntentResponse with risk analysis
    
    Raises:
        422: If validation fails
    """
    # Try to get current user from token, or use demo user
    current_user = None
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "")
        try:
            current_user = get_current_user(db, token)
        except:
            pass
    
    # If no authenticated user, use a demo user for risk analysis
    if not current_user:
        # Find or create a demo user
        current_user = db.query(User).filter(User.email == "demo@sentra.app").first()
        if not current_user:
            current_user = User(
                user_id=f"DEMO-{datetime.now().strftime('%Y%m%d%H%M%S')}",
                email="demo@sentra.app",
                phone="0000000000",
                password_hash="demo",
                full_name="Demo User",
                trust_score=0.5,
                risk_tier="BRONZE"
            )
            db.add(current_user)
            db.commit()
            db.refresh(current_user)
    
    logger.info(f"Payment intent: User {current_user.user_id} - Amount ₹{request.amount/100:.2f} to {request.receiver}")
    
    # Prepare transaction data
    txn_data = {
        "amount": request.amount,
        "receiver": request.receiver,
        "note": request.note or "",
        "device_id": request.device_id or ""
    }
    
    # Call Risk Orchestrator (THE BRAIN)
    risk_analysis = orchestrator.analyze_transaction(
        txn_data=txn_data,
        user_id=current_user.user_id,
        db=db
    )
    
    logger.info(f"Risk analysis complete: {risk_analysis['action']} (score={risk_analysis['risk_score']})")
    
    # Return risk analysis
    return PaymentIntentResponse(**risk_analysis)



@router.post("/confirm", response_model=PaymentConfirmResponse)
async def payment_confirm(
    request: PaymentConfirmRequest,
    current_user: User = Depends(get_current_user_from_token),
    db: Session = Depends(get_db)
):
    """
    Confirm and execute payment after user reviews risk.
    
    Flow:
    1. User reviewed risk analysis from /payment/intent
    2. User clicked "Pay Now" button
    3. This endpoint initiates actual payment via mock UPI service
    4. Updates transaction in database
    5. Updates user trust score on success
    6. Returns payment status
    
    Args:
        request: Payment confirmation with transaction_id
        current_user: Authenticated user from JWT
        db: Database session
    
    Returns:
        PaymentConfirmResponse with payment result
    
    Raises:
        404: Transaction not found
        400: Transaction already processed or user cancelled
    """
    logger.info(f"Payment confirm: User {current_user.user_id} - TXN {request.transaction_id}")
    
    # Import mock payment service
    from app.services.mock_payment_service import mock_payment_service
    
    # Get transaction from database
    txn = db.query(Transaction).filter(
        Transaction.transaction_id == request.transaction_id,
        Transaction.user_id == current_user.id
    ).first()
    
    if not txn:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found or unauthorized"
        )
    
    # Check if already processed
    if txn.status not in ["pending", "PENDING"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Transaction already {txn.status}"
        )
    
    # Check if user confirmed (user can cancel)
    if not request.user_acknowledged:
        txn.status = "cancelled"
        txn.updated_at = datetime.utcnow()
        db.commit()
        
        logger.info(f"Payment cancelled by user: {request.transaction_id}")
        
        return PaymentConfirmResponse(
            transaction_id=request.transaction_id,
            status="cancelled",
            message="Payment cancelled by user",
            timestamp=datetime.utcnow().isoformat()
        )
    
    # Generate UPI deep link for mobile PSP app integration
    upi_link = mock_payment_service.generate_upi_deep_link(
        receiver_upi=txn.receiver,
        amount=float(txn.amount),
        receiver_name=txn.receiver.split('@')[0].title(),  # Extract name from UPI ID
        transaction_note=txn.note or "Payment",
        transaction_ref=request.transaction_id
    )
    
    logger.info(f"Generated UPI link: {upi_link}")
    
    try:
        # Initiate payment via mock UPI service
        # In production, this would:
        # - Generate UPI deep link
        # - Open user's PSP app (GPay, PhonePe, etc.)
        # - Wait for callback/webhook
        payment_result = await mock_payment_service.initiate_payment(
            amount=float(txn.amount),
            receiver_upi=txn.receiver,
            sender_upi=current_user.email,  # Use email as UPI ID for demo
            payer_name=current_user.full_name
        )
        
        # Update transaction based on payment result
        txn.status = "COMPLETED" if payment_result["status"] == "success" else payment_result["status"]
        txn.payment_timestamp = datetime.utcnow()
        txn.updated_at = datetime.utcnow()
        
        if payment_result["status"] == "success":
            txn.utr_number = payment_result.get("utr_number")
            txn.psp_name = payment_result.get("psp_name")
            txn.completed_at = datetime.utcnow()
            txn.payment_method = payment_result.get("payment_method", "UPI")
            
            logger.info(f"✅ Payment successful: {request.transaction_id} via {txn.psp_name}")
            
            # ─────────────────────────────────────────────────────────────
            # CRITICAL FLOW: Update Transaction Stats & Receiver History
            # ─────────────────────────────────────────────────────────────
            
            # 1. Update User Stats
            current_user.trust_score = min(1.0, (current_user.trust_score or 0.0) + 0.01)
            # Assuming these fields exist in User model, if not, they should be added
            # For now, we'll try to update them if they exist or skip
            if hasattr(current_user, 'transaction_count'):
                current_user.transaction_count = (current_user.transaction_count or 0) + 1
            # if hasattr(current_user, 'total_amount_sent'):
            #     current_user.total_amount_sent = (current_user.total_amount_sent or 0) + float(txn.amount) 
            
            # 2. Update Receiver History (First-Time Logic)
            from app.database.models import ReceiverHistory
            
            receiver_record = db.query(ReceiverHistory).filter(
                ReceiverHistory.user_id == current_user.id,
                ReceiverHistory.receiver_upi == txn.receiver
            ).first()
            
            if receiver_record:
                # Update existing record
                receiver_record.last_paid_at = datetime.utcnow()
                receiver_record.payment_count += 1
                receiver_record.total_amount = float(receiver_record.total_amount) + float(txn.amount)
            else:
                # Create new record (First Payment!)
                new_record = ReceiverHistory(
                    user_id=current_user.id,
                    receiver_upi=txn.receiver,
                    first_paid_at=datetime.utcnow(),
                    last_paid_at=datetime.utcnow(),
                    payment_count=1,
                    total_amount=float(txn.amount)
                )
                db.add(new_record)
            
            logger.debug(f"Updated receiver history for {txn.receiver}")

        else:
            logger.warning(f"❌ Payment failed: {request.transaction_id} - {payment_result['message']}")
        
        db.commit()
        db.refresh(txn)
        
        # Invalidate user cache
        try:
            redis_client.invalidate_user_profile(current_user.user_id)
        except Exception as e:
            logger.warning(f"Failed to invalidate cache: {e}")
        
        # Return response
        return PaymentConfirmResponse(
            transaction_id=txn.transaction_id,
            status=payment_result["status"],
            message=payment_result["message"],
            timestamp=payment_result["timestamp"],
            amount=float(txn.amount),
            receiver=txn.receiver,
            utr_number=payment_result.get("utr_number"),
            psp_name=payment_result.get("psp_name"),
            error_code=payment_result.get("error_code"),
            upi_link=upi_link  # UPI deep link for mobile
        )
    
    except Exception as e:
        db.rollback()
        logger.error(f"Payment processing error: {e}", exc_info=True)
        
        # Mark transaction as failed
        txn.status = "failed"
        txn.updated_at = datetime.utcnow()
        db.commit()
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Payment processing failed: {str(e)}"
        )


@router.get("/status/{transaction_id}")
async def get_payment_status(
    transaction_id: str,
    current_user: User = Depends(get_current_user_from_token),
    db: Session = Depends(get_db)
):
    """
    Get current status of a payment transaction.
    
    Useful for:
    - Checking if a pending payment completed
    - Retrieving payment details for receipts
    - Auditing transaction history
    
    Args:
        transaction_id: Unique transaction identifier
        current_user: Authenticated user
        db: Database session
    
    Returns:
        Transaction status and details
    
    Raises:
        404: Transaction not found or unauthorized
    """
    logger.info(f"Status check: {transaction_id} by user {current_user.user_id}")
    
    # Get transaction
    txn = db.query(Transaction).filter(
        Transaction.transaction_id == transaction_id,
        Transaction.user_id == current_user.id
    ).first()
    
    if not txn:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found or unauthorized"
        )
    
    return {
        "transaction_id": txn.transaction_id,
        "status": txn.status,
        "amount": float(txn.amount) if txn.amount else 0.0,
        "receiver": txn.receiver,
        "risk_score": txn.risk_score,
        "risk_level": txn.risk_level,
        "action_taken": txn.action_taken,
        "created_at": txn.created_at.isoformat() if txn.created_at else None,
        "payment_timestamp": txn.payment_timestamp.isoformat() if txn.payment_timestamp else None,
        "utr_number": txn.utr_number,
        "psp_name": txn.psp_name,
        "payment_method": txn.payment_method
    }


@router.get("/health")
async def health_check():
    """
    Health check endpoint for payment service.
    
    Returns:
        Status message
    """
    return {
        "status": "ok",
        "service": "payment",
        "timestamp": datetime.utcnow().isoformat()
    }


@router.post("/scan-qr")
async def scan_qr(
    request: QRScanRequest,
    db: Session = Depends(get_db)
):
    """
    Validate UPI QR code for fraud before payment.
    
    Args:
        request: Contains qr_data (and optional amount)
        db: Database session
    
    Returns:
        Risk assessment of the QR code
    """
    validator = UPIReceiverValidator(db)
    result = validator.validate_qr_transaction(request.qr_data, request.amount)
    return result


@router.get("/history", response_model=list)
async def get_history(
    current_user: User = Depends(get_current_user_from_token),
    db: Session = Depends(get_db),
    limit: int = 50
):
    """
    Get payment history for the current user.
    """
    from sqlalchemy import desc
    
    transactions = db.query(Transaction).filter(
        Transaction.user_id == current_user.id,
        Transaction.status.in_(["COMPLETED", "success"])
    ).order_by(desc(Transaction.created_at)).limit(limit).all()
    
    return [
        {
            "transaction_id": t.transaction_id,
            "receiver": t.receiver,
            "amount": float(t.amount),
            "status": t.status,
            "risk_score": t.risk_score,
            "timestamp": t.created_at.isoformat() if t.created_at else None,
            "risk_level": t.risk_level
        }
        for t in transactions
    ]

