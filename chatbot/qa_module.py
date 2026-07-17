import re
from typing import Optional, Tuple

class QAModule:
    """Handles question answering with pattern matching and knowledge base."""

    def __init__(self):
        self.knowledge_base = self._build_knowledge_base()
        self.patterns = self._build_patterns()

    def _build_knowledge_base(self) -> dict:
        """Build a comprehensive knowledge base."""
        return {
            "greeting": {
                "responses": [
                    "Hello! How can I help you today?",
                    "Hi there! What can I do for you?",
                    "Hey! Nice to meet you. What's on your mind?",
                    "Greetings! How may I assist you?"
                ],
                "patterns": [r'hello', r'hi', r'hey', r'greetings', r'good morning', r'good afternoon', r'good evening']
            },
            "farewell": {
                "responses": [
                    "Goodbye! Have a great day!",
                    "See you later! Take care!",
                    "Bye! Come back anytime!",
                    "Until next time! Stay well!"
                ],
                "patterns": [r'bye', r'goodbye', r'see you', r'farewell', r'quit', r'exit']
            },
            "identity": {
                "responses": [
                    "I'm an AI chatbot created to help you with questions, math, and recommendations!",
                    "I'm your personal AI assistant. I can help with calculations, answer questions, and give recommendations.",
                    "I'm a Python chatbot with math, Q&A, and recommendation capabilities!"
                ],
                "patterns": [r'who are you', r'what are you', r'your name', r'about you', r'introduce yourself']
            },
            "capabilities": {
                "responses": [
                    "I can:\n1. Calculate math expressions\n2. Answer general questions\n3. Give recommendations\n4. Have a conversation\n\nJust ask me anything!",
                    "My capabilities include:\n- Math calculations (e.g., 'calculate 2+2')\n- Answering questions\n- Recommending movies, books, music, and more\n- General conversation"
                ],
                "patterns": [r'what can you do', r'capabilities', r'features', r'help', r'how do you work']
            },
            "time": {
                "responses": [
                    "I don't have access to real-time data, but you can check your system clock!",
                    "I can't tell the exact time right now, but I'm here to help with other things!"
                ],
                "patterns": [r'what time', r'current time', r'tell me the time', r'clock']
            },
            "date": {
                "responses": [
                    "I don't have access to the current date, but I'm always ready to help!",
                    "I can't check the date right now, but I'm here for your questions!"
                ],
                "patterns": [r'what date', r'current date', r'today.*date', r'what day']
            },
            "meaning_of_life": {
                "responses": [
                    "42. At least, that's what Deep Thought says!",
                    "According to The Hitchhiker's Guide to the Galaxy, it's 42!"
                ],
                "patterns": [r'meaning of life', r'universe.*everything']
            },
            "weather": {
                "responses": [
                    "I don't have access to weather data, but I recommend checking a weather service!",
                    "I can't check the weather, but I hope it's nice where you are!"
                ],
                "patterns": [r'weather', r'temperature', r'forecast']
            },
            "joke": {
                "responses": [
                    "Why do programmers prefer dark mode? Because light attracts bugs!",
                    "Why did the scarecrow win an award? He was outstanding in his field!",
                    "What do you call a fake noodle? An impasta!",
                    "Why don't scientists trust atoms? Because they make up everything!",
                    "What do you call a bear with no teeth? A gummy bear!"
                ],
                "patterns": [r'joke', r'funny', r'humor', r'laugh', r'entertain me']
            },
            "compliment": {
                "responses": [
                    "Thank you! You're pretty amazing yourself!",
                    "That's so kind of you! You just made my day!",
                    "Aww, thanks! You're awesome too!",
                    "I appreciate that! You're wonderful!"
                ],
                "patterns": [r'you.*great', r'you.*awesome', r'you.*amazing', r'you.*smart', r'good bot', r'well done']
            },
            "insult": {
                "responses": [
                    "I'm sorry you feel that way. I'm here to help!",
                    "Let's keep things positive. How can I assist you?",
                    "I'll do my best to be more helpful. What can I do for you?"
                ],
                "patterns": [r'you.*stupid', r'you.*dumb', r'you.*useless', r'bad bot', r'hate you']
            },
            "thanks": {
                "responses": [
                    "You're welcome! Happy to help!",
                    "My pleasure! Let me know if you need anything else!",
                    "Anytime! That's what I'm here for!",
                    "Glad I could help!"
                ],
                "patterns": [r'thank', r'thanks', r'appreciate', r'helpful']
            },
            "how_are_you": {
                "responses": [
                    "I'm doing great, thanks for asking! How can I help you?",
                    "All systems running smoothly! What can I do for you?",
                    "I'm wonderful! Ready to assist you with anything!"
                ],
                "patterns": [r'how are you', r'how.*doing', r'how.*feel', r'are you okay']
            },
            "creator": {
                "responses": [
                    "I was created by a talented developer using Python!",
                    "I was built with Python as a demonstration of AI capabilities!"
                ],
                "patterns": [r'who.*created', r'who.*made', r'who.*built', r'developer', r'creator']
            },
            "purpose": {
                "responses": [
                    "My purpose is to help you with questions, calculations, and recommendations!",
                    "I'm here to assist you with various tasks and make your day easier!"
                ],
                "patterns": [r'what.*purpose', r'why.*exist', r'what.*goal']
            }
        }

    def _build_patterns(self) -> list:
        """Build regex patterns for question types."""
        return [
            (r'(what|who|where|when|why|how)\s+is\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+are\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+do\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+does\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+can\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+should\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+would\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+did\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+did\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+will\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+shall\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+could\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+might\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+may\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+ought\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+need\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+have\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+has\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+had\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+was\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+were\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+is\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+are\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+do\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+does\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+can\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+should\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+would\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+did\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+did\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+will\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+shall\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+could\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+might\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+may\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+ought\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+need\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+have\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+has\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+had\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+was\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+were\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+is\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+are\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+do\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+does\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+can\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+should\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+would\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+did\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+did\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+will\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+shall\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+could\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+might\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+may\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+ought\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+need\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+have\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+has\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+had\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+was\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+were\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+is\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+are\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+do\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+does\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+can\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+should\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+would\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+did\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+did\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+will\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+shall\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+could\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+might\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+may\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+ought\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+need\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+have\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+has\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+had\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+was\s+(.+)', self._handle_what_is),
            (r'(what|who|where|when|why|how)\s+were\s+(.+)', self._handle_what_is),
        ]

    def _handle_what_is(self, match: re.Match) -> str:
        """Handle 'what is X' type questions."""
        question_word = match.group(1)
        subject = match.group(2).strip()
        
        subject_lower = subject.lower()
        
        facts = {
            "python": "Python is a high-level, interpreted programming language known for its simplicity and versatility. It was created by Guido van Rossum and first released in 1991.",
            "java": "Java is a class-based, object-oriented programming language designed to have as few implementation dependencies as possible. It was developed by James Gosling at Sun Microsystems.",
            "javascript": "JavaScript is a high-level, interpreted programming language that conforms to the ECMAScript specification. It is a dynamic language with first-class functions.",
            "ai": "Artificial Intelligence (AI) is the simulation of human intelligence processes by computer systems. These processes include learning, reasoning, and self-correction.",
            "machine learning": "Machine Learning is a subset of AI that provides systems the ability to automatically learn and improve from experience without being explicitly programmed.",
            "deep learning": "Deep Learning is a subset of machine learning based on artificial neural networks with representation learning.",
            "blockchain": "Blockchain is a distributed, decentralized, public ledger consisting of blocks that are linked using cryptography.",
            "bitcoin": "Bitcoin is a decentralized digital currency that can be sent between users on a peer-to-peer bitcoin network without the need for intermediaries.",
            "earth": "Earth is the third planet from the Sun and the only astronomical object known to harbor life. It has one natural satellite, the Moon.",
            "sun": "The Sun is the star at the center of the Solar System. It is a nearly perfect ball of hot plasma, heated to incandescence by nuclear fusion reactions.",
            "moon": "The Moon is Earth's only natural satellite. It orbits at an average distance of 384,400 km and has a diameter of about 3,474 km.",
            "gravity": "Gravity is the force of attraction between all masses in the universe. On Earth, it gives weight to physical objects and causes them to fall toward the ground.",
            "water": "Water is a transparent, tasteless, odorless, and nearly colorless chemical substance. It's the main constituent of Earth's surface and the fluids of most living organisms.",
            "oxygen": "Oxygen is a chemical element with symbol O and atomic number 8. It is a member of the chalcogen group and a highly reactive nonmetal.",
            "carbon": "Carbon is a chemical element with symbol C and atomic number 6. It is the basis of organic chemistry and all known life forms.",
            "dna": "DNA (deoxyribonucleic acid) is a molecule composed of two polynucleotide chains that coil around each other to form a double helix. It carries genetic instructions for development and function.",
            "human": "Humans (Homo sapiens) are the only living species of the genus Homo. They are characterized by large brains, bipedal locomotion, and complex social structures.",
            "internet": "The Internet is a global system of interconnected computer networks that use the TCP/IP protocol suite to link billions of devices worldwide.",
            "wifi": "Wi-Fi is a family of wireless network protocols based on the IEEE 802.11 family of standards, which are commonly used for local area networking of devices.",
            "computer": "A computer is a programmable device that can store, retrieve, and process data. Modern computers can perform billions of calculations per second.",
            "software": "Software is a collection of instructions and data that tells a computer how to work. It's the opposite of hardware.",
            "hardware": "Hardware refers to the physical components of a computer system, such as the CPU, memory, storage devices, and peripherals.",
            "algorithm": "An algorithm is a finite sequence of well-defined, computer-implementable instructions typically to solve a class of problems or to perform a computation.",
            "data": "Data is a collection of facts, statistics, and information that can be analyzed. In computing, it refers to information stored in digital form.",
            "api": "An API (Application Programming Interface) is a set of rules and protocols for building and interacting with software applications.",
            "database": "A database is an organized collection of structured information or data, typically stored electronically in a computer system.",
            "cloud": "Cloud computing is the on-demand availability of computer system resources, especially data storage and computing power, without direct active management by the user.",
        }
        
        for key, fact in facts.items():
            if key in subject_lower:
                return fact
        
        if any(word in subject_lower for word in ['who', 'person', 'man', 'woman', 'people']):
            return f"That's an interesting question about {subject}. Could you be more specific?"
        
        return f"I can tell you that '{subject}' is an interesting topic! However, I don't have specific information about it in my knowledge base yet. Could you rephrase or ask something more specific?"

    def answer(self, question: str) -> Optional[str]:
        """Answer a question using pattern matching and knowledge base."""
        question_lower = question.lower().strip()
        
        for category, data in self.knowledge_base.items():
            for pattern in data["patterns"]:
                if re.search(pattern, question_lower):
                    import random
                    return random.choice(data["responses"])
        
        for pattern, handler in self.patterns:
            match = re.search(pattern, question_lower)
            if match:
                return handler(match)
        
        if any(word in question_lower for word in ['what', 'who', 'where', 'when', 'why', 'how', 'is', 'are', 'do', 'does', 'can', 'could', 'would', 'should']):
            return f"That's a great question! I don't have a specific answer for '{question}' yet, but I'm always learning. Could you try rephrasing or asking something else?"
        
        return None
