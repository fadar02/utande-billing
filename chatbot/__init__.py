from .chatbot import ChatBot
from .math_module import MathCalculator
from .qa_module import QAModule
from .recommendation_engine import RecommendationEngine
from .code_generator import CodeGenerator
from .opencode_features import OpenCodeFeatures
from .memory_system import MemorySystem
from .agent_system import MultiAgentSystem
from .reasoning_engine import ReasoningEngine
from .personal_assistant import PersonalAssistant
from .knowledge_base import KnowledgeBase
from .security_system import SecuritySystem
from .plugin_system import PluginSystem
from .file_processors import FileProcessor
from .voice_module import VoiceAssistant
from .workflow_automation import WorkflowAutomation
from .advanced_features import ScreenUnderstanding, EmotionDetection, PredictiveIntelligence, AIResearchMode

__version__ = "2.0.0"
__all__ = [
    "ChatBot", "MathCalculator", "QAModule", "RecommendationEngine",
    "CodeGenerator", "OpenCodeFeatures", "MemorySystem", "MultiAgentSystem",
    "ReasoningEngine", "PersonalAssistant", "KnowledgeBase", "SecuritySystem",
    "PluginSystem", "FileProcessor", "VoiceAssistant", "WorkflowAutomation",
    "ScreenUnderstanding", "EmotionDetection", "PredictiveIntelligence", "AIResearchMode"
]
