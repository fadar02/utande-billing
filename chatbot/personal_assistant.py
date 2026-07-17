import os
import json
import re
from datetime import datetime, timedelta
from typing import Dict, List, Optional

class PersonalAssistant:
    """Manages tasks, notes, calendar, reminders, goals, shopping lists, budgets."""

    def __init__(self, data_dir: str = ".assistant"):
        self.data_dir = data_dir
        self.tasks_file = os.path.join(data_dir, "tasks.json")
        self.notes_file = os.path.join(data_dir, "notes.json")
        self.calendar_file = os.path.join(data_dir, "calendar.json")
        self.goals_file = os.path.join(data_dir, "goals.json")
        self.shopping_file = os.path.join(data_dir, "shopping.json")
        self.budget_file = os.path.join(data_dir, "budget.json")
        self.reminders_file = os.path.join(data_dir, "reminders.json")
        self.todo_file = os.path.join(data_dir, "todo.json")
        os.makedirs(data_dir, exist_ok=True)

    def _load(self, filepath: str) -> dict:
        if os.path.exists(filepath):
            with open(filepath, 'r') as f:
                return json.load(f)
        return {}

    def _save(self, filepath: str, data: dict):
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2, default=str)

    def _load_list(self, filepath: str) -> list:
        if os.path.exists(filepath):
            with open(filepath, 'r') as f:
                return json.load(f)
        return []

    def _save_list(self, filepath: str, data: list):
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2, default=str)

    def is_assistant_request(self, text: str) -> bool:
        keywords = [
            'task', 'todo', 'to-do', 'to do', 'note', 'write note', 'save note',
            'reminder', 'remind me', 'calendar', 'schedule', 'meeting', 'appointment',
            'goal', 'target', 'objective', 'shopping', 'buy', 'grocery',
            'budget', 'expense', 'spending', 'track spending',
            'set reminder', 'add task', 'new task', 'create task',
            'show tasks', 'show notes', 'show calendar', 'show goals',
            'complete task', 'done', 'finish task', 'delete task',
            'notes', 'lists', 'plans', 'itinerary'
        ]
        text_lower = text.lower()
        return any(kw in text_lower for kw in keywords)

    def handle(self, text: str) -> str:
        text_lower = text.lower().strip()

        if any(w in text_lower for w in ['add task', 'new task', 'create task', 'task']):
            return self._add_task(text)
        if any(w in text_lower for w in ['show tasks', 'my tasks', 'list tasks', 'todo', 'to-do']):
            return self._show_tasks()
        if any(w in text_lower for w in ['complete task', 'done', 'finish task', 'complete']):
            return self._complete_task(text)
        if any(w in text_lower for w in ['delete task', 'remove task']):
            return self._delete_task(text)

        if any(w in text_lower for w in ['note', 'write note', 'save note', 'add note']):
            return self._add_note(text)
        if any(w in text_lower for w in ['show notes', 'my notes', 'list notes']):
            return self._show_notes()
        if any(w in text_lower for w in ['search note', 'find note']):
            return self._search_notes(text)

        if any(w in text_lower for w in ['remind me', 'set reminder', 'reminder']):
            return self._add_reminder(text)
        if any(w in text_lower for w in ['show reminders', 'my reminders']):
            return self._show_reminders()

        if any(w in text_lower for w in ['schedule', 'add event', 'create event', 'calendar', 'meeting', 'appointment']):
            return self._add_event(text)
        if any(w in text_lower for w in ['show calendar', 'my calendar', 'upcoming']):
            return self._show_calendar()

        if any(w in text_lower for w in ['goal', 'target', 'set goal', 'add goal']):
            return self._add_goal(text)
        if any(w in text_lower for w in ['show goals', 'my goals']):
            return self._show_goals()

        if any(w in text_lower for w in ['shopping', 'add to shopping', 'buy', 'grocery']):
            return self._add_shopping(text)
        if any(w in text_lower for w in ['show shopping', 'shopping list']):
            return self._show_shopping()

        if any(w in text_lower for w in ['budget', 'track spending', 'add expense', 'expense']):
            return self._add_expense(text)
        if any(w in text_lower for w in ['show budget', 'spending summary', 'expenses']):
            return self._show_budget()

        return "I can help with tasks, notes, reminders, calendar, goals, shopping lists, and budgets. What would you like to do?"

    def _add_task(self, text: str) -> str:
        tasks = self._load_list(self.tasks_file)

        task_text = re.sub(r'(?i)(add|create|new|set)\s+(a\s+)?task\s*:?\s*', '', text).strip()
        task_text = re.sub(r'(?i)priority\s*:?\s*(high|medium|low)', '', task_text).strip()

        priority = "medium"
        if 'high' in text.lower() or 'urgent' in text.lower():
            priority = "high"
        elif 'low' in text.lower():
            priority = "low"

        due_match = re.search(r'(?:due|by|before)\s+(.+?)(?:\s*$)', text.lower())
        due_date = due_match.group(1).strip() if due_match else None

        task = {
            "id": len(tasks) + 1,
            "task": task_text or "Untitled task",
            "priority": priority,
            "due_date": due_date,
            "created": datetime.now().isoformat(),
            "completed": False
        }
        tasks.append(task)
        self._save_list(self.tasks_file, tasks)

        return f"✅ Task added: **{task['task']}** (Priority: {priority})" + (f" (Due: {due_date})" if due_date else "")

    def _show_tasks(self) -> str:
        tasks = self._load_list(self.tasks_file)
        pending = [t for t in tasks if not t.get('completed')]

        if not pending:
            return "📋 No pending tasks. You're all caught up!"

        response = "📋 **Your Tasks:**\n\n"
        for t in pending:
            icon = "🔴" if t.get('priority') == 'high' else "🟡" if t.get('priority') == 'medium' else "🟢"
            response += f"{icon} #{t['id']}: {t['task']}"
            if t.get('due_date'):
                response += f" (Due: {t['due_date']})"
            response += "\n"

        completed = len([t for t in tasks if t.get('completed')])
        response += f"\n{len(pending)} pending, {completed} completed"
        return response

    def _complete_task(self, text: str) -> str:
        tasks = self._load_list(self.tasks_file)
        id_match = re.search(r'#?(\d+)', text)
        if id_match:
            task_id = int(id_match.group(1))
            for t in tasks:
                if t['id'] == task_id:
                    t['completed'] = True
                    t['completed_at'] = datetime.now().isoformat()
                    self._save_list(self.tasks_file, tasks)
                    return f"✅ Task #{task_id} completed: {t['task']}"
            return f"Task #{task_id} not found."

        for t in reversed(tasks):
            if not t.get('completed'):
                t['completed'] = True
                t['completed_at'] = datetime.now().isoformat()
                self._save_list(self.tasks_file, tasks)
                return f"✅ Task completed: {t['task']}"
        return "No pending tasks to complete."

    def _delete_task(self, text: str) -> str:
        tasks = self._load_list(self.tasks_file)
        id_match = re.search(r'#?(\d+)', text)
        if id_match:
            task_id = int(id_match.group(1))
            tasks = [t for t in tasks if t['id'] != task_id]
            self._save_list(self.tasks_file, tasks)
            return f"🗑️ Task #{task_id} deleted."
        return "Please specify a task ID (e.g., 'delete task #3')."

    def _add_note(self, text: str) -> str:
        notes = self._load_list(self.notes_file)
        note_text = re.sub(r'(?i)(add|create|write|save)\s+(a\s+)?note\s*:?\s*', '', text).strip()

        title_match = re.search(r'(?:title|heading|titled?)\s*[:"]\s*([^"]+)', text.lower())
        title = title_match.group(1).strip() if title_match else note_text[:50]

        tags = []
        if 'important' in text.lower():
            tags.append('important')
        if 'work' in text.lower():
            tags.append('work')
        if 'personal' in text.lower():
            tags.append('personal')

        note = {
            "id": len(notes) + 1,
            "title": title,
            "content": note_text,
            "tags": tags,
            "created": datetime.now().isoformat()
        }
        notes.append(note)
        self._save_list(self.notes_file, notes)
        return f"📝 Note saved: **{note['title']}**" + (f" (Tags: {', '.join(tags)})" if tags else "")

    def _show_notes(self) -> str:
        notes = self._load_list(self.notes_file)
        if not notes:
            return "📝 No notes yet. Start by saying 'add note: ...'"

        response = "📝 **Your Notes:**\n\n"
        for n in notes[-10:]:
            tags_str = f" [{', '.join(n.get('tags', []))}]" if n.get('tags') else ""
            response += f"#{n['id']}: {n['title']}{tags_str}\n"
        return response

    def _search_notes(self, text: str) -> str:
        notes = self._load_list(self.notes_file)
        query = re.sub(r'(?i)(search|find|look)\s+(for\s+)?', '', text).strip().lower()
        matches = [n for n in notes if query in n.get('content', '').lower() or query in n.get('title', '').lower()]
        if not matches:
            return f"No notes found matching '{query}'."
        response = f"Found {len(matches)} note(s):\n\n"
        for n in matches:
            response += f"#{n['id']}: {n['title']}\n  {n['content'][:100]}...\n\n"
        return response

    def _add_reminder(self, text: str) -> str:
        reminders = self._load_list(self.reminders_file)
        reminder_text = re.sub(r'(?i)(remind me to?|set reminder|reminder)\s*', '', text).strip()

        when_match = re.search(r'(?:at|on|for|in)\s+(.+?)(?:\s*$)', text.lower())
        when = when_match.group(1).strip() if when_match else "later"

        reminder = {
            "id": len(reminders) + 1,
            "text": reminder_text,
            "when": when,
            "created": datetime.now().isoformat(),
            "active": True
        }
        reminders.append(reminder)
        self._save_list(self.reminders_file, reminders)
        return f"⏰ Reminder set: **{reminder_text}** ({when})"

    def _show_reminders(self) -> str:
        reminders = self._load_list(self.reminders_file)
        active = [r for r in reminders if r.get('active')]
        if not active:
            return "⏰ No active reminders."
        response = "⏰ **Your Reminders:**\n\n"
        for r in active:
            response += f"#{r['id']}: {r['text']} ({r.get('when', 'when?')})\n"
        return response

    def _add_event(self, text: str) -> str:
        calendar = self._load_list(self.calendar_file)
        event_text = re.sub(r'(?i)(schedule|add|create)\s+(an?\s+)?(event|meeting|appointment)\s*:?\s*', '', text).strip()

        when_match = re.search(r'(?:at|on|for)\s+(.+?)(?:\s*$)', text.lower())
        when = when_match.group(1).strip() if when_match else "TBD"

        event = {
            "id": len(calendar) + 1,
            "event": event_text,
            "datetime": when,
            "created": datetime.now().isoformat()
        }
        calendar.append(event)
        self._save_list(self.calendar_file, calendar)
        return f"📅 Event scheduled: **{event['event']}** at {when}"

    def _show_calendar(self) -> str:
        calendar = self._load_list(self.calendar_file)
        if not calendar:
            return "📅 No upcoming events."
        response = "📅 **Your Calendar:**\n\n"
        for e in calendar[-10:]:
            response += f"#{e['id']}: {e['event']} — {e.get('datetime', 'TBD')}\n"
        return response

    def _add_goal(self, text: str) -> str:
        goals = self._load_list(self.goals_file)
        goal_text = re.sub(r'(?i)(set|add|create|new)\s+(a\s+)?goal\s*:?\s*', '', text).strip()

        goal = {
            "id": len(goals) + 1,
            "goal": goal_text,
            "progress": 0,
            "created": datetime.now().isoformat(),
            "status": "active"
        }
        goals.append(goal)
        self._save_list(self.goals_file, goals)
        return f"🎯 Goal added: **{goal['goal']}**"

    def _show_goals(self) -> str:
        goals = self._load_list(self.goals_file)
        if not goals:
            return "🎯 No goals set yet."
        response = "🎯 **Your Goals:**\n\n"
        for g in goals:
            status = "✅" if g.get('status') == 'completed' else "🔄"
            response += f"{status} #{g['id']}: {g['goal']} ({g.get('progress', 0)}%)\n"
        return response

    def _add_shopping(self, text: str) -> str:
        shopping = self._load_list(self.shopping_file)
        item = re.sub(r'(?i)(add|buy|get|need|shopping)\s+(to\s+)?(shopping\s+)?(list\s*)?\s*', '', text).strip()
        if item:
            shopping.append({
                "item": item,
                "added": datetime.now().isoformat(),
                "bought": False
            })
            self._save_list(self.shopping_file, shopping)
            return f"🛒 Added to shopping list: **{item}**"
        return "What would you like to add to the shopping list?"

    def _show_shopping(self) -> str:
        shopping = self._load_list(self.shopping_file)
        pending = [s for s in shopping if not s.get('bought')]
        if not pending:
            return "🛒 Shopping list is empty!"
        response = "🛒 **Shopping List:**\n\n"
        for i, s in enumerate(pending, 1):
            response += f"☐ {s['item']}\n"
        return response

    def _add_expense(self, text: str) -> str:
        budget = self._load_list(self.budget_file)
        amount_match = re.search(r'\$?(\d+(?:\.\d{2})?)', text)
        amount = float(amount_match.group(1)) if amount_match else 0
        category_match = re.search(r'(?:for|category|type)\s+(\w+)', text.lower())
        category = category_match.group(1) if category_match else "general"

        expense = {
            "id": len(budget) + 1,
            "amount": amount,
            "category": category,
            "description": text[:100],
            "date": datetime.now().isoformat()
        }
        budget.append(expense)
        self._save_list(self.budget_file, budget)
        return f"💰 Expense tracked: ${amount:.2f} for {category}"

    def _show_budget(self) -> str:
        budget = self._load_list(self.budget_file)
        if not budget:
            return "💰 No expenses tracked yet."

        total = sum(e.get('amount', 0) for e in budget)
        categories = {}
        for e in budget:
            cat = e.get('category', 'general')
            categories[cat] = categories.get(cat, 0) + e.get('amount', 0)

        response = "💰 **Budget Summary:**\n\n"
        response += f"**Total Spent:** ${total:.2f}\n\n"
        response += "**By Category:**\n"
        for cat, amt in sorted(categories.items(), key=lambda x: -x[1]):
            response += f"  {cat}: ${amt:.2f}\n"
        return response
