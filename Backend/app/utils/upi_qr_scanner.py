
import re
from urllib.parse import urlparse, parse_qs
from typing import Dict, Optional, Tuple
from datetime import datetime
import os
import numpy as np
from catboost import CatBoostClassifier

class UPIQRScanner:
    """
    Scans and validates UPI QR codes for fraud detection
    """
    
    @staticmethod
    def parse_upi_qr(qr_data: str) -> Dict[str, str]:
        """
        Parse UPI QR code data into structured format
        """
        if not qr_data or not qr_data.startswith('upi://'):
            if re.match(r'^[\w\.\-]+@[\w\-]+$', qr_data):
                return {
                    'upi_id': qr_data,
                    'payee_name': None,
                    'amount': None,
                    'merchant_code': None,
                    'transaction_id': None,
                    'currency': 'INR',
                    'transaction_ref': None,
                    'url': None
                }
            raise ValueError("Invalid UPI QR code format")
        
        parsed = urlparse(qr_data)
        params = parse_qs(parsed.query)
        
        result = {
            'upi_id': params.get('pa', [None])[0],
            'payee_name': params.get('pn', [None])[0],
            'amount': params.get('am', [None])[0],
            'merchant_code': params.get('mc', [None])[0],
            'transaction_id': params.get('tid', [None])[0],
            'currency': params.get('cu', ['INR'])[0],
            'transaction_ref': params.get('tr', [None])[0],
            'url': params.get('url', [None])[0],
        }
        
        if not result['upi_id']:
            raise ValueError("UPI ID (pa) is required in QR code")
        
        return result
    
    @staticmethod
    def validate_upi_id(upi_id: str) -> Tuple[bool, str]:
        if not upi_id: return False, "Empty UPI ID"
        pattern = r'^[\w\.\-]+@[\w\-]+$'
        if not re.match(pattern, upi_id): return False, "Invalid UPI ID format"
        
        suspicious_patterns = [
            (r'@test', "Test UPI ID detected"),
            (r'@demo', "Demo UPI ID detected"),
            (r'^temp', "Temporary UPI ID detected"),
            (r'\d{10,}@', "Phone-based UPI (higher risk)"),
        ]
        for pattern, message in suspicious_patterns:
            if re.search(pattern, upi_id.lower()):
                return False, message
        return True, ""
    
    @staticmethod
    def extract_receiver_info(qr_data: str) -> Dict:
        try:
            parsed = UPIQRScanner.parse_upi_qr(qr_data)
            is_valid, validation_msg = UPIQRScanner.validate_upi_id(parsed['upi_id'])
            
            risk_flags = []
            if parsed['amount']: risk_flags.append(f"PRE_FILLED_AMOUNT: ₹{parsed['amount']}")
            if not parsed['payee_name']: risk_flags.append("NO_PAYEE_NAME: Anonymous receiver")
            if parsed['url']: risk_flags.append(f"CALLBACK_URL: {parsed['url']}")
            if parsed['currency'] and parsed['currency'] != 'INR': risk_flags.append(f"FOREIGN_CURRENCY: {parsed['currency']}")
            
            return {
                'upi_id': parsed['upi_id'],
                'payee_name': parsed['payee_name'] or "Unknown",
                'is_valid': is_valid,
                'validation_message': validation_msg if not is_valid else "Valid UPI ID",
                'merchant_category': parsed['merchant_code'],
                'suggested_amount': float(parsed['amount']) if parsed['amount'] else None,
                'risk_flags': risk_flags,
                'raw_data': parsed
            }
        except Exception as e:
            return {
                'upi_id': None, 'payee_name': None, 'is_valid': False,
                'validation_message': str(e), 'merchant_category': None,
                'suggested_amount': None, 'risk_flags': ['PARSE_ERROR'], 'raw_data': {}
            }


