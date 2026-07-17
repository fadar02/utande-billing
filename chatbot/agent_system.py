import re
from typing import Dict, List, Optional, Tuple
from datetime import datetime

class Agent:
    """Base agent class."""
    def __init__(self, name: str, role: str, expertise: List[str], personality: str):
        self.name = name
        self.role = role
        self.expertise = expertise
        self.personality = personality

    def can_handle(self, query: str) -> float:
        query_lower = query.lower()
        score = 0
        for exp in self.expertise:
            if exp.lower() in query_lower:
                score += 1
        return score / max(len(self.expertise), 1)

    def respond(self, query: str, context: str = "") -> str:
        return f"[{self.name} - {self.role}] Processing: {query}"


class CEOAgent(Agent):
    def __init__(self):
        super().__init__(
            name="Alex", role="CEO & Strategy Advisor",
            expertise=["strategy", "business", "plan", "goal", "vision", "decision", "leadership",
                       "company", "startup", "growth", "revenue", "profit", "stakeholder",
                       "roadmap", "milestone", "pitch", "investor", "funding"],
            personality="Strategic thinker, big picture focused, decisive"
        )

    def respond(self, query: str, context: str = "") -> str:
        query_lower = query.lower()
        if any(w in query_lower for w in ['strategy', 'plan', 'roadmap']):
            return (f"**{self.name} (CEO):**\n\n"
                    "Let me break this down from a strategic perspective:\n\n"
                    "1. **Assess the current situation** - Where are we now?\n"
                    "2. **Define clear objectives** - Where do we need to be?\n"
                    "3. **Identify key resources** - What do we have/need?\n"
                    "4. **Set milestones** - How do we measure progress?\n"
                    "5. **Execute with agility** - Adapt as we learn\n\n"
                    f"Context from memory: {context}\n\n"
                    "What specific aspect would you like to dive deeper into?")
        if any(w in query_lower for w in ['should i', 'decide', 'choice', 'option']):
            return (f"**{self.name} (CEO):**\n\n"
                    "When facing a decision, I recommend:\n"
                    "- **Impact analysis**: What's the upside/downside?\n"
                    "- **Resource check**: Do we have what we need?\n"
                    "- **Alignment check**: Does this match our goals?\n"
                    "- **Risk assessment**: What could go wrong?\n"
                    "- **Opportunity cost**: What are we giving up?\n\n"
                    "Present me with your options and I'll help you evaluate them.")
        return (f"**{self.name} (CEO):**\n\n"
                "I can help with strategic planning, business decisions, and leadership guidance. "
                "What business challenge are you facing?")


class ProgrammerAgent(Agent):
    def __init__(self):
        super().__init__(
            name="KaStart", role="Senior Software Engineer",
            expertise=["code", "programming", "python", "javascript", "java", "csharp", "php",
                       "flutter", "react", "laravel", "debug", "bug", "api", "database",
                       "algorithm", "function", "class", "variable", "array", "loop",
                       "frontend", "backend", "devops", "git", "docker", "linux",
                       "html", "css", "typescript", "node", "django", "fastapi",
                       "software", "developer", "engineer", "compile", "deploy"],
            personality="Methodical problem solver, detail-oriented, loves clean code"
        )

    def respond(self, query: str, context: str = "") -> str:
        query_lower = query.lower()
        if any(w in query_lower for w in ['bug', 'error', 'fix', 'debug', 'not working', 'broken']):
            return (f"**{self.name} (Programmer):**\n\n"
                    "Let's debug this systematically:\n\n"
                    "1. **Reproduce** - Can you consistently trigger the issue?\n"
                    "2. **Isolate** - Which component/module is affected?\n"
                    "3. **Examine** - Check logs, stack traces, recent changes\n"
                    "4. **Hypothesize** - What could cause this?\n"
                    "5. **Test** - Verify each hypothesis\n"
                    "6. **Fix** - Implement the solution\n"
                    "7. **Verify** - Confirm the fix works\n"
                    "8. **Document** - Record what happened and the fix\n\n"
                    "Please share the error message or describe the behavior.")
        if any(w in query_lower for w in ['create', 'build', 'make', 'write', 'generate', 'implement']):
            return (f"**{self.name} (Programmer):**\n\n"
                    "I'll help you build this. Before we start:\n\n"
                    "1. **Requirements** - What exactly should it do?\n"
                    "2. **Tech stack** - What language/framework?\n"
                    "3. **Architecture** - How should it be structured?\n"
                    "4. **Edge cases** - What could go wrong?\n"
                    "5. **Testing** - How do we verify it works?\n\n"
                    "I can generate code in Python, JavaScript, Java, C#, PHP, Flutter, React, "
                    "Laravel, and more. What would you like to build?")
        if any(w in query_lower for w in ['explain', 'what does', 'how does', 'understand']):
            return (f"**{self.name} (Programmer):**\n\n"
                    "I'd be happy to explain! Please share the code or concept you'd like "
                    "to understand, and I'll break it down step by step.")
        return (f"**{self.name} (Programmer):**\n\n"
                "I'm your coding specialist. I can help with:\n"
                "- Writing/debugging code\n"
                "- System architecture\n"
                "- Code review & optimization\n"
                "- Technical documentation\n\n"
                "What coding challenge are you working on?")


