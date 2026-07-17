import os
import json
import hashlib
from datetime import datetime
from typing import Optional, List, Dict, Any
from pathlib import Path

class MemorySystem:
    """Long-term memory: preferences, conversations, corrections, personal/work separation."""

    def __init__(self, data_dir: str = ".memory"):
        self.data_dir = data_dir
        self.preferences_file = os.path.join(data_dir, "preferences.json")
        self.conversations_dir = os.path.join(data_dir, "conversations")
        self.corrections_file = os.path.join(data_dir, "corrections.json")
        self.facts_file = os.path.join(data_dir, "facts.json")
        self.user_profile_file = os.path.join(data_dir, "user_profile.json")
        self._ensure_dirs()

    def _ensure_dirs(self):
        os.makedirs(self.data_dir, exist_ok=True)
        os.makedirs(self.conversations_dir, exist_ok=True)

    def _load_json(self, filepath: str) -> dict:
        if os.path.exists(filepath):
            with open(filepath, 'r') as f:
                return json.load(f)
        return {}

    def _save_json(self, filepath: str, data: dict):
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2, default=str)

    def save_preference(self, key: str, value: Any, category: str = "general"):
        prefs = self._load_json(self.preferences_file)
        if category not in prefs:
            prefs[category] = {}
        prefs[category][key] = {
            "value": value,
            "updated": datetime.now().isoformat()
        }
        self._save_json(self.preferences_file, prefs)

    def get_preference(self, key: str, category: str = "general", default=None) -> Any:
        prefs = self._load_json(self.preferences_file)
        cat = prefs.get(category, {})
        item = cat.get(key)
        if item:
            return item.get("value", default)
        return default

    def get_all_preferences(self) -> dict:
        return self._load_json(self.preferences_file)

    def save_conversation(self, user_id: str, messages: List[Dict], topic: str = "general"):
        conv_hash = hashlib.md5(f"{user_id}_{topic}_{datetime.now().date()}".encode()).hexdigest()[:8]
        filename = f"{user_id}_{conv_hash}.json"
        filepath = os.path.join(self.conversations_dir, filename)

        existing = []
        if os.path.exists(filepath):
            with open(filepath, 'r') as f:
                data = json.load(f)
                if isinstance(data, list):
                    existing = data
                elif isinstance(data, dict):
                    existing = data.get("messages", [])

        existing.extend(messages)

        meta = {
            "user_id": user_id,
            "topic": topic,
            "date": datetime.now().isoformat(),
            "message_count": len(existing),
            "messages": existing
        }
        self._save_json(filepath, meta)

    def search_conversations(self, query: str, user_id: str = None) -> List[Dict]:
        results = []
        query_lower = query.lower()

        for filename in os.listdir(self.conversations_dir):
            if not filename.endswith('.json'):
                continue
            filepath = os.path.join(self.conversations_dir, filename)
            with open(filepath, 'r') as f:
                conv = json.load(f)

            if user_id and conv.get('user_id') != user_id:
                continue

            for msg in conv.get('messages', []):
                content = msg.get('content', '').lower()
                if query_lower in content:
                    results.append({
                        "topic": conv.get('topic', 'unknown'),
                        "date": conv.get('date', 'unknown'),
                        "content": msg.get('content', ''),
                        "role": msg.get('role', 'unknown'),
                        "file": filename
                    })
                    break
        return results

    def save_correction(self, user_input: str, incorrect_response: str, correct_response: str):
        corrections = self._load_json(self.corrections_file)
        correction_id = hashlib.md5(f"{user_input}_{datetime.now().isoformat()}".encode()).hexdigest()[:8]
        corrections[correction_id] = {
            "user_input": user_input,
            "incorrect_response": incorrect_response,
            "correct_response": correct_response,
            "timestamp": datetime.now().isoformat()
        }
        self._save_json(self.corrections_file, corrections)

    def get_corrections(self) -> dict:
        return self._load_json(self.corrections_file)

    def find_similar_correction(self, user_input: str) -> Optional[str]:
        corrections = self._load_json(self.corrections_file)
        input_lower = user_input.lower()
        for cid, corr in corrections.items():
            if input_lower in corr.get('user_input', '').lower() or corr.get('user_input', '').lower() in input_lower:
                return corr.get('correct_response')
        return None

    def save_fact(self, fact: str, category: str = "general", source: str = "user"):
        facts = self._load_json(self.facts_file)
        if category not in facts:
            facts[category] = []
        facts[category].append({
            "fact": fact,
            "source": source,
            "timestamp": datetime.now().isoformat()
        })
        self._save_json(self.facts_file, facts)

    def search_facts(self, query: str) -> List[Dict]:
        facts = self._load_json(self.facts_file)
        results = []
        query_lower = query.lower()
        for category, fact_list in facts.items():
            for item in fact_list:
                if query_lower in item.get('fact', '').lower():
                    results.append({**item, "category": category})
        return results

    def update_user_profile(self, data: dict):
        profile = self._load_json(self.user_profile_file)
        profile.update(data)
        profile["last_updated"] = datetime.now().isoformat()
        self._save_json(self.user_profile_file, profile)

    def get_user_profile(self) -> dict:
        return self._load_json(self.user_profile_file)

    def get_context_summary(self, user_id: str = None) -> str:
        profile = self.get_user_profile()
        prefs = self.get_all_preferences()
        facts = self._load_json(self.facts_file)

        summary_parts = []
        if profile.get("name"):
            summary_parts.append(f"User: {profile['name']}")
        if profile.get("role"):
            summary_parts.append(f"Role: {profile['role']}")
        if profile.get("current_project"):
            summary_parts.append(f"Current project: {profile['current_project']}")

        for cat, items in prefs.items():
            for key, val in items.items():
                summary_parts.append(f"Prefers {key}: {val.get('value', '')}")

        for cat, fact_list in list(facts.items())[:3]:
            for item in fact_list[:2]:
                summary_parts.append(f"Known fact ({cat}): {item.get('fact', '')}")

        return "\n".join(summary_parts) if summary_parts else "No memory context yet."

    def forget(self, category: str = None, key: str = None):
        if category and key:
            prefs = self._load_json(self.preferences_file)
            if category in prefs and key in prefs[category]:
                del prefs[category][key]
                self._save_json(self.preferences_file, prefs)
        elif category:
            prefs = self._load_json(self.preferences_file)
            if category in prefs:
                del prefs[category]
                self._save_json(self.preferences_file, prefs)
