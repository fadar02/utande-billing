import json
import os
import re
import math
from datetime import datetime, timedelta
from typing import Dict, List, Optional

class ScreenUnderstanding:
    """Analyze shared screen content, errors, and provide guidance."""

    def is_screen_request(self, text: str) -> bool:
        keywords = ['screen', 'screenshot', 'error on screen', 'what do you see', 'explain this screen',
                     'guide me', 'walk me through', 'how to use', 'screen share']
        return any(kw in text.lower() for kw in keywords)

    def handle(self, text: str) -> str:
        return ("**Screen Understanding** is available when you share a screenshot or describe what's on screen.\n\n"
                "I can help with:\n"
                "- 🐛 **Bug Detection** - Identify errors and suggest fixes\n"
                "- 📖 **Software Guidance** - Walk you through UI steps\n"
                "- 🔍 **Code Analysis** - Explain code visible on screen\n"
                "- ⚠️ **Error Diagnosis** - Read error messages and provide solutions\n"
                "- 💡 **UI/UX Feedback** - Suggest improvements\n\n"
                "To use: describe what you see or paste the error message.")


class EmotionDetection:
    """Detect user emotion from text and adjust responses."""

    EMOTION_PATTERNS = {
        "frustrated": ["frustrated", "annoying", "doesn't work", "broken", "hate", "stupid", "useless",
                       "keeps failing", "not working", "why isn't", "ugh", "argh", "so annoying"],
        "confused": ["confused", "don't understand", "unclear", "what do you mean", "how does",
                     "can you explain", "i'm lost", "doesn't make sense", "bewildered"],
        "happy": ["happy", "great", "awesome", "amazing", "love it", "perfect", "excellent",
                  "wonderful", "fantastic", "thank you", "thanks", "brilliant"],
        "excited": ["excited", "can't wait", "this is going to be", "amazing", "incredible",
                    "wow", "unbelievable", "thrilled"],
        "anxious": ["worried", "anxious", "nervous", "concerned", "what if", " scared",
                    "afraid", "fear", "panicking"],
        "sad": ["sad", "disappointed", "unfortunately", "wish", "sorry to hear", "depressed",
                "down", "upset", "heartbroken"],
        "neutral": []
    }

    ADJUSTMENTS = {
        "frustrated": "I understand this is frustrating. Let me help you work through this step by step. ",
        "confused": "Let me clarify this for you. ",
        "happy": "I'm glad you're happy! ",
        "excited": "That's exciting! ",
        "anxious": "Don't worry, we'll figure this out together. ",
        "sad": "I'm sorry to hear that. Let me help. ",
        "neutral": ""
    }

    def detect(self, text: str) -> str:
        text_lower = text.lower()
        scores = {}
        for emotion, patterns in self.EMOTION_PATTERNS.items():
            score = sum(1 for p in patterns if p in text_lower)
            if score > 0:
                scores[emotion] = score
        if scores:
            return max(scores, key=scores.get)
        return "neutral"

    def get_adjustment(self, text: str) -> str:
        emotion = self.detect(text)
        return self.ADJUSTMENTS.get(emotion, "")

    def get_emotion_report(self, text: str) -> str:
        emotion = self.detect(text)
        adjustment = self.ADJUSTMENTS.get(emotion, "")
        return f"Detected emotion: **{emotion.title()}**\nAdjustment: {adjustment if adjustment else 'No adjustment needed'}"


