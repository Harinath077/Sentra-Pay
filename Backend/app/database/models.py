"""
SQLAlchemy Database Models.
Defines all database tables for the fraud detection system.
"""

from sqlalchemy import Column, String, Integer, Float, DateTime, ForeignKey, JSON, Text, Numeric, UniqueConstraint, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database.connection import Base
import uuid


class User(Base):
    """User model for authentication and profile."""
    
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String(50), unique=True, nullable=False, index=True, default=lambda: f"USER-{uuid.uuid4().hex[:8].upper()}")
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20), unique=True, nullable=True)
    password_hash = Column(String(255), nullable=True) # Nullable for Oauth users
    full_name = Column(String(255), nullable=False)
    
    # OAuth Fields
    google_id = Column(String(255), unique=True, nullable=True)
    login_method = Column(String(20), default="email") # email, google
    is_verified = Column(Boolean, default=False)
    auth_provider = Column(String(50), nullable=True) # For linking accounts
    
    # Trust & Risk Metrics
    trust_score = Column(Float, default=0.0)
    risk_tier = Column(String(20), default="BRONZE")  # BRONZE, SILVER, GOLD
    
    # Device Tracking
    known_devices = Column(JSON, default=list)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    transactions = relationship("Transaction", back_populates="user")
    
    def __repr__(self):
        return f"<User {self.user_id} - {self.email}>"


class Transaction(Base):
    """Transaction model for payment history."""
    
    __tablename__ = "transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    transaction_id = Column(String(50), unique=True, nullable=False, index=True, default=lambda: f"UPI-{uuid.uuid4().hex[:10].upper()}")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    # Transaction Details
    amount = Column(Numeric(15, 2), nullable=False)
    receiver = Column(String(255), nullable=False, index=True)
    note = Column(Text, nullable=True)
    
    # Risk Analysis Results
    risk_score = Column(Float, nullable=True)
    risk_level = Column(String(20), nullable=True)  # LOW, MODERATE, HIGH, VERY_HIGH
    ml_score = Column(Float, nullable=True)
    rule_score = Column(Float, nullable=True)
    
    # Decision
    action_taken = Column(String(20), nullable=True)  # ALLOW, WARNING, OTP_REQUIRED, BLOCK
    status = Column(String(20), default="PENDING")  # PENDING, COMPLETED, FAILED, BLOCKED, CANCELLED
    
    # Payment Completion Details (populated after payment)
    payment_timestamp = Column(DateTime(timezone=True), nullable=True)  # When payment was completed
    utr_number = Column(String(20), nullable=True)  # Unique Transaction Reference (12 digits)
    psp_name = Column(String(50), nullable=True)  # Payment Service Provider (GPay, PhonePe, etc.)
    
    # Payment Details
    payment_method = Column(String(255), nullable=True)
    
    # Blockchain Immutable Ledger
    current_hash = Column(String(64), nullable=True, index=True)
    previous_hash = Column(String(64), nullable=True)
    
    # Location Data (for geo-velocity fraud detection)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    completed_at = Column(DateTime(timezone=True), nullable=True)
    device_id = Column(String(100), nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="transactions")
    risk_events = relationship("RiskEvent", back_populates="transaction")
    
    def __repr__(self):
        return f"<Transaction {self.transaction_id} - ₹{self.amount}>"


class RiskEvent(Base):
    """Risk event log for audit and ML training."""
    
    __tablename__ = "risk_events"
    
    id = Column(Integer, primary_key=True, index=True)
    transaction_id = Column(Integer, ForeignKey("transactions.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    # Risk Analysis Details
    rule_triggered = Column(String(50), nullable=True)
    ml_score = Column(Float, nullable=True)
    rule_score = Column(Float, nullable=True)
    final_score = Column(Float, nullable=True)
    
    # Action
    action = Column(String(20), nullable=True)
    
    # Features (for ML training)
    features = Column(JSON, nullable=True)
    flags = Column(JSON, default=list)
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    
    # Relationships
    transaction = relationship("Transaction", back_populates="risk_events")
    
    def __repr__(self):
        return f"<RiskEvent {self.id} - Score: {self.final_score}>"


class ReceiverReputation(Base):
    """Receiver reputation tracking."""
    
    __tablename__ = "receiver_reputation"
    
    id = Column(Integer, primary_key=True, index=True)
    receiver = Column(String(255), unique=True, nullable=False, index=True)
    
    # Reputation Metrics
    total_transactions = Column(Integer, default=0)
    successful_transactions = Column(Integer, default=0)
    fraud_count = Column(Integer, default=0)
    chargeback_count = Column(Integer, default=0)
    
    # Calculated Score
    reputation_score = Column(Float, default=0.5)
    
    # Metadata
    first_seen = Column(DateTime(timezone=True), server_default=func.now())
    last_updated = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    
    def __repr__(self):
        return f"<ReceiverReputation {self.receiver} - Score: {self.reputation_score}>"

class QRScan(Base):
    """
    Tracks history of scanned QRs for behavioral analysis.
    Method 5: Behavioral Analysis (Virus/Scam Detection)
    """
    __tablename__ = "qr_scans"

    id = Column(Integer, primary_key=True, index=True)
    
    # QR Identity
    upi_id = Column(String(255), index=True)
    qr_hash = Column(String(255), index=True) # Hash of full string to track identical QRs
    
    # Context
    scanned_at = Column(DateTime(timezone=True), server_default=func.now())
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True) # Nullable for anonymous scans
    ip_address = Column(String(50), nullable=True)
    device_id = Column(String(100), nullable=True)
    
    # Risk Result
    risk_score = Column(Float)
    action_taken = Column(String(50))
    flags = Column(JSON, default=list) # List of flags raised

    reported_fraud = Column(Integer, default=0) # 1 if user later reported this specific scan

    def __repr__(self):
        return f"<QRScan {self.upi_id} @ {self.scanned_at}>"



class ReceiverHistory(Base):
    """
    Tracks history of payments to specific receivers by specific users.
    Used for 'First-Time Receiver' logic.
    """
    __tablename__ = "receiver_history"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    receiver_upi = Column(String(255), nullable=False, index=True)
    
    first_paid_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    last_paid_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())
    
    payment_count = Column(Integer, default=1)
    total_amount = Column(Numeric(15, 2), default=0.00)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Ensure one record per user-receiver pair
    __table_args__ = (
        UniqueConstraint('user_id', 'receiver_upi', name='uix_user_receiver'),
    )
    
    # Relationship
    user = relationship("User", backref="receiver_history_records")

    def __repr__(self):
        return f"<ReceiverHistory {self.user_id} -> {self.receiver_upi} ({self.payment_count})>"
