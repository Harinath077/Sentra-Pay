"""
Gemini Banana - GenAI Engine 🍌
Provides natural language explanations and visual reasoning for fraud decisions.
"""

import logging
import random

logger = logging.getLogger(__name__)

class GenAIEngine:
    """
    Simulates Google Gemini (Nano/Pro) for fraud explanation.
    In a real deployment, this would call the Vertex AI or Gemini API.
    """
    
    def __init__(self):
        self.model_name = "gemini-1.5-pro-preview"
        logger.info(f"🍌 GenAI Engine initialized: {self.model_name}")

    def generate_explanation(self, risk_score: float, flags: list, receiver: str) -> dict:
        """
        Generate a human-readable explanation for the risk score.
        """
        explanation = ""
        visual_reasoning = ""
        
        if risk_score > 0.8:
            explanation = (
                f"**Gemini Analysis:** 🚨 High Risk Detected. "
                f"The receiver '{receiver}' matches patterns associated with known fraud rings. "
                "Behavioral analysis indicates this transaction significantly deviates from your usual spending habits."
            )
            visual_reasoning = "Graph: [Your Wallet] --(Unusual High Amount)--> [Unknown Receiver ⚠️] --(Fast Cash Out)--> [Mule Account]"
            
        elif risk_score > 0.5:
            explanation = (
                f"**Gemini Analysis:** ⚠️ Moderate Risk. "
                f"You have never transferred money to '{receiver}' before, and the amount is higher than average. "
                "We recommend verbal verification before proceeding."
            )
            visual_reasoning = "Graph: [Your Wallet] --(New Connection)--> [New Receiver] (No mutual history)"
            
        else:
            explanation = (
                f"**Gemini Analysis:** ✅ Safe Transaction. "
                f"Transfer to '{receiver}' appears normal based on your history and network analysis."
            )
            visual_reasoning = "Graph: [Your Wallet] --(Trusted Path)--> [Receiver]"

        return {
            "ai_explanation": explanation,
            "visual_reasoning": visual_reasoning,
            "model_used": self.model_name
        }

# Global instance
genai = GenAIEngine()
