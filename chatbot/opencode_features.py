import os
import re
import subprocess
import glob
import json
from typing import Optional, Dict, List, Tuple
from pathlib import Path

class OpenCodeFeatures:
    """Implements opencode-like features: file ops, code search, git, web."""

    def __init__(self):
        self.workspace_dir = os.getcwd()
        self.history = []

    def is_opencode_request(self, text: str) -> bool:
        """Check if the input is an opencode-like request."""
        keywords = [
            'create file', 'write file', 'make file', 'new file',
            'read file', 'show file', 'open file', 'cat file',
            'edit file', 'modify file', 'update file',
            'search', 'find', 'grep', 'look for',
            'git', 'commit', 'status', 'diff', 'log', 'branch',
            'fetch', 'download', 'web', 'search web', 'google',
            'list files', 'show files', 'directory', 'ls',
            'delete file', 'remove file',
            'copy file', 'move file',
            'help me with', 'work on', 'fix', 'debug',
            'create a file', 'write a file', 'make a file',
            'read a file', 'show a file', 'open a file',
            'edit a file', 'modify a file', 'update a file',
            'delete a file', 'remove a file'
        ]
        text_lower = text.lower()
        return any(keyword in text_lower for keyword in keywords)

    def detect_operation(self, text: str) -> Tuple[str, Dict]:
        """Detect what operation the user wants."""
        text_lower = text.lower().strip()
        details = {}

        if any(word in text_lower for word in ['create file', 'write file', 'make file', 'new file', 'create a', 'write a', 'make a']):
            details['action'] = 'create'
            filename_match = re.search(r'(?:file|named?|called?)\s+["\']?([^\s"\']+\.\w+)["\']?', text_lower)
            if filename_match:
                details['filename'] = filename_match.group(1)
            else:
                words = text_lower.split()
                for i, word in enumerate(words):
                    if '.' in word and len(word.split('.')[-1]) <= 5:
                        details['filename'] = word.strip('"\'')
                        break
            content_match = re.search(r'(?:with|containing|content)\s+["\'](.+?)["\']', text_lower)
            if not content_match:
                content_match = re.search(r'(?:with|containing|content)\s+(.+?)(?:\s*$)', text_lower)
                if content_match:
                    details['content'] = content_match.group(1).strip()
            else:
                details['content'] = content_match.group(1)
            return 'file_create', details

        if any(word in text_lower for word in ['read file', 'show file', 'open file', 'cat file', 'view file', 'read the']):
            filename_match = re.search(r'(?:file|named?|called?)\s+["\']?([^"\']+\.\w+)["\']?', text_lower)
            if filename_match:
                details['filename'] = filename_match.group(1)
            else:
                words = text_lower.split()
                for word in words:
                    if '.' in word and len(word.split('.')[-1]) <= 5:
                        details['filename'] = word.strip('"\'')
                        break
            return 'file_read', details

        if any(word in text_lower for word in ['edit file', 'modify file', 'update file', 'change file', 'replace in']):
            filename_match = re.search(r'(?:file|named?|called?)\s+["\']?([^"\']+\.\w+)["\']?', text_lower)
            if filename_match:
                details['filename'] = filename_match.group(1)
            old_match = re.search(r'(?:replace|change|swap)\s+["\'](.+?)["\']', text_lower)
            if old_match:
                details['old_text'] = old_match.group(1)
            new_match = re.search(r'(?:with|to|into)\s+["\'](.+?)["\']', text_lower)
            if new_match:
                details['new_text'] = new_match.group(1)
            return 'file_edit', details

        if any(word in text_lower for word in ['delete file', 'remove file', 'erase file']):
            filename_match = re.search(r'(?:file|named?|called?)\s+["\']?([^"\']+\.\w+)["\']?', text_lower)
            if filename_match:
                details['filename'] = filename_match.group(1)
            return 'file_delete', details

        if any(word in text_lower for word in ['list files', 'show files', 'directory', 'ls', 'dir', 'what files', 'files in']):
            path_match = re.search(r'(?:in|from|of)\s+["\']?([^"\']+)["\']?', text_lower)
            details['path'] = path_match.group(1) if path_match else '.'
            return 'file_list', details

        if any(word in text_lower for word in ['search', 'find', 'grep', 'look for', 'find in', 'search for']):
            query_match = re.search(r'(?:search|find|grep)\s+(?:for\s+)?["\']?(.+?)["\']?\s*$', text_lower)
            if query_match:
                details['query'] = query_match.group(1).strip()
            else:
                words = text_lower.split()
                skip_words = {'for', 'search', 'find', 'grep', 'look', 'in', 'from'}
                query_words = []
                found_keyword = False
                for word in words:
                    if not found_keyword and word in skip_words:
                        found_keyword = True
                        continue
                    if found_keyword:
                        query_words.append(word)
                if query_words:
                    details['query'] = ' '.join(query_words)
            path_match = re.search(r'(?:in|from)\s+["\']?([^"\']+)["\']?', text_lower)
            details['path'] = path_match.group(1) if path_match else '.'
            ext_match = re.search(r'\.(\w+)\s+(?:files|only|ext)', text_lower)
            if ext_match:
                details['extension'] = ext_match.group(1)
            return 'code_search', details

        if any(word in text_lower for word in ['git status', 'git status', 'repo status', 'repository status']):
            return 'git_status', details

        if any(word in text_lower for word in ['git commit', 'commit', 'save changes', 'save work']):
            msg_match = re.search(r'(?:message|msg|m)\s+["\'](.+?)["\']', text_lower)
            if msg_match:
                details['message'] = msg_match.group(1)
            else:
                words = text_lower.split()
                for i, word in enumerate(words):
                    if word in ['commit', 'message', 'msg'] and i + 1 < len(words):
                        remaining = ' '.join(words[i + 1:]).strip('"\'')
                        if remaining:
                            details['message'] = remaining
                            break
            return 'git_commit', details

        if any(word in text_lower for word in ['git diff', 'diff', 'show changes', 'what changed', 'changes']):
            return 'git_diff', details

        if any(word in text_lower for word in ['git log', 'log', 'history', 'show history', 'commit history']):
            details['count'] = 10
            count_match = re.search(r'(?:last|show|last)\s+(\d+)', text_lower)
            if count_match:
                details['count'] = int(count_match.group(1))
            return 'git_log', details

        if any(word in text_lower for word in ['git branch', 'branches', 'show branches', 'list branches']):
            return 'git_branch', details

        if any(word in text_lower for word in ['git add', 'stage', 'add to git', 'track']):
            path_match = re.search(r'(?:file|path|all|\.)\s*["\']?([^"\']+)["\']?', text_lower)
            details['path'] = path_match.group(1) if path_match else '.'
            return 'git_add', details

        if any(word in text_lower for word in ['git push', 'push']):
            return 'git_push', details

        if any(word in text_lower for word in ['git pull', 'pull', 'fetch updates']):
            return 'git_pull', details

        if any(word in text_lower for word in ['fetch', 'download', 'get url', 'get page', 'web page', 'open url']):
            url_match = re.search(r'(https?://[^\s]+)', text_lower)
            if url_match:
                details['url'] = url_match.group(1)
            else:
                url_match = re.search(r'(?:url|link|website|page)\s+["\']?([^"\']+)["\']?', text_lower)
                if url_match:
                    details['url'] = url_match.group(1)
            return 'web_fetch', details

        if any(word in text_lower for word in ['search web', 'google', 'web search', 'search online', 'search for']):
            query_match = re.search(r'(?:for|search|google)\s+["\'](.+?)["\']', text_lower)
            if query_match:
                details['query'] = query_match.group(1)
            else:
                words = text_lower.split()
                for i, word in enumerate(words):
                    if word in ['for', 'search', 'google']:
                        details['query'] = ' '.join(words[i + 1:])
                        break
            return 'web_search', details

        return 'unknown', details

    def execute_file_create(self, details: Dict) -> str:
        """Create a new file."""
        filename = details.get('filename', 'new_file.txt')
        content = details.get('content', '')
        
        if not content:
            content = f"# {filename}\n# Created by AI ChatBot\n\n"
        
        try:
            filepath = os.path.join(self.workspace_dir, filename)
            os.makedirs(os.path.dirname(filepath) if os.path.dirname(filepath) else '.', exist_ok=True)
            
            with open(filepath, 'w') as f:
                f.write(content)
            
            self.history.append(f"Created file: {filename}")
            return f"File '{filename}' created successfully at:\n{filepath}"
        except Exception as e:
            return f"Error creating file: {str(e)}"

    def execute_file_read(self, details: Dict) -> str:
        """Read a file's contents."""
        filename = details.get('filename', '')
        if not filename:
            return "Please specify a filename to read."
        
        try:
            filepath = os.path.join(self.workspace_dir, filename)
            if not os.path.exists(filepath):
                return f"File '{filename}' not found."
            
            with open(filepath, 'r') as f:
                content = f.read()
            
            lines = content.split('\n')
            if len(lines) > 50:
                preview = '\n'.join(lines[:50])
                return f"File: {filename} ({len(lines)} lines)\n\n{preview}\n\n... (showing first 50 lines)"
            return f"File: {filename}\n\n{content}"
        except Exception as e:
            return f"Error reading file: {str(e)}"

    def execute_file_edit(self, details: Dict) -> str:
        """Edit a file."""
        filename = details.get('filename', '')
        old_text = details.get('old_text', '')
        new_text = details.get('new_text', '')
        
        if not filename:
            return "Please specify a filename to edit."
        
        try:
            filepath = os.path.join(self.workspace_dir, filename)
            if not os.path.exists(filepath):
                return f"File '{filename}' not found."
            
            with open(filepath, 'r') as f:
                content = f.read()
            
            if old_text and new_text:
                if old_text in content:
                    content = content.replace(old_text, new_text, 1)
                    with open(filepath, 'w') as f:
                        f.write(content)
                    self.history.append(f"Edited file: {filename}")
                    return f"File '{filename}' updated successfully."
                else:
                    return f"Text '{old_text}' not found in '{filename}'."
            else:
                return f"File '{filename}' found. To edit, specify what to replace and what to replace it with."
        except Exception as e:
            return f"Error editing file: {str(e)}"

    def execute_file_delete(self, details: Dict) -> str:
        """Delete a file."""
        filename = details.get('filename', '')
        if not filename:
            return "Please specify a filename to delete."
        
        try:
            filepath = os.path.join(self.workspace_dir, filename)
            if not os.path.exists(filepath):
                return f"File '{filename}' not found."
            
            os.remove(filepath)
            self.history.append(f"Deleted file: {filename}")
            return f"File '{filename}' deleted successfully."
        except Exception as e:
            return f"Error deleting file: {str(e)}"

    def execute_file_list(self, details: Dict) -> str:
        """List files in a directory."""
        path = details.get('path', '.')
        
        try:
            full_path = os.path.join(self.workspace_dir, path)
            if not os.path.exists(full_path):
                return f"Path '{path}' not found."
            
            items = []
            for item in sorted(os.listdir(full_path)):
                item_path = os.path.join(full_path, item)
                if os.path.isdir(item_path):
                    items.append(f"  {item}/")
                else:
                    size = os.path.getsize(item_path)
                    items.append(f"  {item} ({size} bytes)")
            
            if not items:
                return f"Directory '{path}' is empty."
            
            return f"Files in '{path}':\n" + '\n'.join(items)
        except Exception as e:
            return f"Error listing files: {str(e)}"

    def execute_code_search(self, details: Dict) -> str:
        """Search for code patterns."""
        query = details.get('query', '')
        path = details.get('path', '.')
        extension = details.get('extension', '')
        
        if not query:
            return "Please specify what to search for."
        
        try:
            full_path = os.path.join(self.workspace_dir, path)
            if not os.path.exists(full_path):
                return f"Path '{path}' not found."
            
            results = []
            
            if os.path.isfile(full_path):
                with open(full_path, 'r', errors='ignore') as f:
                    for i, line in enumerate(f, 1):
                        if query.lower() in line.lower():
                            results.append(f"{full_path}:{i}: {line.strip()}")
            else:
                search_pattern = f"**/*{extension}" if extension else "**/*"
                for filepath in glob.glob(os.path.join(full_path, search_pattern), recursive=True):
                    if os.path.isfile(filepath):
                        try:
                            with open(filepath, 'r', errors='ignore') as f:
                                for i, line in enumerate(f, 1):
                                    if query.lower() in line.lower():
                                        rel_path = os.path.relpath(filepath, self.workspace_dir)
                                        results.append(f"{rel_path}:{i}: {line.strip()}")
                        except:
                            continue
            
            if not results:
                return f"No results found for '{query}' in '{path}'."
            
            if len(results) > 20:
                output = '\n'.join(results[:20])
                return f"Found {len(results)} matches (showing first 20):\n\n{output}"
            
            return f"Found {len(results)} matches:\n\n" + '\n'.join(results)
        except Exception as e:
            return f"Error searching: {str(e)}"

    def execute_git_status(self, details: Dict) -> str:
        """Get git status."""
        try:
            result = subprocess.run(
                ['git', 'status'],
                capture_output=True,
                text=True,
                cwd=self.workspace_dir
            )
            if result.returncode == 0:
                return f"Git Status:\n{result.stdout}"
            else:
                return f"Git error: {result.stderr}"
        except FileNotFoundError:
            return "Git is not installed or not in PATH."
        except Exception as e:
            return f"Error getting git status: {str(e)}"

    def execute_git_commit(self, details: Dict) -> str:
        """Commit changes."""
        message = details.get('message', '')
        if not message:
            message = "Update via AI ChatBot"
        
        try:
            add_result = subprocess.run(
                ['git', 'add', '.'],
                capture_output=True,
                text=True,
                cwd=self.workspace_dir
            )
            
            commit_result = subprocess.run(
                ['git', 'commit', '-m', message],
                capture_output=True,
                text=True,
                cwd=self.workspace_dir
            )
            
            if commit_result.returncode == 0:
                return f"Changes committed successfully!\n\n{commit_result.stdout}"
            else:
                if "nothing to commit" in commit_result.stdout:
                    return "No changes to commit."
                return f"Commit error: {commit_result.stderr}"
        except FileNotFoundError:
            return "Git is not installed or not in PATH."
        except Exception as e:
            return f"Error committing: {str(e)}"

    def execute_git_diff(self, details: Dict) -> str:
        """Show git diff."""
        try:
            result = subprocess.run(
                ['git', 'diff'],
                capture_output=True,
                text=True,
                cwd=self.workspace_dir
            )
            if result.returncode == 0:
                if result.stdout:
                    return f"Git Diff:\n{result.stdout[:2000]}"
                return "No changes to show."
            return f"Git diff error: {result.stderr}"
        except FileNotFoundError:
            return "Git is not installed or not in PATH."
        except Exception as e:
            return f"Error getting diff: {str(e)}"

    def execute_git_log(self, details: Dict) -> str:
        """Show git log."""
        count = details.get('count', 10)
        try:
            result = subprocess.run(
                ['git', 'log', f'-{count}', '--oneline'],
                capture_output=True,
                text=True,
                cwd=self.workspace_dir
            )
            if result.returncode == 0:
                if result.stdout:
                    return f"Git Log (last {count} commits):\n{result.stdout}"
                return "No commits found."
            return f"Git log error: {result.stderr}"
        except FileNotFoundError:
            return "Git is not installed or not in PATH."
        except Exception as e:
            return f"Error getting log: {str(e)}"

    def execute_git_branch(self, details: Dict) -> str:
        """Show git branches."""
        try:
            result = subprocess.run(
                ['git', 'branch', '-a'],
                capture_output=True,
                text=True,
                cwd=self.workspace_dir
            )
            if result.returncode == 0:
                return f"Git Branches:\n{result.stdout}"
            return f"Git branch error: {result.stderr}"
        except FileNotFoundError:
            return "Git is not installed or not in PATH."
        except Exception as e:
            return f"Error getting branches: {str(e)}"

    def execute_git_add(self, details: Dict) -> str:
        """Stage files."""
        path = details.get('path', '.')
        try:
            result = subprocess.run(
                ['git', 'add', path],
                capture_output=True,
                text=True,
                cwd=self.workspace_dir
            )
            if result.returncode == 0:
                return f"Files staged successfully: {path}"
            return f"Git add error: {result.stderr}"
        except FileNotFoundError:
            return "Git is not installed or not in PATH."
        except Exception as e:
            return f"Error staging files: {str(e)}"

    def execute_git_push(self, details: Dict) -> str:
        """Push to remote."""
        try:
            result = subprocess.run(
                ['git', 'push'],
                capture_output=True,
                text=True,
                cwd=self.workspace_dir
            )
            if result.returncode == 0:
                return "Changes pushed successfully!"
            return f"Git push error: {result.stderr}"
        except FileNotFoundError:
            return "Git is not installed or not in PATH."
        except Exception as e:
            return f"Error pushing: {str(e)}"

    def execute_git_pull(self, details: Dict) -> str:
        """Pull from remote."""
        try:
            result = subprocess.run(
                ['git', 'pull'],
                capture_output=True,
                text=True,
                cwd=self.workspace_dir
            )
            if result.returncode == 0:
                return f"Changes pulled successfully!\n{result.stdout}"
            return f"Git pull error: {result.stderr}"
        except FileNotFoundError:
            return "Git is not installed or not in PATH."
        except Exception as e:
            return f"Error pulling: {str(e)}"

    def execute_web_fetch(self, details: Dict) -> str:
        """Fetch a web page."""
        url = details.get('url', '')
        if not url:
            return "Please specify a URL to fetch."
        
        try:
            import urllib.request
            import urllib.error
            
            if not url.startswith(('http://', 'https://')):
                url = 'https://' + url
            
            req = urllib.request.Request(
                url,
                headers={'User-Agent': 'Mozilla/5.0 (compatible; AIBot/1.0)'}
            )
            
            with urllib.request.urlopen(req, timeout=10) as response:
                content = response.read().decode('utf-8', errors='ignore')
                
                text_only = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.DOTALL)
                text_only = re.sub(r'<style[^>]*>.*?</style>', '', text_only, flags=re.DOTALL)
                text_only = re.sub(r'<[^>]+>', ' ', text_only)
                text_only = re.sub(r'\s+', ' ', text_only).strip()
                
                if len(text_only) > 2000:
                    text_only = text_only[:2000] + "..."
                
                return f"Content from {url}:\n\n{text_only}"
        except Exception as e:
            return f"Error fetching URL: {str(e)}"

    def execute_web_search(self, details: Dict) -> str:
        """Search the web (simulated)."""
        query = details.get('query', '')
        if not query:
            return "Please specify what to search for."
        
        return f"""Web search for: "{query}"

Note: For actual web search, I recommend using a search API like:
- Google Custom Search API
- Bing Search API
- DuckDuckGo API

For now, you can try fetching specific URLs with commands like:
- "fetch https://example.com"
- "download https://example.com/page"

Would you like me to fetch a specific URL instead?"""

    def execute(self, operation: str, details: Dict) -> str:
        """Execute the detected operation."""
        operations = {
            'file_create': self.execute_file_create,
            'file_read': self.execute_file_read,
            'file_edit': self.execute_file_edit,
            'file_delete': self.execute_file_delete,
            'file_list': self.execute_file_list,
            'code_search': self.execute_code_search,
            'git_status': self.execute_git_status,
            'git_commit': self.execute_git_commit,
            'git_diff': self.execute_git_diff,
            'git_log': self.execute_git_log,
            'git_branch': self.execute_git_branch,
            'git_add': self.execute_git_add,
            'git_push': self.execute_git_push,
            'git_pull': self.execute_git_pull,
            'web_fetch': self.execute_web_fetch,
            'web_search': self.execute_web_search,
        }
        
        executor = operations.get(operation)
        if executor:
            return executor(details)
        return "I'm not sure what you want me to do. Try being more specific."

    def get_help(self) -> str:
        """Get help for opencode features."""
        return """
╔══════════════════════════════════════════════════════════════╗
║                  OpenCode Features Help                    ║
╠══════════════════════════════════════════════════════════════╣
║  FILE OPERATIONS:                                           ║
║  • "Create a file called hello.py"                         ║
║  • "Write a file named index.html with <h1>Hello</h1>"     ║
║  • "Read file README.md"                                   ║
║  • "Show file main.py"                                     ║
║  • "Edit file config.json"                                 ║
║  • "Delete file old_file.txt"                              ║
║  • "List files in src/"                                    ║
║                                                             ║
║  CODE SEARCH:                                               ║
║  • "Search for function_name"                              ║
║  • "Find class MyClass"                                    ║
║  • "Grep 'import os' in src/"                              ║
║  • "Look for TODO in all .py files"                        ║
║                                                             ║
║  GIT OPERATIONS:                                            ║
║  • "Git status"                                            ║
║  • "Commit with message 'fix bug'"                         ║
║  • "Git diff"                                              ║
║  • "Git log" or "Show last 5 commits"                      ║
║  • "Git branch"                                            ║
║  • "Git add all"                                           ║
║  • "Git push"                                              ║
║  • "Git pull"                                              ║
║                                                             ║
║  WEB OPERATIONS:                                            ║
║  • "Fetch https://example.com"                             ║
║  • "Download https://example.com/page"                     ║
║  • "Search web for Python tutorial"                        ║
╚══════════════════════════════════════════════════════════════╝
        """
