"""
Mock Payment Service for Hackathon Demo
Simulates UPI payment flow without requiring real payment gateway integration
"""

import asyncio
import random
from datetime import datetime
from typing import Dict
import logging

logger = logging.getLogger(__name__)


class MockPaymentService:
    """
    Simulates UPI payment flow for hackathon demo.
    
    In production, this would integrate with:
    - Razorpay/PayU for payment processing
    - UPI deep linking for PSP app integration
    - NPCI APIs for transaction verification
    """
    
    async def initiate_payment(
        self,
        amount: float,
        receiver_upi: str,
        sender_upi: str = "user@paytm",
        payer_name: str = "Demo User"
    ) -> Dict:
        """
        Simulate UPI payment initiation.
        
        In real app, this would:
        1. Create UPI deep link
        2. Open user's PSP app (GPay, PhonePe, etc.)
        3. User authenticates with PIN/biometric
        4. Return to app with payment status
        
        Args:
            amount: Payment amount in rupees
            receiver_upi: Receiver's UPI ID
            sender_upi: Sender's UPI ID
            payer_name: Name of the payer
        
        Returns:
            Dictionary with payment result
        """
        
        # Generate unique transaction ID (realistic format)
        txn_id = f"TXN{datetime.now().strftime('%Y%m%d%H%M%S')}{random.randint(1000, 9999)}"
        
        logger.info(f"Initiating payment: {txn_id} - ₹{amount} to {receiver_upi}")
        
        # Simulate realistic UPI processing time (1-2 seconds)
        await asyncio.sleep(random.uniform(1.0, 2.0))
        
        # Simulate success/failure (90% success rate for demo)
        success = random.random() < 0.90
        
        if success:
            # Generate realistic UTR (Unique Transaction Reference)
            utr = f"{random.randint(100000000000, 999999999999)}"
            
            # Randomly select PSP (Payment Service Provider)
            psp = random.choice([
                "Google Pay",
                "PhonePe", 
                "Paytm",
                "BHIM UPI",
                "Amazon Pay"
            ])
            
            logger.info(f"✅ Payment successful: {txn_id} via {psp}")
            
            return {
                "status": "success",
                "transaction_id": txn_id,
                "amount": amount,
                "receiver_upi": receiver_upi,
                "sender_upi": sender_upi,
                "timestamp": datetime.utcnow().isoformat(),
                "message": "Payment completed successfully",
                "utr_number": utr,
                "psp_name": psp,
                "payment_method": "UPI"
            }
        else:
            # Simulate different failure scenarios
            failure_reasons = [
                ("User cancelled payment", "USER_CANCELLED"),
                ("Insufficient balance", "INSUFFICIENT_FUNDS"),
                ("UPI PIN incorrect", "INVALID_PIN"),
                ("Transaction timeout", "TIMEOUT"),
                ("Bank server unavailable", "BANK_ERROR"),
                ("Daily transaction limit exceeded", "LIMIT_EXCEEDED"),
                ("Receiver account blocked", "RECEIVER_BLOCKED")
            ]
            
            reason, error_code = random.choice(failure_reasons)
            
            logger.warning(f"❌ Payment failed: {txn_id} - {reason}")
            
            return {
                "status": "failed",
                "transaction_id": txn_id,
                "amount": amount,
                "receiver_upi": receiver_upi,
                "timestamp": datetime.utcnow().isoformat(),
                "message": reason,
                "error_code": error_code
            }
    
    async def check_payment_status(self, transaction_id: str) -> Dict:
        """
        Check status of a payment transaction.
        
        In production, this would query:
        - Payment gateway API
        - Database transaction records
        - NPCI transaction status
        
        Args:
            transaction_id: Unique transaction identifier
        
        Returns:
            Current transaction status
        """
        # Simulate API call delay
        await asyncio.sleep(0.3)
        
        logger.info(f"Checking status for: {transaction_id}")
        
        # Simulate status check
        # In real app, this would query the database
        statuses = ["success", "pending", "failed"]
        weights = [0.7, 0.2, 0.1]  # 70% success, 20% pending, 10% failed
        status = random.choices(statuses, weights=weights)[0]
        
        return {
            "transaction_id": transaction_id,
            "status": status,
            "timestamp": datetime.utcnow().isoformat(),
            "checked_at": datetime.utcnow().isoformat()
        }
    
    def generate_upi_deep_link(
        self,
        receiver_upi: str,
        amount: float,
        receiver_name: str = "",
        transaction_note: str = "",
        transaction_ref: str = ""
    ) -> str:
        """
        Generate UPI deep link for real payment integration.
        
        This is what you'd use in production to open PSP apps.
        
        Format: upi://pay?pa=RECEIVER&pn=NAME&am=AMOUNT&tn=NOTE&tr=REF
        
        Args:
            receiver_upi: Receiver's UPI ID
            amount: Payment amount
            receiver_name: Receiver's name (optional)
            transaction_note: Payment description
            transaction_ref: Transaction reference ID
        
        Returns:
            UPI deep link string
        """
        link = f"upi://pay?pa={receiver_upi}"
        
        if receiver_name:
            link += f"&pn={receiver_name.replace(' ', '+')}"
        
        link += f"&am={amount:.2f}"
        link += "&cu=INR"
        
        if transaction_note:
            link += f"&tn={transaction_note.replace(' ', '+')}"
        
        if transaction_ref:
            link += f"&tr={transaction_ref}"
        
        # Add merchant category code (optional)
        link += "&mc=0000"
        
        logger.debug(f"Generated UPI link: {link}")
        
        return link


# Singleton instance
mock_payment_service = MockPaymentService()
