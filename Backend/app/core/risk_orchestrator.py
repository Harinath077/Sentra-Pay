"""
RISK ORCHESTRATOR - THE BRAIN 🧠
Combines Rules + ML + Context to make intelligent fraud decisions.
"""

from typing import Dict, Optional
from datetime import datetime
from sqlalchemy.orm import Session
import logging
import uuid

from app.core.context_engine import get_user_context
from app.core.rules_engine import evaluate as evaluate_rules
from app.core.ml_engine import predict as ml_predict
from app.core.decision_engine import get_action
from app.core.genai_engine import genai  # 🍌 Import Gemini Banana
from app.database.models import RiskEvent, Transaction
from app.database.connection import SessionLocal

logger = logging.getLogger(__name__)


class RiskOrchestrator:
    """
    The central brain that coordinates all risk assessment components.
    """
    
    def __init__(self):
        logger.info("Risk Orchestrator initialized")
    
    def analyze_transaction(
        self,
        txn_data: Dict,
        user_id: str,
        db: Optional[Session] = None
    ) -> Dict:
        """
        Main orchestration method - THE BRAIN.
        """
        close_db = False
        if not db:
            db = SessionLocal()
            close_db = True
        
        try:
            transaction_id = self._generate_transaction_id()
            receiver = txn_data.get("receiver", "")
            amount = txn_data.get("amount", 0.0)
            
            logger.info(f"🧠 Orchestrating risk analysis: {transaction_id} - User: {user_id}")
            
            # Get User PK (int) first
            from app.database.models import User
            user_orm = db.query(User).filter(User.user_id == user_id).first()
            if not user_orm:
                raise ValueError(f"User not found: {user_id}")
            
            # Create PENDING Transaction Record (for FK and confirmation)
            txn_params = {
                "transaction_id": transaction_id,
                "user_id": user_orm.id,
                "amount": amount,
                "receiver": receiver,
                "note": txn_data.get("note", ""),
                "status": "PENDING",
                "device_id": txn_data.get("device_id", "")
            }
            
            new_txn = Transaction(**txn_params)
            db.add(new_txn)
            db.commit()
            db.refresh(new_txn)  # Get ID (int PK)
            
            # ──────────────────────────────────────────────
            # STEP 1: GATHER CONTEXT
            # ──────────────────────────────────────────────
            context = get_user_context(user_id, receiver, db)
            logger.info(f"✓ Context retrieved: {context.user_profile.get('risk_tier', 'BRONZE')}")
            
            # ──────────────────────────────────────────────
            # STEP 2: RUN RULES ENGINE
            # ──────────────────────────────────────────────
            rule_result = evaluate_rules(txn_data, context)
            
            # Check for hard blocks (override everything)
            if rule_result.hard_block:
                logger.warning(f"⛔ HARD BLOCK: {rule_result.block_reason}")
                
                # Update Transaction status to BLOCKED & Risk Score 1.0
                new_txn.status = "BLOCKED"
                new_txn.risk_score = 1.0
                new_txn.risk_level = "VERY_HIGH"
                new_txn.action_taken = "BLOCK"
                db.commit()
                
                return self._create_blocked_response(
                    transaction_id=transaction_id,
                    reason=rule_result.block_reason,
                    txn_data=txn_data,
                    context=context,
                    db=db,
                    user_id=user_orm.id, # Pass int PK
                    txn_pk=new_txn.id # Pass int PK
                )
            
            logger.info(f"✓ Rules score: {rule_result.rule_score:.2f} - Flags: {rule_result.flags}")
            
            # ──────────────────────────────────────────────
            # STEP 3: RUN ML ENGINE
            # ──────────────────────────────────────────────
            ml_result = ml_predict(txn_data, context)
            logger.info(f"✓ ML score: {ml_result.ml_score:.2f} ({ml_result.model_version})")
            
            # ──────────────────────────────────────────────
            # STEP 4: COMBINE SCORES
            # ──────────────────────────────────────────────
            final_score = self._combine_scores(
                rule_score=rule_result.rule_score,
                ml_score=ml_result.ml_score,
                flags=rule_result.flags,
                context=context,
                txn_data=txn_data
            )
            logger.info(f"✓ Final combined score: {final_score:.2f}")
            
            # ──────────────────────────────────────────────
            # STEP 5: DETERMINE ACTION
            # ──────────────────────────────────────────────
            action_result = get_action(
                risk_score=final_score,
                flags=rule_result.flags,
                user_tier=context.user_profile.get("risk_tier", "BRONZE")
            )
            logger.info(f"✓ Action: {action_result.action} ({action_result.risk_level})")
            
            # Update Transaction with results
            new_txn.risk_score = final_score
            new_txn.risk_level = action_result.risk_level
            new_txn.ml_score = ml_result.ml_score
            new_txn.rule_score = rule_result.rule_score
            new_txn.action_taken = action_result.action
            # status remains PENDING until confirmed
            db.commit()

            # ──────────────────────────────────────────────
            # STEP 6: BUILD RESPONSE
            # ──────────────────────────────────────────────
            response = self._build_response(
                transaction_id=transaction_id,
                final_score=final_score,
                rule_result=rule_result,
                ml_result=ml_result,
                action_result=action_result,
                txn_data=txn_data,
                context=context
            )
            
            # ──────────────────────────────────────────────
            # STEP 7: LOG RISK EVENT
            # ──────────────────────────────────────────────
            self._log_risk_event(
                user_id=user_orm.id, # Pass int PK
                transaction_id=new_txn.id, # Pass int PK
                txn_data=txn_data,
                final_score=final_score,
                action=action_result.action,
                rule_result=rule_result,
                ml_result=ml_result,
                db=db
            )
            
            logger.info(f"✓ Risk analysis complete: {action_result.action}")
            return response
        
        finally:
            if close_db:
                db.close()
    
    def _combine_scores(
        self,
        rule_score: float,
        ml_score: float,
        flags: list,
        context,
        txn_data: Dict
    ) -> float:
        """
        Combine scores using the MASTER PROMPT LOGIC.
        
        Formula: FinalScore = Clamp(RiskSignals - TrustSignals, 0.0, 1.0)
        
        Risk Signals:
        - First-time receiver:            +0.30
        - Suspicious Keywords:            +0.30
        - Amount > 25,000:                +0.30 (Hierarchical)
        - Amount > 10x Avg:               +0.25 (Hierarchical, if not >25k)
        - Amount > 5x Avg:                +0.15 (Hierarchical, if not >10x)
        - New Device:                     +0.15
        - Night Time (10PM-6AM):          +0.15
        - ML High Risk (>0.8):            +0.15
        
        Trust Signals:
        - Previous Successful Txn:        -0.20
        - Good Receiver Reputation:       -0.15
        - Gold Tier User:                 -0.10
        """
        score = 0.0
        amount = txn_data.get("amount", 0.0)
        receiver = txn_data.get("receiver", "")
        avg_amount = context.txn_stats.get("avg_amount_30d", 1000.0)
        if avg_amount == 0: avg_amount = 1000.0
        
        # ──────────────────────────────────────────────
        # 1. RISK SIGNALS (ADDITIVE)
        # ──────────────────────────────────────────────
        
        # Receiver Risk
        is_new_receiver = context.receiver_info.get("is_new", True)
        if is_new_receiver:
            score += 0.20
            # logger.info("Risk: First-time receiver (+0.30)")

        # Suspicious Keywords (lottery, prize, etc.)
        keywords = ["lottery", "prize", "kyc", "crypto", "refund", "win", "cashback"]
        note = txn_data.get("note", "").lower()
        if any(k in note for k in keywords) or "lottery" in receiver.lower():
            score += 0.30
            # logger.info("Risk: Suspicious keyword detected (+0.30)")

        # Amount Risk (Hierarchical)
        if amount > 2500000:  # 25,000 INR
            score += 0.30
            # logger.info("Risk: Amount > 25k (+0.30)")
        elif amount > (avg_amount * 10):
            score += 0.25
            # logger.info("Risk: Extreme spike > 10x (+0.25)")
        elif amount > (avg_amount * 5):
            score += 0.15
            # logger.info("Risk: Spike > 5x (+0.15)")
            
        # Context Risk
        # Night Time (10PM - 6AM)
        hour = datetime.now().hour
        if hour >= 22 or hour < 6:
            score += 0.15
            # logger.info("Risk: Night transaction (+0.15)")
            
        # Device Risk
        if "DEVICE_CHANGE" in flags:
            score += 0.15
            # logger.info("Risk: New device (+0.15)")
            
        # ML Signal
        if ml_score > 0.8:
            score += 0.15
            # logger.info("Risk: ML Model High Probability (+0.15)")

        # ──────────────────────────────────────────────
        # 2. TRUST SIGNALS (SUBTRACTIVE)
        # ──────────────────────────────────────────────
        
        if not is_new_receiver:
            score -= 0.20
            # logger.info("Trust: Previous successful transaction (-0.20)")
            
        if context.receiver_info.get("reputation_score", 0.5) < 0.2:
            score -= 0.15
            # logger.info("Trust: Good receiver reputation (-0.15)")
            
        if context.user_profile.get("risk_tier") == "GOLD":
            score -= 0.10
            # logger.info("Trust: Gold Tier User (-0.10)")
            
        # ──────────────────────────────────────────────
        # 3. CLAMPING
        # ──────────────────────────────────────────────
        final = max(0.0, min(1.0, score))
        # logger.info(f"Final Calculated Score: {final}")
        
        return final
    
    def _build_response(
        self,
        transaction_id: str,
        final_score: float,
        rule_result,
        ml_result,
        action_result,
        txn_data: Dict,
        context
    ) -> Dict:
        """
        Build comprehensive risk analysis response.
        
        Structure matches UI requirements:
        - Risk score and level
        - Risk breakdown (behavior, amount, receiver)
        - Risk factors
        - Recommendations
        - Action requirements
        """
        amount = txn_data.get("amount", 0.0)
        receiver = txn_data.get("receiver", "")
        
        # Calculate component scores for breakdown
        behavior_score = self._calculate_behavior_score(context, rule_result)
        amount_score = self._calculate_amount_score(txn_data, context)
        receiver_score = self._calculate_receiver_score(context, receiver)
        
        return {
            "transaction_id": transaction_id,
            "timestamp": datetime.utcnow().isoformat(),
            
            # Risk scoring
            "risk_score": round(final_score, 2),
            "risk_level": action_result.risk_level,
            "risk_percentage": int(final_score * 100),
            
            "action": action_result.action,
            "message": action_result.message,
            "can_proceed": action_result.action in ["ALLOW", "WARNING"],
            "requires_otp": action_result.requires_otp,

            # UI Rendering Fields
            "icon": "🟢" if action_result.action == "ALLOW" else ("🟠" if action_result.action == "WARNING" else ("🔵" if action_result.action == "OTP_REQUIRED" else "🔴")),
            "color": "#4CAF50" if action_result.action == "ALLOW" else ("#FF9800" if action_result.action == "WARNING" else ("#2196F3" if action_result.action == "OTP_REQUIRED" else "#F44336")),
            "background": "#E8F5E9" if action_result.action == "ALLOW" else ("#FFF3E0" if action_result.action == "WARNING" else ("#E3F2FD" if action_result.action == "OTP_REQUIRED" else "#FFEBEE")),
            "label": "Safe Transaction" if action_result.action == "ALLOW" else ("Moderate Risk" if action_result.action == "WARNING" else ("Verification Required" if action_result.action == "OTP_REQUIRED" else "High Risk Blocked")),
            
            # 🍌 Gemini GenAI Context
            "genai_analysis": genai.generate_explanation(
                risk_score=final_score,
                flags=rule_result.flags,
                receiver=receiver
            ),

            # Risk breakdown (matches UI design)
            "risk_breakdown": {
                "behavior_analysis": {
                    "score": behavior_score,
                    "weight": 30,
                    "status": "normal" if behavior_score < 40 else "suspicious"
                },
                "amount_analysis": {
                    "score": amount_score,
                    "weight": 30,
                    "status": "normal" if amount_score < 40 else "unusual"
                },
                "receiver_analysis": {
                    "score": receiver_score,
                    "weight": 40,
                    "status": "verified" if receiver_score < 30 else "new"
                }
            },
            
            # Risk factors
            "risk_factors": self._extract_risk_factors(rule_result, ml_result, context),
            
            # Recommendations
            "recommendations": action_result.recommendations,
            
            # Transaction details
            "transaction_details": {
                "amount": amount,
                "receiver": receiver,
                "note": txn_data.get("note", "")
            },
            
            # User info
            "user_info": {
                "trust_score": context.user_profile.get("trust_score", 0),
                "risk_tier": context.user_profile.get("risk_tier", "BRONZE"),
                "transaction_count_30d": context.txn_stats.get("txn_count_30d", 0)
            },
            
            # Receiver info
            "receiver_info": {
                "identifier": receiver,
                "is_new": context.receiver_info.get("is_new", True) if context.receiver_info else True,
                "reputation_score": context.receiver_info.get("reputation_score", 0.5) if context.receiver_info else 0.5,
                "total_transactions": context.receiver_info.get("total_transactions", 0) if context.receiver_info else 0
            },
            
            # Debug info (for development)
            "debug": {
                "rule_score": round(rule_result.rule_score, 2),
                "ml_score": round(ml_result.ml_score, 2),
                "flags": rule_result.flags,
                "model_version": ml_result.model_version
            }
        }
    
    def _create_blocked_response(
        self,
        transaction_id: str,
        reason: str,
        txn_data: Dict,
        context,
        db: Session,
        user_id: int,
        txn_pk: int
    ) -> Dict:
        """Create response for hard-blocked transactions."""
        
        # Log the block
        self._log_risk_event(
            user_id=user_id,
            transaction_id=txn_pk,
            txn_data=txn_data,
            final_score=1.0,
            action="BLOCK",
            rule_result=None,
            ml_result=None,
            db=db
        )
        
        return {
            "transaction_id": transaction_id,
            "timestamp": datetime.utcnow().isoformat(),
            "risk_score": 1.0,
            "risk_level": "VERY_HIGH",
            "risk_percentage": 100,
            "message": f"🚫 Transaction blocked: {reason}",
            "can_proceed": False,
            "requires_otp": False,
            "icon": "🔴",
            "color": "#F44336",
            "background": "#FFEBEE",
            "label": "High Risk Blocked",
            "risk_factors": [
                {"factor": "Blacklisted Receiver", "severity": "critical"}
            ],
            "recommendations": [
                "This receiver has been flagged for suspicious activity",
                "Contact support if you believe this is an error"
            ]
        }
    
    def _calculate_behavior_score(self, context, rule_result) -> int:
        """Calculate behavior analysis score (0-100)."""
        score = 0
        
        # Velocity contribution
        if rule_result and "VELOCITY_SPIKE" in rule_result.flags:
            score += 40
        
        # Device change contribution
        if rule_result and "DEVICE_CHANGE" in rule_result.flags:
            score += 20
        
        # Failed transaction pattern
        if rule_result and "HIGH_FAILED_TXN" in rule_result.flags:
            score += 30
        
        # Days since last transaction
        if context:
            days_since = context.txn_stats.get("days_since_last_txn", 0)
            if days_since > 30:
                score += 20
        
        return min(score, 100)
    
    def _calculate_amount_score(self, txn_data: Dict, context) -> int:
        """Calculate amount analysis score (0-100)."""
        amount = txn_data.get("amount", 0.0)
        avg_amount = context.txn_stats.get("avg_amount_30d", 1000.0)
        
        if avg_amount == 0:
            avg_amount = 1000.0
        
        ratio = amount / avg_amount
        
        if ratio > 10:
            return 100
        elif ratio > 5:
            return 80
        elif ratio > 3:
            return 60
        elif ratio > 1.5:
            return 40
        else:
            return 20
    
    def _calculate_receiver_score(self, context, receiver: str) -> int:
        """Calculate receiver analysis score (0-100)."""
        if not context.receiver_info:
            return 50  # Unknown receiver
        
        is_new = context.receiver_info.get("is_new", True)
        reputation_score = context.receiver_info.get("reputation_score", 0.5)
        
        score = 0
        
        if is_new:
            score += 40
        
        # Reputation contribution (0.0 = good, 1.0 = bad)
        score += int(reputation_score * 60)
        
        return min(score, 100)
    
    def _extract_risk_factors(self, rule_result, ml_result, context) -> list:
        """Extract top risk factors for user explanation."""
        factors = []
        
        # From rules engine flags
        flag_messages = {
            "NEW_RECEIVER_HIGH_AMOUNT": {
                "factor": "High amount to new receiver",
                "severity": "high",
                "detail": "This is a large transaction to someone you haven't paid before"
            },
            "VELOCITY_SPIKE": {
                "factor": "Unusual transaction frequency",
                "severity": "medium",
                "detail": "Multiple transactions in short time period"
            },
            "DEVICE_CHANGE": {
                "factor": "New device detected",
                "severity": "medium",
                "detail": "Transaction from unrecognized device"
            },
            "HIGH_FAILED_TXN": {
                "factor": "Multiple failed transactions",
                "severity": "medium",
                "detail": "Recent failed transaction attempts detected"
            }
        }
        
        for flag in rule_result.flags:
            if flag in flag_messages:
                factors.append(flag_messages[flag])
        
        # From ML features
        features = ml_result.features
        
        if features.get("amount_to_avg_ratio", 1.0) > 3:
            factors.append({
                "factor": "Amount significantly above average",
                "severity": "medium",
                "detail": f"This amount is {features.get('amount_to_avg_ratio', 0):.1f}x your usual"
            })
        
        if features.get("days_since_last_txn", 0) > 30:
            factors.append({
                "factor": "Account dormancy",
                "severity": "low",
                "detail": "First transaction in over 30 days"
            })
        
        # Limit to top 5 factors
        return factors[:5]
    
    def _log_risk_event(
        self,
        user_id: int,
        transaction_id: int,
        txn_data: Dict,
        final_score: float,
        action: str,
        rule_result,
        ml_result,
        db: Session
    ):
        """Log risk event to database."""
        try:
            risk_event = RiskEvent(
                user_id=user_id,
                transaction_id=transaction_id,
                final_score=final_score,
                action=action,
                rule_score=rule_result.rule_score if rule_result else 1.0,
                ml_score=ml_result.ml_score if ml_result else 0.0,
                flags=rule_result.flags if rule_result else ["HARD_BLOCK"]
            )
            
            # Map features if possible
            if ml_result and hasattr(ml_result, 'features'):
                risk_event.features = ml_result.features
            
            db.add(risk_event)
            db.commit()
            logger.info(f"✓ Risk event logged: {risk_event.id}")
        
        except Exception as e:
            logger.error(f"Failed to log risk event: {e}")
            db.rollback()
    
    def _generate_transaction_id(self) -> str:
        """Generate unique transaction ID."""
        return f"TXN-{datetime.utcnow().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"


# Global orchestrator instance
orchestrator = RiskOrchestrator()
