import asyncio
from typing import Dict, Optional
from datetime import datetime

class MockUPIService:
    """
    Mock UPI VPA validation service for hackathon demo.
    Simulates NPCI's name inquiry API without needing real integration.
    """
    
    # Mock database of UPI IDs
    # Add more for demo variety
    MOCK_USERS = {
        # Famous people (for fun demos)
        "sachin@paytm": {
            "name": "Sachin Ramesh Tendulkar",
            "bank": "Paytm Payments Bank",
            "verified": True,
            "reputation_score": 0.95,
            "account_age_days": 1825  # 5 years
        },
        "virat@ybl": {
            "name": "Virat Kohli",
            "bank": "YES Bank",
            "verified": True,
            "reputation_score": 0.92,
            "account_age_days": 1460
        },
        "dhoni@okaxis": {
            "name": "Mahendra Singh Dhoni",
            "bank": "Axis Bank",
            "verified": True,
            "reputation_score": 0.98,
            "account_age_days": 2190
        },
        
        # Merchants (for realistic scenarios)
        "swiggy@paytm": {
            "name": "Swiggy Limited",
            "bank": "Paytm Payments Bank",
            "verified": True,
            "reputation_score": 0.99,
            "account_age_days": 2000,
            "is_merchant": True
        },
        "zomato@ybl": {
            "name": "Zomato Media Pvt Ltd",
            "bank": "YES Bank",
            "verified": True,
            "reputation_score": 0.98,
            "account_age_days": 1800,
            "is_merchant": True
        },
        
        # Regular users (for testing)
        "arun@sbi": {
            "name": "Arun Kumar",
            "bank": "State Bank of India",
            "verified": True,
            "reputation_score": 0.85,
            "account_age_days": 730
        },
        "priya@hdfc": {
            "name": "Priya Shah",
            "bank": "HDFC Bank",
            "verified": True,
            "reputation_score": 0.75,
            "account_age_days": 365
        },
        
        # Suspicious accounts (for fraud demo)
        "scammer@paytm": {
            "name": "Suspicious Account",
            "bank": "Unknown Bank",
            "verified": False,
            "reputation_score": 0.15,
            "account_age_days": 10,
            "fraud_reports": 47
        },
        "mule@okaxis": {
            "name": "Money Mule",
            "bank": "Axis Bank",
            "verified": False,
            "reputation_score": 0.08,
            "account_age_days": 5,
            "fraud_reports": 89
        },
        
        # Invalid/Unknown (for error handling demo)
        "invalid@test": {
            "name": None,  # This will show as "Unknown Receiver"
            "bank": None,
            "verified": False,
            "reputation_score": 0.0
        },
         # Specific requests from previous context
        "sachin@sbiok": {
            "name": "Sachin Tendulkar",
            "bank": "State Bank of India",
            "verified": True,
            "reputation_score": 0.95
        },
        "deepblue@upi": {
            "name": "DeepBlue Security",
            "bank": "HDFC Bank",
            "verified": True,
            "reputation_score": 0.99
        },
        "lottery@upi": {
            "name": "Mega Lottery Winner",
            "bank": "Fake Bank Ltd",
            "verified": False,
            "reputation_score": 0.1
        }
    }
    
    async def validate_vpa(self, vpa: str) -> Dict:
        """
        Validate UPI Virtual Payment Address
        
        Args:
            vpa: UPI ID like "sachin@paytm"
        
        Returns:
            {
                "vpa": "sachin@paytm",
                "name": "Sachin Ramesh Tendulkar",
                "bank": "Paytm Payments Bank",
                "verified": True,
                "reputation_score": 0.95,
                "metadata": {...}
            }
        """
        
        # Simulate network delay (realistic feel)
        await asyncio.sleep(0.3)  # 300ms delay
        
        # Clean input
        vpa_clean = vpa.lower().strip()
        
        # Validate UPI format
        if not self._is_valid_upi_format(vpa_clean):
            return {
                "status": "error",
                "vpa": vpa,
                "name": None,
                "bank": None,
                "verified": False,
                "error": "Invalid UPI ID format",
                "error_code": "INVALID_FORMAT"
            }
        
        # Check if VPA exists in our mock database
        if vpa_clean in self.MOCK_USERS:
            user = self.MOCK_USERS[vpa_clean]
            
            # If name is None, it's an unknown receiver
            if user["name"] is None:
                return {
                    "status": "not_found",
                    "vpa": vpa,
                    "name": "Unknown Receiver",
                    "bank": None,
                    "verified": False,
                    "error": "VPA not found in system",
                    "error_code": "VPA_NOT_FOUND"
                }
            
            # Return success with full details
            return {
                "status": "success",
                "vpa": vpa,
                "name": user["name"],
                "bank": user["bank"],
                "verified": user.get("verified", False),
                "reputation_score": user.get("reputation_score", 0.5),
                "metadata": {
                    "is_merchant": user.get("is_merchant", False),
                    "account_age_days": user.get("account_age_days", 0),
                    "fraud_reports": user.get("fraud_reports", 0),
                    "last_checked": datetime.utcnow().isoformat()
                }
            }
        else:
            # VPA not in database - return as unknown
            return {
                "status": "not_found",
                "vpa": vpa,
                "name": "Unknown Receiver",
                "bank": None,
                "verified": False,
                "error": "VPA not registered",
                "error_code": "VPA_NOT_FOUND",
                "suggestion": f"Please verify the UPI ID: {vpa}"
            }
    
    def _is_valid_upi_format(self, vpa: str) -> bool:
        """
        Validate UPI format: username@bank
        """
        import re
        # Pattern: alphanumeric + dots/underscores + @ + alphanumeric
        pattern = r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+$'
        return bool(re.match(pattern, vpa))
    
    def add_test_user(self, vpa: str, name: str, bank: str, **kwargs):
        """
        Add a test user dynamically (useful during hackathon demo)
        """
        self.MOCK_USERS[vpa] = {
            "name": name,
            "bank": bank,
            "verified": kwargs.get("verified", True),
            "reputation_score": kwargs.get("reputation_score", 0.5),
            "account_age_days": kwargs.get("account_age_days", 100)
        }
        return f"✅ Added {vpa} to mock database"


# Create singleton instance
mock_upi_service = MockUPIService()
