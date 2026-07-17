import os
import json
import re
from typing import Dict, List, Callable, Optional, Any


class PluginSystem:
    def __init__(self, plugins_dir: str = ".plugins"):
        self.plugins_dir = plugins_dir
        self.plugins: Dict[str, Dict[str, Any]] = {}
        self.config_file = os.path.join(plugins_dir, "plugins.json")
        os.makedirs(plugins_dir, exist_ok=True)
        self._load_config()
        self._load_builtin_plugins()

    def _load_config(self) -> None:
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, "r") as f:
                    saved = json.load(f)
                for name, config in saved.items():
                    if name in self.plugins:
                        self.plugins[name]["enabled"] = config.get("enabled", True)
            except (json.JSONDecodeError, KeyError):
                pass

    def _save_config(self) -> None:
        config = {}
        for name, plugin in self.plugins.items():
            config[name] = {"enabled": plugin["enabled"]}
        with open(self.config_file, "w") as f:
            json.dump(config, f, indent=2)

    def register_plugin(
        self,
        name: str,
        description: str,
        commands: List[str],
        handler: Callable[[str, List[str]], str],
    ) -> bool:
        if name in self.plugins:
            return False
        self.plugins[name] = {
            "description": description,
            "commands": commands,
            "handler": handler,
            "enabled": True,
            "builtin": False,
        }
        self._save_config()
        return True

    def list_plugins(self) -> str:
        if not self.plugins:
            return "No plugins installed."
        lines = ["Installed Plugins:"]
        for name, plugin in self.plugins.items():
            status = "enabled" if plugin["enabled"] else "disabled"
            builtin = " (builtin)" if plugin["builtin"] else ""
            lines.append(f"  - {name}{builtin}: {plugin['description']} [{status}]")
            lines.append(f"    Commands: {', '.join(plugin['commands'])}")
        return "\n".join(lines)

    def enable_plugin(self, name: str) -> bool:
        if name not in self.plugins:
            return False
        self.plugins[name]["enabled"] = True
        self._save_config()
        return True

    def disable_plugin(self, name: str) -> bool:
        if name not in self.plugins:
            return False
        self.plugins[name]["enabled"] = False
        self._save_config()
        return True

    def execute_command(
        self, plugin_name: str, command: str, args: List[str]
    ) -> str:
        if plugin_name not in self.plugins:
            return f"Plugin '{plugin_name}' not found."
        plugin = self.plugins[plugin_name]
        if not plugin["enabled"]:
            return f"Plugin '{plugin_name}' is disabled."
        if command not in plugin["commands"]:
            return (
                f"Command '{command}' not found in plugin '{plugin_name}'. "
                f"Available: {', '.join(plugin['commands'])}"
            )
        try:
            return plugin["handler"](command, args)
        except Exception as e:
            return f"Error executing {plugin_name}/{command}: {str(e)}"

    def is_plugin_request(self, text: str) -> bool:
        text_lower = text.lower().strip()
        triggers = [
            "calculate",
            "calc",
            "weather",
            "translate",
            "summarize",
            "summary",
            "email",
            "report",
            "/calc",
            "/weather",
            "/translate",
            "/summarize",
            "/email",
            "/report",
            "/plugin",
        ]
        return any(text_lower.startswith(t) for t in triggers)

    def handle(self, text: str) -> str:
        text = text.strip()
        text_lower = text.lower()

        if text_lower.startswith("/plugin"):
            parts = text.split(maxsplit=2)
            if len(parts) < 2:
                return self.list_plugins()
            sub = parts[1].lower()
            if sub == "list":
                return self.list_plugins()
            elif sub == "enable" and len(parts) >= 3:
                name = parts[2].strip()
                if self.enable_plugin(name):
                    return f"Plugin '{name}' enabled."
                return f"Plugin '{name}' not found."
            elif sub == "disable" and len(parts) >= 3:
                name = parts[2].strip()
                if self.disable_plugin(name):
                    return f"Plugin '{name}' disabled."
                return f"Plugin '{name}' not found."
            return self.list_plugins()

        plugin_map = {
            "calc": ("calculator", "calculate"),
            "calculate": ("calculator", "calculate"),
            "/calc": ("calculator", "calculate"),
            "weather": ("weather", "weather"),
            "/weather": ("weather", "weather"),
            "translate": ("translator", "translate"),
            "/translate": ("translator", "translate"),
            "summarize": ("summarizer", "summarize"),
            "summary": ("summarizer", "summarize"),
            "/summarize": ("summarizer", "summarize"),
            "email": ("email_composer", "compose"),
            "/email": ("email_composer", "compose"),
            "report": ("report_generator", "generate"),
            "/report": ("report_generator", "generate"),
        }

        for trigger, (plugin_name, command) in plugin_map.items():
            if text_lower.startswith(trigger):
                rest = text[len(trigger) :].strip()
                args = rest.split() if rest else []
                return self.execute_command(plugin_name, command, args)

        return "Command not recognized. Use /plugin list to see available plugins."

    def _load_builtin_plugins(self) -> None:
        self.register_plugin(
            name="calculator",
            description="Performs basic mathematical calculations",
            commands=["calculate"],
            handler=self._calculator_handler,
        )
        self.register_plugin(
            name="weather",
            description="Provides weather information (stub - requires API key)",
            commands=["weather"],
            handler=self._weather_handler,
        )
        self.register_plugin(
            name="translator",
            description="Translates text between languages (stub - requires API key)",
            commands=["translate"],
            handler=self._translator_handler,
        )
        self.register_plugin(
            name="summarizer",
            description="Summarizes long pieces of text",
            commands=["summarize"],
            handler=self._summarizer_handler,
        )
        self.register_plugin(
            name="email_composer",
            description="Helps draft professional emails",
            commands=["compose"],
            handler=self._email_composer_handler,
        )
        self.register_plugin(
            name="report_generator",
            description="Creates structured reports from given topics",
            commands=["generate"],
            handler=self._report_generator_handler,
        )

    def _calculator_handler(self, command: str, args: List[str]) -> str:
        if not args:
            return "Usage: calc <expression>\nExample: calc 2 + 2 * 3"
        expression = " ".join(args)
        sanitized = re.sub(r"[^0-9+\-*/().%\s]", "", expression)
        if not sanitized.strip():
            return "Invalid expression. Use numbers and operators: +, -, *, /, %, ()"
        try:
            result = eval(sanitized, {"__builtins__": {}}, {})
            return f"Result: {expression} = {result}"
        except ZeroDivisionError:
            return "Error: Division by zero."
        except Exception:
            return f"Error evaluating expression: {expression}"

    def _weather_handler(self, command: str, args: List[str]) -> str:
        if not args:
            return (
                "Weather plugin requires an API key to function.\n"
                "To set up:\n"
                "  1. Get a free API key from OpenWeatherMap (https://openweathermap.org/api)\n"
                "  2. Set environment variable: export WEATHER_API_KEY=your_key\n"
                "  3. Restart the chatbot\n"
                "Usage: weather <city_name>"
            )
        city = " ".join(args)
        api_key = os.environ.get("WEATHER_API_KEY")
        if not api_key:
            return (
                f"No API key configured for weather plugin.\n"
                f"Set WEATHER_API_KEY environment variable.\n"
                f"Requested city: {city}"
            )
        return f"Weather data for '{city}' would be fetched here using API key."

    def _translator_handler(self, command: str, args: List[str]) -> str:
        if len(args) < 2:
            return (
                "Translation plugin requires an API key to function.\n"
                "To set up:\n"
                "  1. Get an API key from Google Cloud Translation or similar\n"
                "  2. Set environment variable: export TRANSLATE_API_KEY=your_key\n"
                "  3. Restart the chatbot\n"
                "Usage: translate <target_language> <text>\n"
                "Example: translate spanish Hello, how are you?"
            )
        target_lang = args[0]
        text_to_translate = " ".join(args[1:])
        api_key = os.environ.get("TRANSLATE_API_KEY")
        if not api_key:
            return (
                f"No API key configured for translator plugin.\n"
                f"Set TRANSLATE_API_KEY environment variable.\n"
                f"Would translate '{text_to_translate}' to {target_lang}."
            )
        return f"Translation of '{text_to_translate}' to {target_lang} would appear here."

    def _summarizer_handler(self, command: str, args: List[str]) -> str:
        if not args:
            return "Usage: summarize <text>\nProvide the text you want summarized."
        text = " ".join(args)
        if len(text) < 20:
            return "Text too short to summarize. Provide a longer passage."
        sentences = re.split(r"[.!?]+", text)
        sentences = [s.strip() for s in sentences if s.strip()]
        if len(sentences) <= 2:
            return f"Summary: {text}"
        scored = []
        words = text.lower().split()
        word_freq: Dict[str, int] = {}
        for w in words:
            w_clean = re.sub(r"[^a-zA-Z]", "", w)
            if w_clean and len(w_clean) > 3:
                word_freq[w_clean] = word_freq.get(w_clean, 0) + 1
        for i, sentence in enumerate(sentences):
            score = 0
            s_words = sentence.lower().split()
            for w in s_words:
                w_clean = re.sub(r"[^a-zA-Z]", "", w)
                if w_clean in word_freq:
                    score += word_freq[w_clean]
            if i == 0 or i == len(sentences) - 1:
                score += 2
            scored.append((score, i, sentence))
        scored.sort(key=lambda x: x[0], reverse=True)
        top = sorted(scored[: max(1, len(sentences) // 2)], key=lambda x: x[1])
        summary = ". ".join(s[2] for s in top)
        if not summary.endswith("."):
            summary += "."
        return f"Summary ({len(sentences)} sentences -> {len(top)}):\n{summary}"

    def _email_composer_handler(self, command: str, args: List[str]) -> str:
        if not args:
            return (
                "Usage: email <type> <topic>\n"
                "Types: formal, informal, followup, thank you, complaint\n"
                "Example: email formal meeting request\n"
                "Example: email thank you interview"
            )
        email_type = args[0].lower()
        topic = " ".join(args[1:]) if len(args) > 1 else "general inquiry"

        templates = {
            "formal": (
                f"Subject: {topic.title()}\n\n"
                f"Dear [Recipient],\n\n"
                f"I am writing to address the matter of {topic}. "
                f"I would appreciate the opportunity to discuss this further "
                f"at your earliest convenience.\n\n"
                f"Please do not hesitate to reach out should you require "
                f"any additional information.\n\n"
                f"Kind regards,\n[Your Name]"
            ),
            "informal": (
                f"Subject: {topic.title()}\n\n"
                f"Hi [Name],\n\n"
                f"Just wanted to reach out about {topic}. "
                f"Let me know what you think!\n\n"
                f"Best,\n[Your Name]"
            ),
            "followup": (
                f"Subject: Follow-up: {topic.title()}\n\n"
                f"Hi [Name],\n\n"
                f"I wanted to follow up on our previous conversation about {topic}. "
                f"Have you had a chance to review this? "
                f"I would love to hear your thoughts.\n\n"
                f"Looking forward to your response.\n\n"
                f"Best regards,\n[Your Name]"
            ),
            "thank": (
                f"Subject: Thank You - {topic.title()}\n\n"
                f"Dear [Name],\n\n"
                f"I wanted to take a moment to express my sincere gratitude "
                f"regarding {topic}. Your assistance has been invaluable.\n\n"
                f"Thank you once again for your time and support.\n\n"
                f"With appreciation,\n[Your Name]"
            ),
            "complaint": (
                f"Subject: Complaint Regarding {topic.title()}\n\n"
                f"Dear [Manager/Support Team],\n\n"
                f"I am writing to formally bring to your attention an issue "
                f"regarding {topic}. I have encountered this problem and "
                f"would appreciate a prompt resolution.\n\n"
                f"I look forward to your response and a satisfactory resolution.\n\n"
                f"Sincerely,\n[Your Name]"
            ),
        }

        if email_type in templates:
            return templates[email_type]
        return (
            f"Unknown email type: '{email_type}'.\n"
            f"Available types: formal, informal, followup, thank, complaint"
        )

    def _report_generator_handler(self, command: str, args: List[str]) -> str:
        if not args:
            return (
                "Usage: report <topic> [sections]\n"
                "Example: report quarterly sales revenue,expenses,forecast\n"
                "Sections are comma-separated (optional)."
            )
        topic = args[0]
        sections = (
            [s.strip() for s in args[1].split(",")]
            if len(args) > 1
            else ["Overview", "Key Findings", "Analysis", "Recommendations", "Conclusion"]
        )

        lines = [
            f"{'=' * 60}",
            f"REPORT: {topic.upper()}",
            f"{'=' * 60}",
            f"Generated: [Date]",
            f"{'─' * 60}",
        ]
        for section in sections:
            lines.append(f"\n## {section.title()}")
            lines.append(f"  [Content for {section.lower()} section would be")
            lines.append(f"   generated here based on provided data.]\n")
        lines.append(f"{'─' * 60}")
        lines.append("END OF REPORT")
        lines.append(f"{'=' * 60}")
        return "\n".join(lines)


if __name__ == "__main__":
    system = PluginSystem()
    print(system.list_plugins())
    print()
    print(system.handle("calc 10 + 5 * 2"))
    print()
    print(system.handle("summarize Machine learning is a subset of artificial intelligence. It enables systems to learn from data. Deep learning uses neural networks with many layers. These advances have transformed many industries."))
    print()
    print(system.handle("email formal project deadline extension"))
    print()
    print(system.handle("report Q3 Performance revenue,headcount,growth"))
    print()
    print(system.handle("weather London"))
    print()
    print(system.handle("translate french Hello world"))
    print()
    print(system.handle("/plugin disable weather"))
    print()
    print(system.handle("/plugin list"))