class AccountantAgent(Agent):
    def __init__(self):
        super().__init__(
            name="Maya", role="Financial Advisor & Accountant",
            expertise=["money", "budget", "finance", "accounting", "tax", "invoice",
                       "profit", "loss", "revenue", "expense", "cost", "price",
                       "investment", "roi", "cash flow", "balance sheet", "audit",
                       "payment", "billing", "subscription", "salary", "payroll"],
            personality="Numbers-driven, precise, compliance-focused"
        )

    def respond(self, query: str, context: str = "") -> str:
        query_lower = query.lower()
        if any(w in query_lower for w in ['budget', 'plan', 'allocate']):
            return (f"**{self.name} (Accountant):**\n\n"
                    "Let me help with budget planning:\n\n"
                    "📊 **Budget Framework:**\n"
                    "- 50% Needs (rent, utilities, salaries)\n"
                    "- 30% Operations (tools, marketing, growth)\n"
                    "- 20% Savings & Investment\n\n"
                    "Key questions:\n"
                    "1. What's your total monthly revenue?\n"
                    "2. What are your fixed costs?\n"
                    "3. What are variable costs?\n"
                    "4. What are your financial goals?\n\n"
                    "Share your numbers and I'll create a detailed breakdown.")
        if any(w in query_lower for w in ['invoice', 'bill', 'payment']):
            return (f"**{self.name} (Accountant):**\n\n"
                    "For invoicing best practices:\n"
                    "- Include clear payment terms (Net 15/30)\n"
                    "- Add late payment penalties\n"
                    "- Track all invoices systematically\n"
                    "- Follow up on overdue payments\n\n"
                    "Would you like me to help create an invoice or set up a billing system?")
        return (f"**{self.name} (Accountant):**\n\n"
                "I can help with financial planning, budgeting, invoicing, tax preparation, "
                "and financial analysis. What financial matter needs attention?")


class LawyerAgent(Agent):
    def __init__(self):
        super().__init__(
            name="Justice", role="Legal Advisor",
            expertise=["legal", "law", "contract", "agreement", "policy", "compliance",
                       "regulation", "license", "terms", "privacy", "gdpr", "liability",
                       "intellectual property", "trademark", "copyright", "patent",
                       "nda", "nda", "terms of service", "terms and conditions"],
            personality="Thorough, risk-aware, protective of interests"
        )

    def respond(self, query: str, context: str = "") -> str:
        return (f"**{self.name} (Legal):**\n\n"
                "⚠️ *Disclaimer: This is general legal information, not legal advice.*\n\n"
                "I can help with:\n"
                "- Contract review & drafting guidance\n"
                "- Compliance requirements\n"
                "- Privacy policy considerations\n"
                "- Terms of service guidance\n"
                "- Intellectual property basics\n"
                "- Regulatory awareness\n\n"
                "For complex legal matters, always consult a licensed attorney.\n\n"
                "What legal aspect do you need help with?")


class MedicalAgent(Agent):
    def __init__(self):
        super().__init__(
            name="Dr. Sage", role="Health Information Assistant",
            expertise=["health", "medical", "symptom", "disease", "medicine", "treatment",
                       "diagnosis", "doctor", "hospital", "wellness", "fitness", "nutrition",
                       "mental health", "anxiety", "depression", "sleep", "exercise"],
            personality="Caring, evidence-based, safety-first"
        )

    def respond(self, query: str, context: str = "") -> str:
        return (f"**{self.name} (Medical):**\n\n"
                "⚠️ *Important: I provide general health information only, NOT medical advice.*\n\n"
                "For any health concerns:\n"
                "1. Always consult a qualified healthcare professional\n"
                "2. In emergencies, call emergency services immediately\n"
                "3. Don't rely solely on internet information for diagnosis\n\n"
                "I can share general health information and wellness tips.\n"
                "What health topic would you like to learn about?")


class HRAgent(Agent):
    def __init__(self):
        super().__init__(
            name="Harmony", role="Human Resources Specialist",
            expertise=["hiring", "recruit", "employee", "hr", "human resources", "interview",
                       "resume", "onboarding", "performance", "review", "compensation",
                       "benefits", "training", "team", "culture", "conflict", "mediation"],
            personality="People-oriented, fair, culturally aware"
        )

    def respond(self, query: str, context: str = "") -> str:
        return (f"**{self.name} (HR):**\n\n"
                "I can help with:\n"
                "- Recruitment & interview strategies\n"
                "- Employee onboarding processes\n"
                "- Performance review frameworks\n"
                "- Compensation & benefits guidance\n"
                "- Team building & culture development\n"
                "- Conflict resolution approaches\n"
                "- HR policy creation\n\n"
                "What HR challenge are you facing?")


