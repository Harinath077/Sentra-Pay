import asyncio
import random
from typing import Dict, Optional, List
from datetime import datetime

class MockUPIService:
    """
    Mock UPI VPA validation service for hackathon demo.
    Simulates NPCI's name inquiry API without needing real integration.
    """
    
    # 🏦 Bank Handle Mapping Layer (The "Realism" Upgrade)
    BANK_HANDLES = {
        "paytm": "Paytm Payments Bank",
        "okaxis": "Axis Bank",
        "okhdfcbank": "HDFC Bank",
        "okicici": "ICICI Bank",
        "oksbi": "State Bank of India",
        "ybl": "YES Bank",
        "ibl": "ICICI Bank",
        "axl": "Axis Bank",
        "idfcbank": "IDFC First Bank",
        "waaxis": "WhatsApp (Axis Bank)",
        "ikwik": "MobiKwik",
        "postbank": "India Post Payments Bank",
        "jupiteraxis": "Jupiter (Axis Bank)",
        "niyo": "Niyo (Equitas Bank)", 
        "slice": "Slice (SBM Bank)",
        "uni": "Uni Cards",
        "kotak": "Kotak Mahindra Bank",
        "barodampay": "Bank of Baroda"
    }

    # Mock database of Specific Users
    MOCK_USERS = {
        # Famous people
        "sachin@paytm": {
            "name": "Sachin Ramesh Tendulkar",
            "reputation_score": 0.99,
            "account_age_days": 1825,
            "verified": True
        },
        "virat@ybl": {
            "name": "Virat Kohli",
            "reputation_score": 0.98,
            "account_age_days": 1460,
            "verified": True
        },
        
        # Merchants
        "swiggy@paytm": {
            "name": "Swiggy Limited",
            "reputation_score": 0.99,
            "account_age_days": 2000,
            "verified": True,
            "is_merchant": True
        },
        
        # Custom Users
        "arun@oksbi": {
            "name": "Arun Kumar",
            "reputation_score": 0.85,
            "account_age_days": 800,
            "verified": True
        },
        "sriram@okaxis": {
            "name": "Sriram V",
            "reputation_score": 0.90,
            "account_age_days": 600,
            "verified": True
        },
        "sabarish@paytm": {
            "name": "Sabarish N",
            "reputation_score": 0.88,
            "account_age_days": 1200,
            "verified": True
        },
        "ram@okhdfcbank": {
            "name": "Ram Charan",
            "reputation_score": 0.95,
            "account_age_days": 1500,
            "verified": True
        },
        "gopal@ybl": {
            "name": "Gopal Krishna",
            "reputation_score": 0.70,
            "account_age_days": 400,
            "verified": True
        },
        "roshan@ikwik": {
            "name": "Roshan S",
            "reputation_score": 0.60,
            "account_age_days": 200,
            "verified": True
        },
        "jenisha@okicici": {
            "name": "Jenisha R",
            "reputation_score": 0.92,
            "account_age_days": 900,
            "verified": True
        },
        "priya@dbs": {
            "name": "Priya Shah",
            "reputation_score": 0.94,
            "account_age_days": 1100,
            "verified": True
        },
        "thithiksha@barodampay": {
            "name": "Thithiksha K",
            "reputation_score": 0.89,
            "account_age_days": 700,
            "verified": True
        },

        # Suspicious / Fraud Accounts
        # Suspicious / Fraud Accounts (Realistic)
        "sbi.kyc.support@ybl": {
            "name": "Bank Kyc Verification",
            "reputation_score": 0.15,
            "account_age_days": 3,
            "fraud_reports": 145,
            "verified": False
        },
        "amazon.refunds.dept@paytm": {
            "name": "Order Refunds",
            "reputation_score": 0.12,
            "account_age_days": 1,
            "fraud_reports": 89,
            "verified": False
        },
        "electricity.board.help@okaxis": {
            "name": "Electricity Board Support",
            "reputation_score": 0.05,
            "account_age_days": 0,
            "fraud_reports": 210,
            "verified": False
        },
        "vikram_trader_99@okicici": { 
            "name": "Vikram Traders",
            "reputation_score": 0.25,
            "account_age_days": 20,
            "fraud_reports": 15,
            "verified": False
        },

        # Fraud Accounts
        "scammer@paytm": {
            "name": "Suspicious Account",
            "reputation_score": 0.15,
            "account_age_days": 10,
            "fraud_reports": 47,
            "verified": False
        },
        "mule@okaxis": {
            "name": "Money Mule",
            "reputation_score": 0.08,
            "account_age_days": 5,
            "fraud_reports": 89,
            "verified": False
        }
    }
    
    async def validate_vpa(self, vpa: str) -> Dict:
        """
        Validate UPI Virtual Payment Address with Behavioral Classification.
        """
        # Simulate network delay for realism (300ms - 800ms)
        await asyncio.sleep(random.uniform(0.3, 0.8))
        
        vpa_clean = vpa.lower().strip()
        
        # 1. basic format check
        if not self._is_valid_upi_format(vpa_clean):
            return self._build_error_response(vpa, "Invalid UPI ID format")

        # 2. Extract Handle & Bank Name
        try:
            handle = vpa_clean.split("@")[1]
            bank_name = self.BANK_HANDLES.get(handle, "Unified Payments Interface Network")
        except IndexError:
            return self._build_error_response(vpa, "Invalid handle")

        # 3. Check Mock Database / Simulate Lookup
        user_data = self.MOCK_USERS.get(vpa_clean)
        
        if user_data:
            # KNOWN USER (Mocked)
            name = user_data["name"]
            is_merchant = user_data.get("is_merchant", False)
            reputation = user_data.get("reputation_score", 0.5)
            verified = user_data.get("verified", True)
            fraud_reports = user_data.get("fraud_reports", 0)
            account_age = user_data.get("account_age_days", 100)
            
        else:
            # UNKNOWN USER -> SIMULATE REALISM
            name = vpa_clean.split("@")[0].title() + " (Unverified)" 
            is_merchant = False
            reputation = 0.5  # Neutral start
            verified = True   # It "exists" at the bank level
            fraud_reports = 0
            account_age = random.randint(30, 500) # Simulate random age

        # 4. CLASSIFICATION LOGIC
        ui_props = {}
        
        # PRIORITY 1: BLACKLISTED
        if fraud_reports >= 3 or reputation < 0.2:
            status = "BLACKLISTED"
            ui_props = {
                "icon": "🔴",
                "color": "#F44336",
                "background": "#FFEBEE",
                "label": "High Risk Account",
                "can_proceed": False,
                "action": "BLOCK",
                "warning": "🚨 Flagged for suspicious activity.",
                "recommendation": "Transaction blocked for safety."
            }
            risk_level = "High"
            risk_score = 90
            
        # PRIORITY 2: VERIFIED
        elif is_merchant and reputation > 0.8:
            status = "VERIFIED"
            ui_props = {
                "icon": "🟢",
                "color": "#4CAF50",
                "background": "#E8F5E9",
                "label": "Verified Merchant",
                "can_proceed": True,
                "action": "ALLOW",
                "message": "✅ Verified merchant with excellent track record."
            }
            risk_level = "Low"
            risk_score = 10
            
        # PRIORITY 3: TRUSTED (Optional)
        elif reputation > 0.7:
            status = "TRUSTED"
            ui_props = {
                "icon": "🔵",
                "color": "#2196F3",
                "background": "#E3F2FD",
                "label": "Trusted Account",
                "can_proceed": True,
                "action": "ALLOW",
                "message": "Safe account with good history."
            }
            risk_level = "Low"
            risk_score = 20
            
        # PRIORITY 4: UNKNOWN (Default)
        else:
            status = "UNKNOWN"
            ui_props = {
                "icon": "🟠",
                "color": "#FF9800",
                "background": "#FFF3E0",
                "label": "Unverified Account",
                "can_proceed": True,
                "action": "WARNING",
                "warning": "⚠️ First time paying this receiver.",
                "recommendation": "💡 Verify details carefully."
            }
            risk_level = "Medium"
            risk_score = 45

        # 5. Build Professional Response
        return {
            "status": status,
            "vpa": vpa,
            "name": name,
            "bank": bank_name,
            "verified": verified,
            "reputation_score": reputation,
            
            # UI Rendering Fields
            "icon": ui_props["icon"],
            "color": ui_props["color"],
            "background": ui_props["background"],
            "label": ui_props["label"],
            "can_proceed": ui_props["can_proceed"],
            "action": ui_props["action"],
            "message": ui_props.get("message"),
            "warning": ui_props.get("warning"),
            "recommendation": ui_props.get("recommendation"),
            
            # Legacy/Intelligence Fields
            "risk_score": risk_score,
            "risk_level": risk_level,
            "risk_factors": [ui_props["label"]],
            "micro_tip": ui_props.get("warning") or ui_props.get("message"),
            
            "metadata": {
                "account_age_days": account_age,
                "is_merchant": is_merchant,
                "fraud_reports": fraud_reports
            }
        }

    def _is_valid_upi_format(self, vpa: str) -> bool:
        import re
        pattern = r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+$'
        return bool(re.match(pattern, vpa))

    def _build_error_response(self, vpa, error_msg):
        return {
            "status": "error",
            "vpa": vpa,
            "name": "Unknown",
            "bank": None,
            "verified": False,
            "reputation_score": 0.0,
            "risk_score": 0,
            "risk_level": "Unknown",
            "risk_factors": ["Invalid Format"],
            "micro_tip": error_msg,
            "error": error_msg
        }

    def add_test_user(self, vpa: str, name: str, bank: str, **kwargs):
        self.MOCK_USERS[vpa] = {
            "name": name,
            "reputation_score": kwargs.get("reputation_score", 0.5),
            "account_age_days": kwargs.get("account_age_days", 100),
            "verified": kwargs.get("verified", True)
        }
        return f"✅ Added {vpa}"

mock_upi_service = MockUPIService()
