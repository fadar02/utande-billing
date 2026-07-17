import os
import json
import re
import shutil
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any


class WorkflowAutomation:
    """Workflow and task automation with scheduling, reminders, and file operations."""

    def __init__(self, data_dir: str = ".workflows"):
        self.data_dir = data_dir
        self.workflows_file = os.path.join(data_dir, "workflows.json")
        self.tasks_file = os.path.join(data_dir, "scheduled_tasks.json")
        self.reminders_file = os.path.join(data_dir, "reminders.json")
        os.makedirs(data_dir, exist_ok=True)
        self.workflows = self._load_json(self.workflows_file, {})
        self.scheduled_tasks = self._load_json(self.tasks_file, [])
        self.reminders = self._load_json(self.reminders_file, [])

    def _load_json(self, filepath: str, default: Any) -> Any:
        if os.path.exists(filepath):
            try:
                with open(filepath, "r") as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError):
                pass
        return default

    def _save_json(self, filepath: str, data: Any):
        with open(filepath, "w") as f:
            json.dump(data, f, indent=2, default=str)

    def _save_workflows(self):
        self._save_json(self.workflows_file, self.workflows)

    def _save_tasks(self):
        self._save_json(self.tasks_file, self.scheduled_tasks)

    def _save_reminders(self):
        self._save_json(self.reminders_file, self.reminders)

    def _generate_id(self) -> str:
        return datetime.now().strftime("%Y%m%d%H%M%S%f")

    def is_workflow_request(self, text: str) -> bool:
        text_lower = text.lower()
        keywords = [
            "workflow", "automate", "automation", "automated", "schedule",
            "task automation", "create workflow", "run workflow",
            "execute workflow", "list workflow", "show workflow",
            "email draft", "compose email", "draft email", "send email",
            "organize files", "file organization", "sort files", "categorize files",
            "report", "generate report", "create report",
            "reminder", "remind me", "scheduled task", "cron",
            "pipeline", "batch", "multi-step", "sequence",
        ]
        return any(kw in text_lower for kw in keywords)

    def handle(self, text: str) -> str:
        text_lower = text.lower().strip()

        if any(w in text_lower for w in ["create workflow", "new workflow", "add workflow"]):
            return self._handle_create_workflow(text)
        if any(w in text_lower for w in ["list workflow", "show workflow", "my workflow"]):
            return self.list_workflows()
        if any(w in text_lower for w in ["execute workflow", "run workflow", "start workflow"]):
            return self._handle_execute_workflow(text)
        if any(w in text_lower for w in ["delete workflow", "remove workflow"]):
            return self._handle_delete_workflow(text)
        if any(w in text_lower for w in ["email draft", "compose email", "draft email"]):
            return self._handle_email_draft(text)
        if any(w in text_lower for w in ["organize files", "sort files", "categorize files"]):
            return self._handle_file_organization(text)
        if any(w in text_lower for w in ["generate report", "create report", "build report"]):
            return self._handle_report(text)
        if any(w in text_lower for w in ["schedule task", "scheduled task", "add schedule"]):
            return self._handle_schedule_task(text)
        if any(w in text_lower for w in ["list schedule", "show schedule", "my tasks"]):
            return self.list_scheduled_tasks()
        if any(w in text_lower for w in ["remind me", "set reminder", "create reminder"]):
            return self._handle_reminder(text)
        if any(w in text_lower for w in ["show reminders", "my reminders", "list reminders"]):
            return self._show_reminders()

        return (
            "Workflow commands:\n"
            "  create workflow <name> — Create a new workflow\n"
            "  list workflows — Show all workflows\n"
            "  execute workflow <name> — Run a workflow\n"
            "  email draft <to>: <subject> — Draft an email\n"
            "  organize files <directory> — Categorize files in a directory\n"
            "  generate report <topic> — Generate a report\n"
            "  schedule task <task> at <time> — Schedule a task\n"
            "  remind me <text> at <time> — Set a reminder"
        )

    # --- Workflow CRUD ---

    def create_workflow(self, name: str, steps: List[Dict], triggers: List[str] = None) -> str:
        wf_id = self._generate_id()
        workflow = {
            "id": wf_id,
            "name": name,
            "steps": steps,
            "triggers": triggers or [],
            "created_at": datetime.now().isoformat(),
            "last_run": None,
            "run_count": 0,
            "status": "active",
        }
        self.workflows[name] = workflow
        self._save_workflows()
        step_summary = "\n".join(
            f"  {i+1}. [{s.get('type', 'unknown')}] {s.get('description', s.get('action', ''))}"
            for i, s in enumerate(steps)
        )
        return f"Workflow '{name}' created with {len(steps)} steps:\n{step_summary}"

    def list_workflows(self) -> str:
        if not self.workflows:
            return "No workflows found. Create one with: create workflow <name>"
        lines = ["=== Workflows ==="]
        for name, wf in self.workflows.items():
            lines.append(
                f"  • {name} — {len(wf['steps'])} steps, "
                f"runs: {wf['run_count']}, status: {wf['status']}"
            )
        return "\n".join(lines)

    def execute_workflow(self, name: str) -> str:
        if name not in self.workflows:
            available = ", ".join(self.workflows.keys()) or "none"
            return f"Workflow '{name}' not found. Available: {available}"

        wf = self.workflows[name]
        if wf["status"] != "active":
            return f"Workflow '{name}' is {wf['status']} and cannot be executed."

        results = []
        for i, step in enumerate(wf["steps"], 1):
            step_result = self._execute_step(step)
            results.append(f"  Step {i}: {step_result}")

        wf["last_run"] = datetime.now().isoformat()
        wf["run_count"] += 1
        self._save_workflows()

        summary = "\n".join(results)
        return f"Workflow '{name}' executed successfully:\n{summary}"

    def _execute_step(self, step: Dict) -> str:
        step_type = step.get("type", "unknown")

        if step_type == "email":
            to = step.get("to", "recipient@example.com")
            subject = step.get("subject", "No Subject")
            body = step.get("body", "")
            draft_path = os.path.join(self.data_dir, f"draft_{self._generate_id()}.json")
            draft = {"to": to, "subject": subject, "body": body, "created_at": datetime.now().isoformat()}
            self._save_json(draft_path, draft)
            return f"Email drafted to {to} — Subject: {subject} (saved to {draft_path})"

        elif step_type == "file_organize":
            directory = step.get("directory", ".")
            return self._organize_directory(directory)

        elif step_type == "report":
            topic = step.get("topic", "General")
            return self._generate_report_content(topic, step.get("data_sources", []))

        elif step_type == "delay":
            seconds = step.get("seconds", 1)
            return f"Delayed {seconds} seconds (simulated)"

        elif step_type == "log":
            message = step.get("message", "Step executed")
            log_path = os.path.join(self.data_dir, "execution.log")
            with open(log_path, "a") as f:
                f.write(f"[{datetime.now().isoformat()}] {message}\n")
            return f"Logged: {message}"

        else:
            return f"Unknown step type '{step_type}' (skipped)"

    # --- Email Drafts ---

    def _handle_email_draft(self, text: str) -> str:
        match = re.search(
            r"(?:email draft|compose email|draft email)\s+(?:to\s+)?(.+?):\s*(.+)",
            text, re.IGNORECASE,
        )
        if not match:
            return (
                "Usage: email draft <to>: <subject>\n"
                "Example: email draft john@example.com: Meeting Tomorrow"
            )
        to = match.group(1).strip()
        subject = match.group(2).strip()

        draft = {
            "id": self._generate_id(),
            "to": to,
            "subject": subject,
            "body": "",
            "created_at": datetime.now().isoformat(),
            "status": "draft",
        }
        draft_path = os.path.join(self.data_dir, f"draft_{draft['id']}.json")
        self._save_json(draft_path, draft)

        return (
            f"Email draft created:\n"
            f"  To: {to}\n"
            f"  Subject: {subject}\n"
            f"  Saved to: {draft_path}"
        )

    # --- File Organization ---

    def _handle_file_organization(self, text: str) -> str:
        match = re.search(r"(?:organize|sort|categorize)\s+files\s+(.+)", text, re.IGNORECASE)
        directory = match.group(1).strip() if match else "."
        return self._organize_directory(directory)

    def _organize_directory(self, directory: str) -> str:
        if not os.path.isdir(directory):
            return f"Directory not found: {directory}"

        categories = {
            "Documents": [".pdf", ".doc", ".docx", ".txt", ".md", ".rtf", ".odt", ".csv", ".xlsx", ".pptx"],
            "Images": [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".svg", ".webp", ".ico", ".tiff"],
            "Audio": [".mp3", ".wav", ".flac", ".aac", ".ogg", ".wma", ".m4a"],
            "Video": [".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm"],
            "Code": [".py", ".js", ".ts", ".java", ".c", ".cpp", ".h", ".go", ".rs", ".rb", ".php", ".html", ".css", ".json", ".xml"],
            "Archives": [".zip", ".tar", ".gz", ".rar", ".7z", ".bz2"],
            "Data": [".sql", ".db", ".sqlite", ".parquet", ".avro"],
        }

        moved = {}
        for filename in os.listdir(directory):
            filepath = os.path.join(directory, filename)
            if not os.path.isfile(filepath):
                continue

            ext = os.path.splitext(filename)[1].lower()
            dest_folder = "Other"
            for cat, extensions in categories.items():
                if ext in extensions:
                    dest_folder = cat
                    break

            dest_dir = os.path.join(directory, dest_folder)
            os.makedirs(dest_dir, exist_ok=True)

            dest_path = os.path.join(dest_dir, filename)
            if not os.path.exists(dest_path):
                shutil.move(filepath, dest_path)
                moved.setdefault(dest_folder, []).append(filename)

        if not moved:
            return f"No files to organize in {directory}."

        lines = [f"Organized files in {directory}:"]
        for folder, files in sorted(moved.items()):
            lines.append(f"  {folder}/: {', '.join(files)}")
        return "\n".join(lines)

    # --- Report Generation ---

    def _handle_report(self, text: str) -> str:
        match = re.search(r"(?:generate|create|build)\s+report\s+(.+)", text, re.IGNORECASE)
        topic = match.group(1).strip() if match else "General"
        return self._generate_report_content(topic, [])

    def _generate_report_content(self, topic: str, data_sources: List[str]) -> str:
        now = datetime.now()
        report_lines = [
            f"=== Report: {topic} ===",
            f"Generated: {now.strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "Summary:",
            f"  This report covers '{topic}' generated at {now.strftime('%Y-%m-%d')}.",
        ]

        if data_sources:
            report_lines.append("\nData Sources:")
            for src in data_sources:
                if os.path.exists(src):
                    report_lines.append(f"  ✓ {src}")
                else:
                    report_lines.append(f"  ✗ {src} (not found)")

        report_lines.extend([
            "",
            "Workflow Status:",
            f"  Total workflows: {len(self.workflows)}",
            f"  Active: {sum(1 for w in self.workflows.values() if w['status'] == 'active')}",
            f"  Scheduled tasks: {len(self.scheduled_tasks)}",
            f"  Active reminders: {sum(1 for r in self.reminders if r.get('active', True))}",
        ])

        report = "\n".join(report_lines)
        report_path = os.path.join(self.data_dir, f"report_{self._generate_id()}.txt")
        with open(report_path, "w") as f:
            f.write(report)

        return f"{report}\n\nReport saved to: {report_path}"

    # --- Scheduled Tasks ---

    def add_scheduled_task(self, task: str, schedule: str, action: str) -> str:
        task_entry = {
            "id": self._generate_id(),
            "task": task,
            "schedule": schedule,
            "action": action,
            "created_at": datetime.now().isoformat(),
            "active": True,
            "last_run": None,
        }
        self.scheduled_tasks.append(task_entry)
        self._save_tasks()
        return f"Scheduled task '{task}' created.\n  Schedule: {schedule}\n  Action: {action}"

    def list_scheduled_tasks(self) -> str:
        if not self.scheduled_tasks:
            return "No scheduled tasks."
        lines = ["=== Scheduled Tasks ==="]
        for t in self.scheduled_tasks:
            status = "active" if t.get("active", True) else "paused"
            lines.append(
                f"  [{status}] {t['task']}\n"
                f"    Schedule: {t['schedule']} | Action: {t['action']}"
            )
        return "\n".join(lines)

    def _handle_schedule_task(self, text: str) -> str:
        match = re.search(
            r"schedule\s+task\s+(.+?)\s+(?:at|every|on)\s+(.+)",
            text, re.IGNORECASE,
        )
        if not match:
            return "Usage: schedule task <task description> at <time/schedule>"
        task = match.group(1).strip()
        schedule = match.group(2).strip()
        return self.add_scheduled_task(task, schedule, "notify")

    # --- Reminders with Actions ---

    def create_reminder_with_action(self, text: str, action_type: str, details: Dict = None) -> str:
        reminder_id = self._generate_id()
        reminder = {
            "id": reminder_id,
            "text": text,
            "action_type": action_type,
            "details": details or {},
            "created_at": datetime.now().isoformat(),
            "active": True,
        }
        self.reminders.append(reminder)
        self._save_reminders()
        return (
            f"Reminder set: \"{text}\"\n"
            f"  Action: {action_type}\n"
            f"  ID: {reminder_id}"
        )

    def _handle_reminder(self, text: str) -> str:
        match = re.search(
            r"(?:remind me|set reminder|create reminder)\s+(.+?)(?:\s+at\s+(.+))?$",
            text, re.IGNORECASE,
        )
        if not match:
            return "Usage: remind me <text> at <time>"
        reminder_text = match.group(1).strip()
        schedule = match.group(2).strip() if match.group(2) else "now"

        action_match = re.search(r"(?:to|and)\s+(send email|open file|run workflow|create task)\s*(.*)", text, re.IGNORECASE)
        action_type = "notify"
        details = {}
        if action_match:
            action_type = action_match.group(1).strip().lower()
            details["extra"] = action_match.group(2).strip()

        details["schedule"] = schedule
        return self.create_reminder_with_action(reminder_text, action_type, details)

    def _show_reminders(self) -> str:
        active = [r for r in self.reminders if r.get("active", True)]
        if not active:
            return "No active reminders."
        lines = ["=== Reminders ==="]
        for r in active:
            lines.append(
                f"  [{r['action_type']}] {r['text']}\n"
                f"    Created: {r['created_at']}\n"
                f"    Details: {r.get('details', {})}"
            )
        return "\n".join(lines)

    def _handle_delete_workflow(self, text: str) -> str:
        match = re.search(r"(?:delete|remove)\s+workflow\s+(.+)", text, re.IGNORECASE)
        if not match:
            return "Usage: delete workflow <name>"
        name = match.group(1).strip()
        if name in self.workflows:
            del self.workflows[name]
            self._save_workflows()
            return f"Workflow '{name}' deleted."
        return f"Workflow '{name}' not found."
