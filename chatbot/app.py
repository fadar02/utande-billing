"""
KaStart AI Assistant - Web Interface
A ChatGPT-like web interface powered by Streamlit
"""
import streamlit as st
import sys
import os
from datetime import datetime

# Add chatbot directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from chatbot import ChatBot

# Page config
st.set_page_config(
    page_title="KaStart AI Assistant",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        padding: 20px;
        border-radius: 10px;
        color: white;
        text-align: center;
        margin-bottom: 20px;
    }
    .feature-card {
        background: #f8f9fa;
        padding: 15px;
        border-radius: 8px;
        border-left: 4px solid #667eea;
        margin: 10px 0;
    }
    .stChatMessage {
        border-radius: 10px;
    }
    sidebar .sidebar-content {
        background: #f8f9fa;
    }
</style>
""", unsafe_allow_html=True)


def initialize_chatbot():
    """Initialize chatbot in session state"""
    if 'chatbot' not in st.session_state:
        st.session_state.chatbot = ChatBot()
    if 'messages' not in st.session_state:
        st.session_state.messages = []
    if 'conversation_count' not in st.session_state:
        st.session_state.conversation_count = 0


def display_header():
    """Display the main header"""
    st.markdown("""
    <div class="main-header">
        <h1>🤖 KaStart AI Assistant</h1>
        <p>Your AI-powered business assistant for SMEs</p>
    </div>
    """, unsafe_allow_html=True)


def display_sidebar():
    """Display sidebar with features and controls"""
    with st.sidebar:
        st.header("⚙️ Controls")
        
        if st.button("🗑️ Clear Chat", use_container_width=True):
            st.session_state.messages = []
            st.session_state.conversation_count = 0
            st.rerun()
        
        st.divider()
        
        st.header("📊 Session Stats")
        st.metric("Messages", len(st.session_state.messages))
        
        st.divider()
        
        st.header("💼 Business Features")
        st.markdown("""
        **Invoicing**
        - Add/List/Mark invoices
        - Revenue reports
        
        **Support**
        - Ticket management
        - FAQ system
        
        **Proposals**
        - Generate proposals
        - Create quotes
        
        **HR**
        - Employee records
        - Leave management
        
        **Reports**
        - Dashboard
        - Monthly/Quarterly
        """)
        
        st.divider()
        
        st.header("🧠 AI Features")
        st.markdown("""
        - Multi-Agent System
        - Reasoning Engine
        - Knowledge Base
        - Code Generation
        - File Operations
        """)
        
        st.divider()
        
        st.header("📋 Quick Commands")
        st.code("""
help          - Show all commands
agents        - View AI team
plugins       - List plugins
reasoning     - Reasoning engine
voice         - Voice status
status        - System status
quit          - Exit
        """, language=None)


def display_welcome():
    """Display welcome message"""
    if not st.session_state.messages:
        st.markdown("""
        ## Welcome to KaStart AI Assistant! 👋
        
        I'm your AI-powered business assistant. I can help you with:
        
        ### 💼 Business Management
        - **Invoicing**: Create, track, and manage invoices
        - **Support**: Handle customer tickets and FAQs
        - **Proposals**: Generate business proposals and quotes
        - **HR**: Manage employees and leave requests
        - **Reports**: View business dashboards and analytics
        
        ### 🧠 AI Capabilities
        - **Multi-Agent System**: Talk to specialized AI agents (CEO, Programmer, etc.)
        - **Reasoning Engine**: Step-by-step thinking
        - **Knowledge Base**: Store and search documents
        - **Code Generation**: Create websites and apps
        
        ### 📋 Productivity
        - Tasks, Notes, Calendar, Reminders
        - Shopping Lists, Budgets
        - Workflow Automation
        
        ---
        
        **Try saying:**
        - "Add invoice: Acme Corp, $1500, 2026-02-15, Website"
        - "Add ticket: John, Login issue, high"
        - "Ask the CEO about strategy"
        - "Help" - to see all commands
        """)


def main():
    """Main application"""
    initialize_chatbot()
    display_header()
    display_sidebar()
    
    # Chat container
    chat_container = st.container()
    
    with chat_container:
        display_welcome()
        
        # Display chat history
        for message in st.session_state.messages:
            with st.chat_message(message["role"]):
                st.markdown(message["content"])
        
        # Chat input
        if prompt := st.chat_input("Type your message here..."):
            # Add user message to chat history
            st.session_state.messages.append({"role": "user", "content": prompt})
            
            with st.chat_message("user"):
                st.markdown(prompt)
            
            # Generate response
            with st.chat_message("assistant"):
                with st.spinner("Thinking..."):
                    try:
                        response = st.session_state.chatbot.process_input(prompt)
                        st.markdown(response)
                        
                        # Add assistant response to chat history
                        st.session_state.messages.append({"role": "assistant", "content": response})
                        
                        # Increment conversation count
                        st.session_state.conversation_count += 1
                        
                    except Exception as e:
                        error_msg = f"Sorry, I encountered an error: {str(e)}"
                        st.error(error_msg)
                        st.session_state.messages.append({"role": "assistant", "content": error_msg})
            
            # Rerun to update sidebar stats
            st.rerun()


if __name__ == "__main__":
    main()
