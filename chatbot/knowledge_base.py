import os
import json
import re
import glob
import math
from typing import List, Dict, Optional
from datetime import datetime


class KnowledgeBase:
    """RAG knowledge base for document storage, indexing, and retrieval."""

    def __init__(self, data_dir=".knowledge"):
        self.data_dir = data_dir
        self.docs_file = os.path.join(data_dir, "documents.json")
        self.index_file = os.path.join(data_dir, "index.json")
        self._ensure_dirs()
        self.documents = self._load_json(self.docs_file)
        self.index = self._load_json(self.index_file)

    def _ensure_dirs(self):
        os.makedirs(self.data_dir, exist_ok=True)

    def _load_json(self, filepath):
        if os.path.exists(filepath):
            with open(filepath, "r") as f:
                return json.load(f)
        return {}

    def _save_json(self, filepath, data):
        with open(filepath, "w") as f:
            json.dump(data, f, indent=2, default=str)

    def _tokenize(self, text):
        text = text.lower()
        text = re.sub(r"[^a-z0-9\s]", " ", text)
        tokens = text.split()
        return [t for t in tokens if len(t) > 1]

    def _build_tf(self, tokens):
        tf = {}
        for token in tokens:
            tf[token] = tf.get(token, 0) + 1
        for token in tf:
            tf[token] = 1 + math.log(tf[token]) if tf[token] > 0 else 0
        return tf

    def _compute_idf(self, query_tokens):
        idf = {}
        n_docs = len(self.documents)
        if n_docs == 0:
            return idf
        for token in query_tokens:
            containing = sum(
                1 for doc in self.documents.values()
                if token in self.index.get(doc["id"], {})
            )
            if containing > 0:
                idf[token] = math.log((n_docs + 1) / (containing + 1)) + 1
            else:
                idf[token] = 0
        return idf

    def _score(self, query_tokens, doc_id):
        doc_tf = self.index.get(doc_id, {})
        idf = self._compute_idf(query_tokens)
        score = 0.0
        for token in query_tokens:
            tf = doc_tf.get(token, 0)
            weight = idf.get(token, 0)
            score += tf * weight
        return score

    def _chunk_text(self, text, chunk_size=500, overlap=50):
        words = text.split()
        chunks = []
        start = 0
        while start < len(words):
            end = min(start + chunk_size, len(words))
            chunk = " ".join(words[start:end])
            chunks.append(chunk)
            start += chunk_size - overlap
        return chunks if chunks else [text]

    def add_document(self, title, content, source="user"):
        doc_id = re.sub(r"[^a-z0-9]", "_", title.lower()).strip("_")
        timestamp = datetime.now().isoformat()
        chunks = self._chunk_text(content)

        doc_entry = {
            "id": doc_id,
            "title": title,
            "source": source,
            "content": content,
            "chunks": chunks,
            "added": timestamp,
            "updated": timestamp,
        }
        self.documents[doc_id] = doc_entry

        for i, chunk in enumerate(chunks):
            chunk_id = f"{doc_id}_chunk_{i}"
            tokens = self._tokenize(chunk)
            self.index[chunk_id] = self._build_tf(tokens)
            self.index[chunk_id]["_doc_id"] = doc_id
            self.index[chunk_id]["_chunk_idx"] = i

        tokens = self._tokenize(content)
        self.index[doc_id] = self._build_tf(tokens)
        self.index[doc_id]["_doc_id"] = doc_id
        self.index[doc_id]["_chunk_idx"] = -1

        self._save_json(self.docs_file, self.documents)
        self._save_json(self.index_file, self.index)
        return f"Document '{title}' added successfully."

    def add_file(self, filepath):
        if not os.path.exists(filepath):
            return None, f"File not found: {filepath}"
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        title = os.path.splitext(os.path.basename(filepath))[0]
        return self.add_document(title, content, source=filepath), None

    def search(self, query, top_k=3):
        if not self.documents:
            return []

        query_tokens = self._tokenize(query)
        if not query_tokens:
            return []

        scores = {}
        for chunk_id in self.index:
            if chunk_id.startswith("_"):
                continue
            entry = self.index[chunk_id]
            doc_id = entry.get("_doc_id")
            if not doc_id or doc_id not in self.documents:
                continue
            chunk_idx = entry.get("_chunk_idx", -1)
            score = self._score(query_tokens, chunk_id)
            if score > 0:
                doc = self.documents[doc_id]
                if chunk_idx >= 0 and chunk_idx < len(doc.get("chunks", [])):
                    snippet = doc["chunks"][chunk_idx]
                else:
                    snippet = doc["content"][:500]
                scores[chunk_id] = {
                    "doc_id": doc_id,
                    "title": doc["title"],
                    "source": doc.get("source", "unknown"),
                    "snippet": snippet,
                    "score": score,
                }

        ranked = sorted(scores.values(), key=lambda x: x["score"], reverse=True)
        return ranked[:top_k]

    def answer(self, query):
        results = self.search(query, top_k=3)
        if not results:
            return "No relevant information found in the knowledge base."

        response_parts = []
        for i, result in enumerate(results, 1):
            snippet = result["snippet"][:300]
            if len(result["snippet"]) > 300:
                snippet += "..."
            response_parts.append(
                f"[{i}] From '{result['title']}' (relevance: {result['score']:.2f}):\n{snippet}"
            )

        return "\n\n".join(response_parts)

    def list_documents(self):
        if not self.documents:
            return "Knowledge base is empty."

        lines = ["Documents in knowledge base:", "=" * 40]
        for doc_id, doc in self.documents.items():
            source = doc.get("source", "unknown")
            added = doc.get("added", "unknown")[:10]
            lines.append(f"- {doc['title']} (source: {source}, added: {added})")
        lines.append(f"\nTotal: {len(self.documents)} document(s)")
        return "\n".join(lines)

    def is_knowledge_request(self, text):
        text_lower = text.lower().strip()
        patterns = [
            r"\b(learn|store|remember|add|save)\b.*\b(info|information|document|doc|note|data|knowledge)\b",
            r"\b(what do you know|knowledge base|search.*doc|find.*doc)\b",
            r"\b(read|load|import)\s+(file|document|txt|md|markdown)\b",
            r"\blist\s+(doc|file|note|document)",
            r"\b(documents?|notes?|files?)\s+(in|from)\s+(kb|knowledge|base)\b",
            r"\b(add|create)\s+(a\s+)?(document|note|entry|doc)\b",
            r"\btell me about\b",
            r"\bsearch.*for\b",
            r"\bwhat is\b.*\bin the\b.*\b(knowledge|kb|base|docs)\b",
            r"\bknowledge\b",
        ]
        return any(re.search(p, text_lower) for p in patterns)

    def handle(self, text):
        text_lower = text.lower().strip()

        if any(w in text_lower for w in ["list documents", "list docs", "show documents", "show docs", "what do you know"]):
            return self.list_documents()

        add_match = re.search(
            r"(?:add|create|save|store)\s+(?:a\s+)?(?:document|note|doc|entry|knowledge)\s*(?::)\s*(.*)",
            text_lower,
        )
        if add_match:
            content = add_match.group(1).strip()
            title = content[:50] if content else "Untitled"
            return self.add_document(title, content, source="user")

        add_match = re.search(
            r"(?:add|create|save|store)\s+(?:a\s+)?(?:document|note|doc|entry|knowledge)\s+(?:called|named|titled)?\s*['\"]?([\w\s]*?)['\"]?\s*(?:with|containing|about)\s*(.*)",
            text_lower,
        )
        if add_match:
            title = add_match.group(1).strip()
            content = add_match.group(2).strip()
            if not content:
                content = f"Document '{title}' with no content yet."
            return self.add_document(title, content, source="user")

        file_match = re.search(r"(?:read|load|import)\s+(?:file\s+)?(.+\.\w+)", text_lower)
        if file_match:
            filepath = file_match.group(1).strip()
            result, error = self.add_file(filepath)
            if error:
                return error
            return result

        search_match = re.search(r"(?:search|find|look)\s+(?:for\s+)?(.+)", text_lower)
        if search_match:
            query = search_match.group(1).strip()
            results = self.search(query)
            if not results:
                return "No matching documents found."
            return self.answer(query)

        return self.answer(text)