class UPIReceiverValidator:
    """
    Advanced & Comprehensive QR Validator
    Combines 5 methods including Real ML.
    """
    
    def __init__(self, db_session):
        self.db = db_session
        self.model = None
        # Load ML Model
        try:
            model_path = os.path.join("app", "ml", "catboost_fraud_final.cbm")
            if os.path.exists(model_path):
                self.model = CatBoostClassifier()
                self.model.load_model(model_path)
                print("✅ [ML] CatBoost FINAL Fraud Model Loaded Successfully")
            else:
                print(f"⚠️ [ML] Model not found at {model_path}")
        except Exception as e:
            print(f"❌ [ML] Failed to load model: {e}")
    
    def validate_qr_transaction(self, qr_data: str, user_amount: float = None) -> Dict:
        # Step 1: Parse
        qr_info = UPIQRScanner.extract_receiver_info(qr_data)
        if not qr_info['is_valid']:
            return {
                'status': 'invalid_qr', 'can_proceed': False, 'action': 'BLOCK',
                'message': qr_info['validation_message'], 'risk_score': 1.0,
                'qr_info': qr_info, 'detail_scores': {}
            }

        upi_id = qr_info['upi_id']
        parsed = qr_info['raw_data']

        # METHOD 1: Blacklist
        blacklist_res = self._check_blacklist(upi_id)
        
        # METHOD 2: Patterns
        pattern_res = self._analyze_patterns(parsed, qr_info)

        # METHOD 5: Behavior (Need this for ML features!)
        behavior_res = self._analyze_behavior(upi_id)

        # METHOD 3: REAL ML Model
        ml_score = 0.0
        ml_flags = []
        
        if self.model:
            try:
                # Prepare Features: [amount, is_personal, has_url, scan_count, keyword]
                # 1. Amount
                amt = 0.0
                if parsed.get('amount'): amt = float(parsed['amount'])
                
                # 2. Is Personal (10 digit phone)
                is_personal = 1 if re.match(r'^\d{10}@', upi_id) else 0
                
                # 3. Has URL
                has_url = 1 if parsed.get('url') else 0
                
                # 4. Scan Count (From behavior res)
                scan_count = behavior_res.get('scan_count', 0) # Extracted from behavior
                
                # 5. Keywords
                suspicious_keywords = ['offer', 'refund', 'cashback', 'winner', 'luck', 'claim']
                keyword_risk = 1 if any(w in upi_id for w in suspicious_keywords) else 0
                
                features = [amt, is_personal, has_url, scan_count, keyword_risk]
                
                # Predict
                probs = self.model.predict_proba(features)
                ml_score = probs[1] # Probability of Class 1 (Fraud)
                
                if ml_score > 0.6:
                    ml_flags.append(f"🤖 AI Confidence: {(ml_score*100):.0f}% Risk")
            except Exception as e:
                print(f"ML Prediction Error: {e}")
                
        ml_res = {'score': ml_score, 'flags': ml_flags}

        # COMBINED SCORE
        combined_score = (
            blacklist_res['score'] * 0.35 +
            pattern_res['score'] * 0.25 +
            ml_res['score'] * 0.20 +
            behavior_res['score'] * 0.20
        )
        
        if blacklist_res['is_blacklisted']: combined_score = 1.0
        if pattern_res['score'] >= 0.8: combined_score = max(combined_score, 0.85)
        if ml_score > 0.8: combined_score = max(combined_score, 0.80) # Strong AI signal

        # Verdict
        if combined_score >= 0.80:
            verdict, action, msg = "FRAUD", "BLOCK", "🚫 FRAUD DETECTED - This QR is dangerous"
        elif combined_score >= 0.50:
             verdict, action, msg = "HIGH_RISK", "HARD_CHALLENGE", "⚠️ Proceed with Extreme Caution"
        elif combined_score >= 0.25:
             verdict, action, msg = "MODERATE_RISK", "SOFT_CHALLENGE", "⚠️ Verify Receiver Identity"
        else:
             verdict, action, msg = "SAFE", "ALLOW", "✅ Safe to Proceed"

        # Amount Check
        if user_amount and qr_info['suggested_amount']:
            if abs(user_amount - float(qr_info['suggested_amount'])) > 1.0:
                pattern_res['flags'].append(f"💰 Amount Mismatch: Paying ₹{user_amount} vs QR ₹{qr_info['suggested_amount']}")
                combined_score = max(combined_score, 0.35)
                if action == "ALLOW": action = "SOFT_CHALLENGE"

        all_flags = blacklist_res['flags'] + pattern_res['flags'] + ml_res['flags'] + behavior_res['flags']

        return {
            'status': 'validated',
            'can_proceed': action != "BLOCK",
            'action': action,
            'message': msg,
            'overall_risk': round(combined_score, 2),
            'qr_info': qr_info,
            'receiver_reputation': blacklist_res['raw_data'],
            'risk_factors': all_flags,
            'recommendations': self._generate_recommendations(verdict, all_flags),
            'detail_scores': {
                'blacklist': round(blacklist_res['score'], 2),
                'pattern': round(pattern_res['score'], 2),
                'behavior': round(behavior_res['score'], 2),
                'ml': round(ml_score, 2)
            }
        }

    def _check_blacklist(self, upi_id: str) -> Dict:
        try:
            from app.database.models import ReceiverReputation
            receiver = self.db.query(ReceiverReputation).filter(ReceiverReputation.receiver == upi_id).first()
            if not receiver:
                return {'score': 0.0, 'is_blacklisted': False, 'flags': ['🆕 New/Unknown Receiver'], 'raw_data': {}}
            fraud_ratio = receiver.fraud_count / receiver.total_transactions if receiver.total_transactions > 0 else 0
            is_blacklisted = fraud_ratio >= 0.7
            flags = []
            if is_blacklisted: flags.append(f"⛔ BLACKLISTED in database ({fraud_ratio*100:.0f}% fraud rate)")
            elif fraud_ratio > 0.4: flags.append(f"🚨 High Fraud History ({receiver.fraud_count} reports)")
            return {'score': fraud_ratio, 'is_blacklisted': is_blacklisted, 'flags': flags, 'raw_data': {'fraud_ratio': fraud_ratio, 'is_blacklisted': is_blacklisted}}
        except ImportError:
            return {'score': 0.0, 'is_blacklisted': False, 'flags': [], 'raw_data': {}}

    def _analyze_patterns(self, parsed: Dict, qr_info: Dict) -> Dict:
        score, flags = 0.0, []
        upi_id = parsed.get('upi_id', '').lower()
        amount_str = parsed.get('amount')
        
        if amount_str:
            try:
                amt = float(amount_str)
                if amt > 20000: score += 0.4; flags.append(f"⚠️ High Pre-filled Amount (₹{amt})")
                elif amt > 5000: score += 0.2; flags.append(f"⚠️ Pre-filled Amount (₹{amt})")
                if amt > 1000 and amt % 500 == 0: score += 0.1; flags.append("⚠️ Suspiciously round amount")
            except: pass

        if re.match(r'^\d{10}@', upi_id): score += 0.2; flags.append("⚠️ Personal Phone Number UPI")
        
        suspicious_keywords = ['offer', 'refund', 'cashback', 'winner', 'luck', 'claim']
        if any(w in upi_id for w in suspicious_keywords): score += 0.5; flags.append(f"🚨 Suspicious keyword in UPI ID")
        
        if parsed.get('url'): score += 0.4; flags.append("🚨 External Link in QR (Phishing Risk)")
        
        return {'score': min(1.0, score), 'flags': flags}

    def _analyze_behavior(self, upi_id: str) -> Dict:
        try:
            from app.database.models import QRScan
            from sqlalchemy import func
            scan_count = self.db.query(func.count(QRScan.id)).filter(QRScan.upi_id == upi_id).scalar() or 0
            score, flags = 0.0, []
            
            if scan_count > 100: score += 0.4; flags.append(f"🔥 Viral Scan Activity ({scan_count} scans)")
            elif scan_count == 0: score += 0.1
            
            # Return scan_count too for ML to use
            return {'score': score, 'flags': flags, 'scan_count': scan_count}
        except ImportError:
            return {'score': 0.0, 'flags': [], 'scan_count': 0}

    def _generate_recommendations(self, verdict: str, flags: list) -> list:
        recs = []
        if verdict == "FRAUD": recs.extend(["⛔ DO NOT PAY under any circumstances", "🔒 Report this QR to police/cybercell"])
        elif verdict == "HIGH_RISK": recs.extend(["📞 Call the receiver to verify identify manually", "❌ Do not pay if you received this via WhatsApp/SMS"])
        elif verdict == "MODERATE_RISK": recs.extend(["👁️ Check the name on the scanner carefully", "💰 Verify the amount is correct"])
        else: recs.append("✅ Safe to Pay")
        return recs