class PredictiveIntelligence:
    """Basic predictive analytics for business metrics."""

    def __init__(self, data_dir: str = ".predictions"):
        self.data_dir = data_dir
        self.history_file = os.path.join(data_dir, "metric_history.json")
        os.makedirs(data_dir, exist_ok=True)

    def _load_history(self) -> dict:
        if os.path.exists(self.history_file):
            with open(self.history_file, 'r') as f:
                return json.load(f)
        return {}

    def _save_history(self, data: dict):
        with open(self.history_file, 'w') as f:
            json.dump(data, f, indent=2, default=str)

    def is_predictive_request(self, text: str) -> bool:
        keywords = ['predict', 'forecast', 'trend', 'projection', 'estimate',
                     'will sales', 'future', 'expect', 'outlook', 'analytics']
        return any(kw in text.lower() for kw in keywords)

    def handle(self, text: str) -> str:
        text_lower = text.lower()
        if any(w in text_lower for w in ['sales', 'revenue']):
            return self._predict_sales()
        if any(w in text_lower for w in ['customer', 'churn']):
            return self._predict_churn()
        if any(w in text_lower for w in ['inventory', 'stock']):
            return self._predict_inventory()
        return self._general_predictions()

    def _predict_sales(self) -> str:
        history = self._load_history()
        sales = history.get("sales", [])
        if len(sales) < 2:
            return ("**Sales Prediction:**\n\n"
                    "Not enough historical data yet. Start tracking sales data "
                    "with 'record sales: 1000' and I'll build predictions.\n\n"
                    "I can predict:\n"
                    "- Monthly revenue trends\n"
                    "- Seasonal patterns\n"
                    "- Growth rate projections\n"
                    "- Best/worst performing periods")

        values = [s.get("value", 0) for s in sales[-12:]]
        avg = sum(values) / len(values)
        trend = (values[-1] - values[0]) / max(len(values), 1)
        predicted_next = values[-1] + trend

        return (f"**Sales Prediction:**\n\n"
                f"- Average: ${avg:,.2f}\n"
                f"- Trend: {'📈 Growing' if trend > 0 else '📉 Declining'} "
                f"(${abs(trend):,.2f}/period)\n"
                f"- Next period estimate: ${predicted_next:,.2f}\n"
                f"- Data points: {len(sales)}\n\n"
                "Record more data for better accuracy.")

    def _predict_churn(self) -> str:
        return ("**Customer Churn Prediction:**\n\n"
                "Factors I monitor:\n"
                "- Usage frequency decline\n"
                "- Support ticket volume\n"
                "- Payment delays\n"
                "- Feature adoption rate\n\n"
                "Not enough customer data yet. Track interactions to enable predictions.")

    def _predict_inventory(self) -> str:
        return ("**Inventory Prediction:**\n\n"
                "I can forecast:\n"
                "- Stock depletion rates\n"
                "- Reorder timing\n"
                "- Demand spikes\n"
                "- Supplier lead times\n\n"
                "Record inventory data to enable predictions.")

    def _general_predictions(self) -> str:
        return ("**Predictive Intelligence Dashboard:**\n\n"
                "Available predictions:\n"
                "📈 **Sales** - Revenue trends & forecasts\n"
                "👥 **Customer Churn** - Attrition risk analysis\n"
                "📦 **Inventory** - Stock & demand forecasting\n"
                "💰 **Cash Flow** - Financial projections\n"
                "📊 **Growth** - Business expansion trends\n\n"
                "Say 'predict sales' or 'forecast revenue' to get started.\n"
                "Record data first: 'record sales: 5000'")

    def record_metric(self, metric_type: str, value: float, details: str = ""):
        history = self._load_history()
        if metric_type not in history:
            history[metric_type] = []
        history[metric_type].append({
            "value": value,
            "details": details,
            "timestamp": datetime.now().isoformat()
        })
        self._save_history(history)


class AIResearchMode:
    """Simulated AI research that compiles information."""

    def is_research_request(self, text: str) -> bool:
        keywords = ['research', 'deep dive', 'comprehensive', 'detailed report',
                     'investigate', 'analyze thoroughly', 'academic', 'literature review']
        return any(kw in text.lower() for kw in keywords)

    def handle(self, text: str) -> str:
        topic = re.sub(r'(?i)(research|investigate|analyze|deep dive on|comprehensive)\s*', '', text).strip()
        return (f"**AI Research Mode: {topic.title()}**\n\n"
                "I can compile a research report from multiple sources.\n\n"
                "**Research Process:**\n"
                "1. Scan 100+ relevant sources\n"
                "2. Extract key findings\n"
                "3. Cross-reference information\n"
                "4. Identify trends and patterns\n"
                "5. Compile structured report\n\n"
                "**Report Sections:**\n"
                "- Executive Summary\n"
                "- Key Findings\n"
                "- Data Analysis\n"
                "- Expert Opinions\n"
                "- Recommendations\n"
                "- Sources & Citations\n\n"
                "For comprehensive research, I recommend:\n"
                "- Use web search for current data\n"
                "- Upload academic papers for analysis\n"
                "- Check the knowledge base for existing research\n\n"
                "Would you like me to start with a specific angle?")
