"""
HR Management Module
Employee records, leave requests, performance tracking
"""
import json
import os
from datetime import datetime


class HRManager:
    def __init__(self, data_dir=".business"):
        self.data_dir = data_dir
        os.makedirs(data_dir, exist_ok=True)
        self.employees_file = os.path.join(data_dir, "employees.json")
        self.leave_file = os.path.join(data_dir, "leave_requests.json")
        self.performance_file = os.path.join(data_dir, "performance.json")
        self.employees = self._load_json(self.employees_file)
        self.leave_requests = self._load_json(self.leave_file)
        self.performance = self._load_json(self.performance_file)

    def _load_json(self, filepath):
        if os.path.exists(filepath):
            with open(filepath, "r") as f:
                return json.load(f)
        return {}

    def _save_json(self, filepath, data):
        with open(filepath, "w") as f:
            json.dump(data, f, indent=2)

    def is_hr_request(self, text):
        text_lower = text.lower()
        keywords = [
            "employee", "staff", "hire", "leave", "vacation",
            "sick day", "performance", "review", "hr", "human resource",
            "team member", "personnel"
        ]
        return any(k in text_lower for k in keywords)

    def handle(self, text):
        text_lower = text.lower().strip()

        if any(w in text_lower for w in ["list employee", "show employee", "all employee", "team"]):
            return self.list_employees()
        if "leave" in text_lower and ("list" in text_lower or "show" in text_lower or "pending" in text_lower):
            return self.list_leave_requests()
        if "approve" in text_lower and "leave" in text_lower:
            return self.approve_leave(text_lower)
        if "reject" in text_lower and "leave" in text_lower:
            return self.reject_leave(text_lower)
        if "performance" in text_lower and ("list" in text_lower or "show" in text_lower):
            return self.list_performance()
        if "add performance" in text_lower or "review employee" in text_lower:
            return self.add_performance_review(text_lower)

        add_emp_match = re.search(r"(?:add|hire|register)\s+(?:employee|staff|member)\s*(?::)?\s*(.*)", text_lower)
        if add_emp_match:
            return self.add_employee(add_emp_match.group(1).strip())

        leave_match = re.search(r"(?:request|apply|add)\s+leave\s*(?::)?\s*(.*)", text_lower)
        if leave_match:
            return self.request_leave(leave_match.group(1).strip())

        return self._help_text()

    def add_employee(self, text):
        parts = [p.strip() for p in text.split(",")]
        if len(parts) < 3:
            return (
                "Format: Add employee: Name, Position, Department, Start Date, Salary\n"
                "Example: Add employee: John Smith, Developer, Engineering, 2026-01-15, $75000"
            )

        name = parts[0]
        position = parts[1]
        department = parts[2]
        start_date = parts[3] if len(parts) > 3 else "TBD"
        salary = parts[4].replace("$", "").replace(",", "") if len(parts) > 4 else "0"

        emp_id = f"EMP-{len(self.employees) + 1:04d}"
        employee = {
            "id": emp_id,
            "name": name,
            "position": position,
            "department": department,
            "start_date": start_date,
            "salary": salary,
            "status": "active",
            "created": datetime.now().isoformat(),
        }
        self.employees[emp_id] = employee
        self._save_json(self.employees_file, self.employees)

        return (
            f"Employee Added\n"
            f"  ID: {emp_id}\n"
            f"  Name: {name}\n"
            f"  Position: {position}\n"
            f"  Department: {department}\n"
            f"  Start Date: {start_date}"
        )

    def list_employees(self):
        if not self.employees:
            return "No employees yet."

        lines = ["Employees:", "=" * 50]
        for eid, emp in self.employees.items():
            status_icon = "✅" if emp["status"] == "active" else "❌"
            lines.append(
                f"  {status_icon} {eid} | {emp['name']} | "
                f"{emp['position']} | {emp['department']}"
            )
        return "\n".join(lines)

    def request_leave(self, text):
        parts = [p.strip() for p in text.split(",")]
        if len(parts) < 3:
            return (
                "Format: Request leave: Employee Name, Leave Type, Start Date, End Date, Reason\n"
                "Example: Request leave: John Smith, Vacation, 2026-03-01, 2026-03-05, Family trip"
            )

        employee = parts[0]
        leave_type = parts[1]
        start_date = parts[2]
        end_date = parts[3] if len(parts) > 3 else start_date
        reason = parts[4] if len(parts) > 4 else "Not specified"

        leave_id = f"LV-{len(self.leave_requests) + 1:04d}"
        request = {
            "id": leave_id,
            "employee": employee,
            "type": leave_type,
            "start_date": start_date,
            "end_date": end_date,
            "reason": reason,
            "status": "pending",
            "created": datetime.now().isoformat(),
        }
        self.leave_requests[leave_id] = request
        self._save_json(self.leave_file, self.leave_requests)

        return (
            f"Leave Request Submitted\n"
            f"  ID: {leave_id}\n"
            f"  Employee: {employee}\n"
            f"  Type: {leave_type}\n"
            f"  Dates: {start_date} to {end_date}\n"
            f"  Reason: {reason}"
        )

    def list_leave_requests(self):
        if not self.leave_requests:
            return "No leave requests."

        lines = ["Leave Requests:", "=" * 50]
        for lid, req in self.leave_requests.items():
            status_icon = {"pending": "⏳", "approved": "✅", "rejected": "❌"}.get(req["status"], "❓")
            lines.append(
                f"  {status_icon} {lid} | {req['employee']} | "
                f"{req['type']} | {req['start_date']} to {req['end_date']} | "
                f"{req['status'].upper()}"
            )
        return "\n".join(lines)

    def approve_leave(self, text):
        match = re.search(r"approve\s+leave\s+([\w-]+)", text)
        if not match:
            return "Format: Approve leave LV-0001"

        lid = match.group(1).upper()
        if lid not in self.leave_requests:
            return f"Leave request {lid} not found."

        self.leave_requests[lid]["status"] = "approved"
        self._save_json(self.leave_file, self.leave_requests)
        return f"Leave request {lid} approved!"

    def reject_leave(self, text):
        match = re.search(r"reject\s+leave\s+([\w-]+)", text)
        if not match:
            return "Format: Reject leave LV-0001"

        lid = match.group(1).upper()
        if lid not in self.leave_requests:
            return f"Leave request {lid} not found."

        self.leave_requests[lid]["status"] = "rejected"
        self._save_json(self.leave_file, self.leave_requests)
        return f"Leave request {lid} rejected."

    def add_performance_review(self, text):
        parts = [p.strip() for p in text.split(",")]
        if len(parts) < 3:
            return (
                "Format: Add performance: Employee Name, Rating (1-5), Comments\n"
                "Example: Add performance: John Smith, 4, Excellent work on project X"
            )

        employee = parts[0]
        try:
            rating = int(parts[1])
            if not 1 <= rating <= 5:
                return "Rating must be between 1 and 5."
        except ValueError:
            return "Rating must be a number (1-5)."

        comments = parts[2] if len(parts) > 3 else "No comments"

        review_id = f"REV-{len(self.performance) + 1:04d}"
        review = {
            "id": review_id,
            "employee": employee,
            "rating": rating,
            "comments": comments,
            "date": datetime.now().isoformat(),
        }
        self.performance[review_id] = review
        self._save_json(self.performance_file, self.performance)

        stars = "⭐" * rating
        return (
            f"Performance Review Added\n"
            f"  ID: {review_id}\n"
            f"  Employee: {employee}\n"
            f"  Rating: {stars} ({rating}/5)\n"
            f"  Comments: {comments}"
        )

    def list_performance(self):
        if not self.performance:
            return "No performance reviews."

        lines = ["Performance Reviews:", "=" * 50]
        for rid, rev in self.performance.items():
            stars = "⭐" * rev["rating"]
            lines.append(
                f"  {rid} | {rev['employee']} | {stars} | {rev['comments'][:40]}"
            )
        return "\n".join(lines)

    def _help_text(self):
        return (
            "HR Management Commands:\n"
            "  Add employee: Name, Position, Department, Start Date, Salary\n"
            "  List employees / Show team\n"
            "  Request leave: Employee, Type, Start Date, End Date, Reason\n"
            "  List leave requests / Show pending leave\n"
            "  Approve leave LV-0001 / Reject leave LV-0001\n"
            "  Add performance: Employee, Rating (1-5), Comments\n"
            "  Show performance reviews"
        )


import re
