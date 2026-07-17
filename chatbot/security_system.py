import os
import json
import hashlib
import time
import datetime
import secrets
from pathlib import Path


class SecuritySystem:
    ROLES = {
        "admin": {"manage_users", "manage_api_keys", "view_logs", "moderate", "chat", "configure"},
        "user": {"chat", "view_own_logs", "generate_own_key"},
        "guest": {"chat"},
    }

    def __init__(self, data_dir=".security"):
        self._data_dir = Path(data_dir)
        self._users_path = self._data_dir / "users.json"
        self._api_keys_path = self._data_dir / "api_keys.json"
        self._audit_path = self._data_dir / "audit_log.json"
        self._rate_limits_path = self._data_dir / "rate_limits.json"
        self._sessions_path = self._data_dir / "sessions.json"
        self._data_dir.mkdir(parents=True, exist_ok=True)
        self._load_or_create(self._users_path, {})
        self._load_or_create(self._api_keys_path, {})
        self._load_or_create(self._audit_path, [])
        self._load_or_create(self._rate_limits_path, {})
        self._load_or_create(self._sessions_path, {})

    def _load_or_create(self, path, default):
        if path.exists():
            return self._read(path)
        self._write(path, default)
        return default

    def _read(self, path):
        with open(path, "r") as f:
            return json.load(f)

    def _write(self, path, data):
        with open(path, "w") as f:
            json.dump(data, f, indent=2)

    @staticmethod
    def _hash_password(password, salt=None):
        if salt is None:
            salt = secrets.token_hex(16)
        dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 100_000)
        return f"{salt}${dk.hex()}"

    @staticmethod
    def _verify_password(password, stored):
        salt, _ = stored.split("$", 1)
        return secrets.compare_digest(
            SecuritySystem._hash_password(password, salt), stored
        )

    # ── User Management ──────────────────────────────────────────────

    def create_user(self, username, role="user", password=None):
        users = self._read(self._users_path)
        if username in users:
            raise ValueError(f"User '{username}' already exists")
        if role not in self.ROLES:
            raise ValueError(f"Unknown role '{role}'")
        hashed = self._hash_password(password) if password else None
        users[username] = {
            "role": role,
            "password": hashed,
            "created": datetime.datetime.now().isoformat(),
            "active": True,
        }
        self._write(self._users_path, users)
        self.log_action("system", "create_user", f"Created {role} user '{username}'")
        return users[username]

    def authenticate(self, username, password):
        users = self._read(self._users_path)
        user = users.get(username)
        if not user or not user["active"]:
            return False
        if user["password"] is None:
            return False
        return self._verify_password(password, user["password"])

    # ── Permissions ──────────────────────────────────────────────────

    def check_permission(self, username, action):
        users = self._read(self._users_path)
        user = users.get(username)
        if not user or not user["active"]:
            return False
        allowed = self.ROLES.get(user["role"], set())
        return action in allowed

    # ── API Keys ─────────────────────────────────────────────────────

    def generate_api_key(self, username):
        users = self._read(self._users_path)
        if username not in users:
            raise ValueError(f"Unknown user '{username}'")
        if not self.check_permission(username, "generate_own_key") and not self.check_permission(username, "manage_api_keys"):
            raise PermissionError("Insufficient permissions to generate API key")
        key = f"ak_{secrets.token_hex(24)}"
        keys = self._read(self._api_keys_path)
        keys[key] = {
            "username": username,
            "created": datetime.datetime.now().isoformat(),
            "active": True,
        }
        self._write(self._api_keys_path, keys)
        self.log_action(username, "generate_api_key", "API key generated")
        return key

    def validate_api_key(self, key):
        keys = self._read(self._api_keys_path)
        entry = keys.get(key)
        if not entry or not entry["active"]:
            return False
        users = self._read(self._users_path)
        user = users.get(entry["username"])
        return bool(user and user["active"])

    def revoke_api_key(self, key):
        keys = self._read(self._api_keys_path)
        if key not in keys:
            return False
        keys[key]["active"] = False
        self._write(self._api_keys_path, keys)
        self.log_action(keys[key]["username"], "revoke_api_key", f"Key revoked")
        return True

    # ── Audit Logging ────────────────────────────────────────────────

    def log_action(self, username, action, details=""):
        log = self._read(self._audit_path)
        log.append({
            "timestamp": datetime.datetime.now().isoformat(),
            "username": username,
            "action": action,
            "details": details,
        })
        self._write(self._audit_path, log)

    def get_audit_log(self, limit=50):
        log = self._read(self._audit_path)
        recent = log[-limit:]
        lines = [f"[{e['timestamp']}] {e['username']}: {e['action']} - {e['details']}" for e in recent]
        return "\n".join(lines) if lines else "No audit entries."

    # ── Rate Limiting ────────────────────────────────────────────────

    def check_rate_limit(self, identifier, limit=30, window=60):
        data = self._read(self._rate_limits_path)
        now = time.time()
        entry = data.get(identifier, {"timestamps": []})
        entry["timestamps"] = [t for t in entry["timestamps"] if now - t < window]
        if len(entry["timestamps"]) >= limit:
            self._write(self._rate_limits_path, data)
            return False
        entry["timestamps"].append(now)
        data[identifier] = entry
        self._write(self._rate_limits_path, data)
        return True

    # ── Sessions ─────────────────────────────────────────────────────

    def create_session(self, username):
        sessions = self._read(self._sessions_path)
        token = secrets.token_hex(32)
        sessions[token] = {
            "username": username,
            "created": datetime.datetime.now().isoformat(),
            "last_active": datetime.datetime.now().isoformat(),
        }
        self._write(self._sessions_path, sessions)
        return token

    def validate_session(self, token, max_age_seconds=3600):
        sessions = self._read(self._sessions_path)
        session = sessions.get(token)
        if not session:
            return None
        created = datetime.datetime.fromisoformat(session["created"])
        if (datetime.datetime.now() - created).total_seconds() > max_age_seconds:
            del sessions[token]
            self._write(self._sessions_path, sessions)
            return None
        session["last_active"] = datetime.datetime.now().isoformat()
        self._write(self._sessions_path, sessions)
        return session["username"]

    def destroy_session(self, token):
        sessions = self._read(self._sessions_path)
        if token in sessions:
            del sessions[token]
            self._write(self._sessions_path, sessions)
            return True
        return False

    # ── Request Handling ─────────────────────────────────────────────

    SECURITY_KEYWORDS = {
        "who", "user", "admin", "login", "logout", "password", "auth",
        "permission", "access", "ban", "unban", "key", "apikey", "api_key",
        "security", "role", "session", "audit", "revoke", "create user",
        "list users", "rate limit", "protect", "block", "unblock",
    }

    def is_security_request(self, text):
        lower = text.lower().strip()
        return any(kw in lower for kw in self.SECURITY_KEYWORDS)

    def handle(self, text, current_user="guest"):
        if not self.is_security_request(text):
            return ""
        lower = text.lower().strip()

        if "who" in lower and ("am i" in lower or "is" in lower):
            users = self._read(self._users_path)
            user = users.get(current_user)
            if user:
                return f"You are '{current_user}' with role '{user['role']}'."
            return f"User '{current_user}' not found."

        if "list users" in lower:
            if not self.check_permission(current_user, "manage_users"):
                return "Permission denied: requires admin role."
            users = self._read(self._users_path)
            lines = [f"- {u} (role={d['role']}, active={d['active']})" for u, d in users.items()]
            return "Users:\n" + "\n".join(lines) if lines else "No users."

        if "create user" in lower:
            if not self.check_permission(current_user, "manage_users"):
                return "Permission denied: requires admin role."
            parts = text.split()
            try:
                idx = parts.index("user") + 1
                uname = parts[idx]
                role = parts[idx + 1] if idx + 1 < len(parts) else "user"
                self.create_user(uname, role=role)
                return f"User '{uname}' created with role '{role}'."
            except (ValueError, IndexError):
                return "Usage: create user <username> [role]"

        if "generate" in lower and ("key" in lower or "api" in lower):
            try:
                key = self.generate_api_key(current_user)
                return f"API key generated: {key}"
            except (ValueError, PermissionError) as e:
                return str(e)

        if "revoke" in lower and ("key" in lower or "api" in lower):
            if not self.check_permission(current_user, "manage_api_keys"):
                return "Permission denied: requires admin role."
            parts = text.split()
            for part in parts:
                if part.startswith("ak_"):
                    if self.revoke_api_key(part):
                        return f"API key revoked."
                    return "Key not found."
            return "Usage: revoke api key <key>"

        if "permission" in lower or "access" in lower:
            if not self.check_permission(current_user, "view_logs"):
                return "Permission denied: requires admin role."
            users = self._read(self._users_path)
            lines = []
            for u, d in users.items():
                perms = ", ".join(sorted(self.ROLES.get(d["role"], set())))
                lines.append(f"- {u}: {perms}")
            return "Permissions:\n" + "\n".join(lines) if lines else "No users."

        if "audit" in lower or "log" in lower:
            if not self.check_permission(current_user, "view_logs"):
                return "Permission denied: requires admin role."
            return self.get_audit_log(limit=20)

        if "ban" in lower and "unban" not in lower:
            if not self.check_permission(current_user, "manage_users"):
                return "Permission denied: requires admin role."
            parts = text.split()
            for part in parts:
                if part not in ("ban", "user", "the"):
                    users = self._read(self._users_path)
                    if part in users:
                        users[part]["active"] = False
                        self._write(self._users_path, users)
                        self.log_action(current_user, "ban_user", f"Banned '{part}'")
                        return f"User '{part}' has been banned."
                    return f"User '{part}' not found."

        if "unban" in lower:
            if not self.check_permission(current_user, "manage_users"):
                return "Permission denied: requires admin role."
            parts = text.split()
            for part in parts:
                if part not in ("unban", "user", "the"):
                    users = self._read(self._users_path)
                    if part in users:
                        users[part]["active"] = True
                        self._write(self._users_path, users)
                        self.log_action(current_user, "unban_user", f"Unbanned '{part}'")
                        return f"User '{part}' has been unbanned."
                    return f"User '{part}' not found."

        if "role" in lower and ("change" in lower or "set" in lower or "update" in lower):
            if not self.check_permission(current_user, "manage_users"):
                return "Permission denied: requires admin role."
            parts = text.split()
            try:
                u_idx = parts.index("user") + 1
                r_idx = parts.index("role") + 1
                uname = parts[u_idx]
                new_role = parts[r_idx]
                users = self._read(self._users_path)
                if uname not in users:
                    return f"User '{uname}' not found."
                if new_role not in self.ROLES:
                    return f"Unknown role '{new_role}'. Valid: {', '.join(self.ROLES)}"
                users[uname]["role"] = new_role
                self._write(self._users_path, users)
                self.log_action(current_user, "change_role", f"Changed '{uname}' to '{new_role}'")
                return f"User '{uname}' role changed to '{new_role}'."
            except (ValueError, IndexError):
                return "Usage: change user <username> role <role>"

        return "I can help with security tasks: user management, API keys, audit logs, permissions, banning, and rate limits."
