import sys
import os
import re
from typing import Optional

from math_module import MathCalculator
from qa_module import QAModule
from recommendation_engine import RecommendationEngine
from code_generator import CodeGenerator
from opencode_features import OpenCodeFeatures
from memory_system import MemorySystem
from agent_system import MultiAgentSystem
from reasoning_engine import ReasoningEngine
from personal_assistant import PersonalAssistant
from knowledge_base import KnowledgeBase
from security_system import SecuritySystem
from plugin_system import PluginSystem
from file_processors import FileProcessor
from voice_module import VoiceAssistant
from workflow_automation import WorkflowAutomation
from advanced_features import ScreenUnderstanding, EmotionDetection, PredictiveIntelligence, AIResearchMode
from business_suite import InvoiceManager
from support_tickets import SupportManager
from proposals import ProposalManager
from hr_manager import HRManager
from reports import ReportManager


class ChatBot:
    """Full-featured AI chatbot with 30+ capabilities."""

    def __init__(self):
        self.math = MathCalculator()
        self.qa = QAModule()
        self.recommender = RecommendationEngine()
        self.code_gen = CodeGenerator()
        self.opencode = OpenCodeFeatures()
        self.memory = MemorySystem()
        self.agents = MultiAgentSystem()
        self.reasoning = ReasoningEngine(verbose=False)
        self.assistant = PersonalAssistant()
        self.knowledge = KnowledgeBase()
        self.security = SecuritySystem()
        self.plugins = PluginSystem()
        self.file_processor = FileProcessor()
        self.voice = VoiceAssistant()
        self.workflows = WorkflowAutomation()
        self.screen = ScreenUnderstanding()
        self.emotion = EmotionDetection()
        self.predictions = PredictiveIntelligence()
        self.research = AIResearchMode()
        self.invoices = InvoiceManager()
        self.support = SupportManager()
        self.proposals = ProposalManager()
        self.hr = HRManager()
        self.reports = ReportManager()
        self.conversation_history = []
        self.context = {}
        self.current_user = "user"

    def greet(self) -> str:
        return """
╔══════════════════════════════════════════════════════════════╗
║                  Welcome to KaStart AI Assistant!              ║
╠══════════════════════════════════════════════════════════════╣
║  30+ Capabilities at your service:                          ║
║                                                             ║
║  🧠 INTELLIGENCE:                                           ║
║  • Multi-Agent System (CEO, Programmer, Accountant, etc.)   ║
║  • AI Reasoning Engine (step-by-step thinking)              ║
║  • Long-Term Memory (remembers everything)                  ║
║  • Knowledge Base (RAG for your documents)                  ║
║                                                             ║
║  💻 DEVELOPMENT:                                            ║
║  • Math calculations & code generation                      ║
║  • Website & mobile app creation                            ║
║  • File operations, code search, git, web fetch             ║
║  • Debug, refactor, code explanation                        ║
║                                                             ║
║  📋 PRODUCTIVITY:                                           ║
║  • Tasks, notes, calendar, reminders, goals                 ║
║  • Shopping lists, budgets, workflow automation              ║
║  • Email drafts, reports, research                          ║
║                                                             ║
║  🔧 SYSTEM:                                                 ║
║  • File processing (PDF, images, data analysis)             ║
║  • Voice assistant, screen understanding                    ║
║  • Security (roles, API keys, audit logs)                   ║
║  • Plugin system, predictive intelligence                   ║
║                                                             ║
║  Type 'help' for all commands | Type 'agents' for AI team  ║
║  Type 'quit' to exit                                        ║
╚══════════════════════════════════════════════════════════════╝
        """

    def process_input(self, user_input: str) -> str:
        if not user_input.strip():
            return "Please say something! I'm here to help."

        self.conversation_history.append({"role": "user", "content": user_input})
        text_lower = user_input.lower().strip()

        if text_lower in ['help', 'commands', '?']:
            return self.show_help()
        if text_lower in ['quit', 'exit', 'bye', 'goodbye', 'q']:
            return self.goodbye()
        if text_lower in ['history', 'chat history', 'show history']:
            return self.show_history()
        if text_lower in ['clear', 'reset', 'clear history']:
            return self.clear_history()
        if text_lower in ['agents', 'team', 'show agents', 'ai team']:
            return self.agents.get_available_agents()
        if text_lower in ['plugins', 'show plugins', 'list plugins']:
            return self.plugins.list_plugins()
        if text_lower in ['reasoning', 'reasoning engine', 'think']:
            return self.reasoning.explain_reasoning()
        if text_lower in ['voice status', 'voice']:
            return self.voice.voice_status()
        if text_lower in ['status', 'system status', 'capabilities']:
            return self._system_status()

        emotion_adj = self.emotion.get_adjustment(user_input)

        if self.memory.find_similar_correction(user_input):
            return emotion_adj + self.memory.find_similar_correction(user_input)

        if text_lower.startswith('ask ') or text_lower.startswith('talk to ') or text_lower.startswith('use agent'):
            response = self._handle_agent_request(user_input)
            self._save_response(response)
            return response

        if text_lower.startswith('reason') or text_lower.startswith('think about') or text_lower.startswith('analyze'):
            query = re.sub(r'(?i)^(reason|think about|analyze)\s*:?\s*', '', user_input)
            trace = self.reasoning.reason(query, self.memory.get_context_summary())
            response = trace + "Based on my analysis, here's what I think:\n\n" + self._simple_response(query)
            self._save_response(response)
            return emotion_adj + response

        if self.assistant.is_assistant_request(user_input):
            response = self.assistant.handle(user_input)
            self._save_response(response)
            return response

        if self.knowledge.is_knowledge_request(user_input):
            response = self.knowledge.handle(user_input)
            self._save_response(response)
            return response

        if self.invoices.is_invoice_request(user_input):
            response = self.invoices.handle(user_input)
            self._save_response(response)
            return response

        if self.support.is_support_request(user_input):
            response = self.support.handle(user_input)
            self._save_response(response)
            return response

        if self.proposals.is_proposal_request(user_input):
            response = self.proposals.handle(user_input)
            self._save_response(response)
            return response

        if self.hr.is_hr_request(user_input):
            response = self.hr.handle(user_input)
            self._save_response(response)
            return response

        if self.reports.is_report_request(user_input):
            response = self.reports.handle(user_input)
            self._save_response(response)
            return response

        if self.plugins.is_plugin_request(user_input):
            response = self.plugins.handle(user_input)
            self._save_response(response)
            return response

        if self.file_processor.is_file_request(user_input):
            response = self.file_processor.handle(user_input)
            self._save_response(response)
            return response

        if self.voice.is_voice_request(user_input):
            response = self.voice.handle(user_input)
            self._save_response(response)
            return response

        if self.screen.is_screen_request(user_input):
            response = self.screen.handle(user_input)
            self._save_response(response)
            return response

        if self.predictions.is_predictive_request(user_input):
            response = self.predictions.handle(user_input)
            self._save_response(response)
            return response

        if self.research.is_research_request(user_input):
            response = self.research.handle(user_input)
            self._save_response(response)
            return response

        if self.workflows.is_workflow_request(user_input):
            response = self.workflows.handle(user_input)
            self._save_response(response)
            return response

        if self.security.is_security_request(user_input):
            response = self.security.handle(user_input, self.current_user)
            self._save_response(response)
            return response

        if self.math.is_math_expression(user_input):
            result = self.math.calculate(user_input)
            if result is not None:
                formatted = self.math.format_result(result)
                response = f"The result of your calculation is: **{formatted}**"
                self._save_response(response)
                return response

        if self.recommender.is_recommendation_request(user_input):
            response = self.recommender.get_recommendations(user_input)
            self._save_response(response)
            return response

        if self.opencode.is_opencode_request(user_input):
            operation, details = self.opencode.detect_operation(user_input)
            response = self.opencode.execute(operation, details)
            self._save_response(response)
            return response

        if self.code_gen.is_code_request(user_input):
            response = self.code_gen.generate(user_input)
            self._save_response(response)
            return response

        qa_response = self.qa.answer(user_input)
        if qa_response:
            self._save_response(qa_response)
            return emotion_adj + qa_response

        response = self._simple_response(user_input)
        self._save_response(response)
        return emotion_adj + response

    def _handle_agent_request(self, text: str) -> str:
        text_lower = text.lower()
        agent_map = {
            'ceo': 'ceo', 'strategy': 'ceo', 'business': 'ceo',
            'programmer': 'programmer', 'developer': 'programmer', 'coding': 'programmer', 'code': 'programmer',
            'accountant': 'accountant', 'finance': 'accountant', 'money': 'accountant',
            'lawyer': 'lawyer', 'legal': 'lawyer',
            'medical': 'medical', 'health': 'medical', 'doctor': 'medical',
            'hr': 'hr', 'human resource': 'hr', 'hiring': 'hr',
            'marketing': 'marketing', 'growth': 'marketing',
            'security': 'security', 'cyber': 'security',
        }
        for keyword, agent_key in agent_map.items():
            if keyword in text_lower:
                query = re.sub(r'(?i)(ask|talk to|use agent|the)\s*', '', text)
                query = re.sub(r'(?i)\b' + keyword + r'\b\s*', '', query).strip()
                return self.agents.ask_agent(agent_key, query or text, self.memory.get_context_summary())
        return self.agents.delegate(text, self.memory.get_context_summary())

    def _simple_response(self, user_input: str) -> str:
        text_lower = user_input.lower()
        if any(w in text_lower for w in ['yes', 'yeah', 'yep', 'sure', 'ok', 'okay']):
            return "Great! Is there anything else you'd like help with?"
        if any(w in text_lower for w in ['no', 'nah', 'nope', 'not really']):
            return "Alright! Let me know if you need anything else."
        if any(w in text_lower for w in ['sorry', 'apologize', 'my bad']):
            return "No worries at all! How can I help?"
        if any(w in text_lower for w in ['thank', 'thanks']):
            return "You're welcome! Happy to help."
        if len(user_input.split()) <= 2:
            return ("I can help with many things! Try:\n"
                    "- Ask a question\n- Math calculations\n- Create websites/apps\n"
                    "- Manage tasks & notes\n- Talk to an AI agent\n- Get recommendations\n"
                    "- Type 'help' for all commands")
        return ("I'm not sure about that. Try:\n"
                "- 'help' for all commands\n"
                "- 'agents' to meet the AI team\n"
                "- Ask a specific question\n"
                "- Describe what you need")

    def _save_response(self, response: str):
        self.conversation_history.append({"role": "assistant", "content": response})
        self.memory.save_conversation("default", [
            {"role": "user", "content": self.conversation_history[-2]["content"]},
            {"role": "assistant", "content": response}
        ], "general")

    def _system_status(self) -> str:
        return (f"**System Status:**\n\n"
                f"🧠 Memory: {len(self.memory.get_all_preferences())} preference categories stored\n"
                f"🤖 Agents: {len(self.agents.agents)} specialized agents\n"
                f"📋 Tasks: Active\n"
                f"📚 Knowledge Base: Active\n"
                f"🔒 Security: Active\n"
                f"🔌 Plugins: Active\n"
                f"⚡ Workflows: Active\n"
                f"💬 Conversation: {len(self.conversation_history)} messages\n"
                f"😊 Emotion Detection: Active\n"
                f"🔮 Predictive Intel: Active\n"
                f"🎤 Voice: {self.voice.voice_status()[:50]}")

    def show_help(self) -> str:
        return """
╔══════════════════════════════════════════════════════════════╗
║                    KaStart AI - Full Commands                  ║
╠══════════════════════════════════════════════════════════════╣
║                                                             ║
║  🧠 AI TEAM:                                                ║
║  • "Ask the CEO about strategy"                            ║
║  • "Talk to the programmer about Python"                   ║
║  • "Use the accountant for budgeting"                      ║
║  • "Ask the lawyer about contracts"                        ║
║                                                             ║
║  📋 PERSONAL ASSISTANT:                                     ║
║  • "Add task: Finish report by Friday"                     ║
║  • "Add note: Important meeting notes"                     ║
║  • "Set reminder: Call John at 3 PM"                       ║
║  • "Show tasks / notes / calendar / goals"                 ║
║                                                             ║
║  💻 DEVELOPMENT:                                            ║
║  • Math: "calculate 2+2*3", "sqrt(144)"                    ║
║  • Websites: "Create a landing page"                       ║
║  • Files: "Create/read/edit/list files"                    ║
║  • Git: "Git status/diff/log/commit"                       ║
║                                                             ║
║  💼 INVOICING:                                              ║
║  • "Add invoice: Acme Corp, $1500, 2026-02-15, Web"        ║
║  • "List invoices" / "Show pending" / "Show overdue"       ║
║  • "Mark invoice INV-0001 paid"                            ║
║  • "Revenue report"                                        ║
║                                                             ║
║  🎫 SUPPORT:                                                ║
║  • "Add ticket: John, Login issue, high"                   ║
║  • "List tickets" / "Close ticket TKT-0001"                ║
║  • "Add FAQ: Hours? -> We are open 9-5"                    ║
║                                                             ║
║  📄 PROPOSALS:                                              ║
║  • "Generate proposal: Acme, Website, $5000, 2 months"     ║
║  • "Generate quote: John, Logo design, $800"               ║
║  • "List proposals" / "List quotes"                        ║
║                                                             ║
║  👥 HR:                                                     ║
║  • "Add employee: John, Dev, Eng, 2026-01-15, $75000"      ║
║  • "List employees" / "Show team"                          ║
║  • "Request leave: John, Vacation, 2026-03-01, 2026-03-05" ║
║  • "Approve leave LV-0001"                                 ║
║                                                             ║
║  📊 REPORTS:                                                ║
║  • "Revenue report" / "Client summary"                     ║
║  • "Employee report" / "Support report"                    ║
║  • "Monthly report" / "Dashboard"                          ║
║                                                             ║
║  🎯 QUICK COMMANDS:                                         ║
║  • agents, plugins, reasoning, voice, status               ║
║  • history, clear, help, quit                              ║
╚══════════════════════════════════════════════════════════════╝
        """

    def show_history(self) -> str:
        if not self.conversation_history:
            return "No conversation history yet."
        history = "**Conversation History:**\n\n"
        for i, msg in enumerate(self.conversation_history[-20:], 1):
            role = "You" if msg["role"] == "user" else "KaStart"
            content = msg["content"][:80] + "..." if len(msg["content"]) > 80 else msg["content"]
            history += f"{i}. [{role}]: {content}\n"
        return history

    def clear_history(self) -> str:
        self.conversation_history = []
        return "Conversation history cleared!"

    def goodbye(self) -> str:
        self.memory.save_conversation("default", self.conversation_history[-10:], "final_session")
        return "Goodbye! Your session has been saved. See you next time! 👋"

    def run(self):
        print(self.greet())
        while True:
            try:
                user_input = input("\nYou: ").strip()
                if not user_input:
                    continue
                if user_input.lower() in ['quit', 'exit', 'bye', 'goodbye', 'q']:
                    print(f"\nKaStart: {self.goodbye()}")
                    break
                response = self.process_input(user_input)
                print(f"\nKaStart: {response}")
            except KeyboardInterrupt:
                print(f"\n\n{self.goodbye()}")
                break
            except Exception as e:
                print(f"\nKaStart: I encountered an error: {str(e)}")


def main():
    bot = ChatBot()
    if len(sys.argv) > 1:
        user_input = ' '.join(sys.argv[1:])
        response = bot.process_input(user_input)
        print(f"KaStart: {response}")
    else:
        bot.run()


if __name__ == "__main__":
    main()
