# KaStart AI Assistant

An AI-powered business assistant for small and medium enterprises (SMEs).

## Features

**Business Suite:**
- Invoice & Billing management
- Customer Support tickets
- Proposals & Quotes generation
- HR Management (employees, leave, performance)
- Business Reporting & Dashboard

**AI Capabilities:**
- Multi-Agent System (CEO, Programmer, Accountant, Lawyer, etc.)
- AI Reasoning Engine (step-by-step thinking)
- Long-Term Memory
- Knowledge Base (RAG)
- Code Generation & Website/App creation

**Productivity:**
- Tasks, Notes, Calendar, Reminders
- Shopping Lists, Budgets
- Workflow Automation
- Email Drafts & Reports

**Technical:**
- Voice Assistant (with fallbacks)
- File Processing (PDF, images, data)
- Security (roles, API keys, audit logs)
- Plugin System

## Installation

```bash
# Clone the repository
git clone https://github.com/fadar02/KaStart-.git
cd KaStart-

# Install dependencies
pip install -r requirements.txt

# Run the web interface (recommended)
streamlit run app.py

# Or run terminal version
python3 chatbot.py
```

## Quick Start

```bash
# Web Interface (ChatGPT-like UI)
streamlit run app.py

# Terminal Interface
python3 chatbot.py

# Run with a command
python3 chatbot.py "help"
```

## Commands

### Business

```bash
# Invoicing
Add invoice: Client Name, Amount, Due Date, Description
List invoices
Mark invoice INV-0001 paid
Revenue report

# Support
Add ticket: Customer, Issue, Priority
List tickets
Close ticket TKT-0001

# Proposals
Generate proposal: Client, Description, Amount, Timeline
Generate quote: Client, Items, Amount

# HR
Add employee: Name, Position, Department, Start Date, Salary
Request leave: Employee, Type, Start Date, End Date, Reason

# Reports
Dashboard
Revenue report
Monthly report
```

### AI Features

```bash
# Talk to AI agents
Ask the CEO about strategy
Talk to the programmer about Python

# Reasoning
Reason: Should I use Python or JavaScript?
Think about: How to scale my app

# Knowledge Base
Add knowledge: Our company uses React
Search knowledge: deployment
```

## Project Structure

```
kastart/
├── chatbot.py              # Main orchestrator
├── business_suite.py       # Invoice & Billing
├── support_tickets.py      # Customer Support
├── proposals.py            # Proposals & Quotes
├── hr_manager.py           # HR Management
├── reports.py              # Business Reporting
├── memory_system.py        # Long-term memory
├── agent_system.py         # Multi-agent AI
├── reasoning_engine.py     # Reasoning engine
├── personal_assistant.py   # Tasks, notes, calendar
├── knowledge_base.py       # RAG knowledge base
├── security_system.py      # Security & auth
├── plugin_system.py        # Plugin architecture
├── file_processors.py      # PDF, image processing
├── voice_module.py         # Voice assistant
├── workflow_automation.py  # Workflow automation
├── advanced_features.py    # Screen, emotions, predictions
├── math_module.py          # Math calculations
├── qa_module.py            # Q&A system
├── recommendation_engine.py # Recommendations
├── code_generator.py       # Code generation
├── opencode_features.py    # File ops, git, web
├── requirements.txt        # Dependencies
└── README.md               # Documentation
```

## License

MIT License

## Contact

Your Name - your.email@example.com
