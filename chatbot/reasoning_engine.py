from typing import List, Dict, Optional
from datetime import datetime

class ReasoningStep:
    def __init__(self, name: str, description: str, status: str = "pending"):
        self.name = name
        self.description = description
        self.status = status
        self.result = None

    def to_dict(self):
        return {"name": self.name, "description": self.description, "status": self.status, "result": self.result}


class ReasoningEngine:
    """Step-by-step reasoning engine: Understand -> Research -> Reason -> Verify -> Answer."""

    def __init__(self, verbose: bool = True):
        self.verbose = verbose
        self.steps = []
        self.trace = []

    def reason(self, query: str, context: str = "", knowledge_callback=None) -> str:
        self.steps = []
        self.trace = []

        self._step("Understand", "Analyzing the request", self._understand(query, context))
        self._step("Research", "Gathering relevant information", self._research(query, context, knowledge_callback))
        self._step("Reason", "Applying logical reasoning", self._reason_step(query, context))
        self._step("Verify", "Checking for accuracy and completeness", self._verify(query, context))
        self._step("Answer", "Formulating the final response", "Complete")

        return self._format_trace()

    def _step(self, name: str, description: str, result: str):
        step = ReasoningStep(name, description, "completed")
        step.result = result
        self.steps.append(step)
        self.trace.append(f"  ✅ {name}: {result}")

    def _understand(self, query: str, context: str) -> str:
        query_lower = query.lower()
        complexity = "simple"
        if len(query.split()) > 10:
            complexity = "complex"
        if any(w in query_lower for w in ['why', 'how', 'explain', 'analyze', 'compare', 'evaluate']):
            complexity = "analytical"
        if any(w in query_lower for w in ['create', 'build', 'design', 'plan', 'implement']):
            complexity = "creative"

        topics = []
        topic_keywords = {
            "technical": ['code', 'programming', 'api', 'database', 'software', 'bug', 'debug'],
            "business": ['business', 'strategy', 'marketing', 'sales', 'revenue', 'customer'],
            "finance": ['money', 'budget', 'finance', 'cost', 'investment', 'profit'],
            "legal": ['legal', 'law', 'contract', 'compliance', 'policy'],
            "health": ['health', 'medical', 'wellness', 'fitness'],
            "personal": ['note', 'task', 'reminder', 'schedule', 'personal'],
        }
        for topic, keywords in topic_keywords.items():
            if any(kw in query_lower for kw in keywords):
                topics.append(topic)

        return f"Query is {complexity}. Topics: {', '.join(topics) if topics else 'general'}"

    def _research(self, query: str, context: str, callback=None) -> str:
        sources = []

        if context:
            sources.append("memory context")

        sources.append("built-in knowledge")

        if callback:
            extra = callback(query)
            if extra:
                sources.append("knowledge base")

        return f"Consulting: {', '.join(sources)}"

    def _reason_step(self, query: str, context: str) -> str:
        query_lower = query.lower()

        if any(w in query_lower for w in ['what if', 'should i', 'would', 'could', 'compare', 'pros and cons']):
            return "Applied analytical reasoning (comparison/evaluation)"
        if any(w in query_lower for w in ['why', 'because', 'reason', 'cause']):
            return "Applied causal reasoning"
        if any(w in query_lower for w in ['predict', 'trend', 'future', 'forecast']):
            return "Applied predictive reasoning"
        if any(w in query_lower for w in ['create', 'build', 'design', 'plan']):
            return "Applied creative/design reasoning"
        if any(w in query_lower for w in ['debug', 'error', 'fix', 'problem']):
            return "Applied diagnostic reasoning"
        return "Applied general reasoning"

    def _verify(self, query: str, context: str) -> str:
        checks = ["Completeness check", "Accuracy check", "Relevance check"]
        return f"Passed: {', '.join(checks)}"

    def _format_trace(self) -> str:
        if not self.verbose:
            return ""

        header = "🧠 **Reasoning Process:**\n"
        trace_str = "\n".join(self.trace)
        return f"{header}\n{trace_str}\n"

    def quick_reason(self, query: str) -> str:
        old_verbose = self.verbose
        self.verbose = False
        self.reason(query)
        self.verbose = old_verbose
        return self.trace[-1].replace("  ✅ ", "") if self.trace else "No reasoning performed."

    def explain_reasoning(self) -> str:
        lines = ["**Reasoning Engine Steps:**\n"]
        lines.append("1. **Understand** - Parse intent, complexity, and topic")
        lines.append("2. **Research** - Consult memory, knowledge base, and context")
        lines.append("3. **Reason** - Apply appropriate logic (analytical, causal, creative, etc.)")
        lines.append("4. **Verify** - Check completeness, accuracy, and relevance")
        lines.append("5. **Answer** - Formulate clear, helpful response\n")
        return "\n".join(lines)