class MarketingAgent(Agent):
    def __init__(self):
        super().__init__(
            name="Spike", role="Marketing & Growth Expert",
            expertise=["marketing", "brand", "seo", "social media", "advertising", "campaign",
                       "content", "audience", "customer", "conversion", "funnel", "growth",
                       "email marketing", "affiliate", "influencer", "viral", "engagement"],
            personality="Creative, data-driven, trend-aware"
        )

    def respond(self, query: str, context: str = "") -> str:
        return (f"**{self.name} (Marketing):**\n\n"
                "🚀 Marketing & Growth insights:\n\n"
                "Key areas I can help with:\n"
                "- **Brand Strategy** - Positioning & messaging\n"
                "- **Content Marketing** - Blog, social, video\n"
                "- **SEO** - Search optimization\n"
                "- **Paid Ads** - ROI-focused campaigns\n"
                "- **Social Media** - Engagement & growth\n"
                "- **Email Marketing** - Automation & sequences\n"
                "- **Analytics** - Metrics that matter\n\n"
                "What marketing goal are you working towards?")


class CyberSecurityAgent(Agent):
    def __init__(self):
        super().__init__(
            name="Cipher", role="Cybersecurity Expert",
            expertise=["security", "hack", "vulnerability", "encryption", "firewall",
                       "password", "authentication", "penetration", "malware", "phishing",
                       "data breach", "ssl", "tls", "vpn", "owasp", "cyber"],
            personality="Vigilant, paranoid (in a good way), security-first"
        )

    def respond(self, query: str, context: str = "") -> str:
        return (f"**{self.name} (Security):**\n\n"
                "🔐 Security Assessment:\n\n"
                "Key security practices:\n"
                "- **Authentication**: Use MFA everywhere\n"
                "- **Encryption**: TLS for data in transit, AES for data at rest\n"
                "- **Passwords**: Minimum 16 chars, unique per service\n"
                "- **Updates**: Patch everything regularly\n"
                "- **Backups**: Follow 3-2-1 rule\n"
                "- **Monitoring**: Log and audit everything\n\n"
                "What security concern do you need addressed?")


class MultiAgentSystem:
    """Master agent that delegates to specialized agents."""

    def __init__(self):
        self.agents = {
            "ceo": CEOAgent(),
            "programmer": ProgrammerAgent(),
            "accountant": AccountantAgent(),
            "lawyer": LawyerAgent(),
            "medical": MedicalAgent(),
            "hr": HRAgent(),
            "marketing": MarketingAgent(),
            "security": CyberSecurityAgent(),
        }
        self.delegation_history = []

    def classify_request(self, query: str) -> List[Tuple[str, float]]:
        scores = []
        for key, agent in self.agents.items():
            score = agent.can_handle(query)
            if score > 0:
                scores.append((key, score))
        scores.sort(key=lambda x: x[1], reverse=True)
        return scores

    def delegate(self, query: str, context: str = "") -> str:
        classifications = self.classify_request(query)

        if not classifications:
            return self._general_response(query, context)

        primary_key, primary_score = classifications[0]
        primary_agent = self.agents[primary_key]

        response = primary_agent.respond(query, context)

        self.delegation_history.append({
            "query": query[:100],
            "delegated_to": primary_agent.name,
            "role": primary_agent.role,
            "confidence": primary_score,
            "timestamp": datetime.now().isoformat()
        })

        return response

    def _general_response(self, query: str, context: str) -> str:
        return (f"I can route this to our specialized team. Available agents:\n\n"
                "🏛️ **CEO (Alex)** - Strategy & business decisions\n"
                "💻 **Programmer (KaStart)** - Coding & technical\n"
                "💰 **Accountant (Maya)** - Finance & accounting\n"
                "⚖️ **Lawyer (Justice)** - Legal guidance\n"
                "🏥 **Medical (Dr. Sage)** - Health information\n"
                "👥 **HR (Harmony)** - People & culture\n"
                "📈 **Marketing (Spike)** - Growth & marketing\n"
                "🔒 **Security (Cipher)** - Cybersecurity\n\n"
                "Try: 'Ask the programmer about Python' or 'Get CEO advice on strategy'")

    def ask_agent(self, agent_key: str, query: str, context: str = "") -> str:
        agent = self.agents.get(agent_key)
        if agent:
            return agent.respond(query, context)
        return f"Agent '{agent_key}' not found. Available: {', '.join(self.agents.keys())}"

    def get_available_agents(self) -> str:
        lines = ["Available Agents:\n"]
        for key, agent in self.agents.items():
            lines.append(f"  **{agent.name}** ({agent.role})")
            lines.append(f"    Expertise: {', '.join(agent.expertise[:5])}...")
            lines.append("")
        return "\n".join(lines)
