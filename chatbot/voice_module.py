import re
from typing import List, Optional

try:
    import pyttsx3
    PYTTSX3_AVAILABLE = True
except ImportError:
    PYTTSX3_AVAILABLE = False

try:
    import speech_recognition as sr
    SR_AVAILABLE = True
except ImportError:
    SR_AVAILABLE = False


class VoiceAssistant:
    """Voice assistant with wake word detection and graceful TTS/STT fallbacks."""

    def __init__(self, wake_words: Optional[List[str]] = None):
        self.wake_words = [w.lower() for w in (wake_words or ["hey kastart", "hello jarvis", "hey ai"])]
        self.tts_engine = None
        self.recognizer = None
        self.microphone = None
        self.history = []
        self.enabled = True

        if PYTTSX3_AVAILABLE:
            try:
                self.tts_engine = pyttsx3.init()
                self.tts_engine.setProperty("rate", 175)
            except Exception:
                self.tts_engine = None

        if SR_AVAILABLE:
            self.recognizer = sr.Recognizer()
            try:
                self.microphone = sr.Microphone()
            except (OSError, AttributeError):
                self.microphone = None

    def is_voice_request(self, text: str) -> bool:
        text_lower = text.lower().strip()
        voice_keywords = [
            "voice", "speak", "say", "say that", "read aloud", "tell me",
            "listen", "hear", "record", "transcribe", "speech", "tts",
            "text to speech", "speak up", "voice command", "voice control",
            "voice status", "wake word", "set wake word",
            "activate voice", "deactivate voice", "voice mode",
        ]
        return (
            any(kw in text_lower for kw in voice_keywords)
            or any(ww in text_lower for ww in self.wake_words)
        )

    def handle(self, text: str) -> str:
        text_lower = text.lower().strip()
        self.history.append({"role": "user", "content": text})

        if any(w in text_lower for w in ["voice status", "voice mode"]):
            response = self.voice_status()
        elif any(w in text_lower for w in ["set wake word", "change wake word", "add wake word"]):
            response = self.set_wake_word(text)
        elif any(w in text_lower for w in ["deactivate voice", "disable voice", "voice off"]):
            self.enabled = False
            response = "Voice mode deactivated. I'll respond with text only."
        elif any(w in text_lower for w in ["activate voice", "enable voice", "voice on"]):
            self.enabled = True
            response = "Voice mode activated."
        elif any(w in text_lower for w in ["listen", "hear me", "record", "transcribe"]):
            response = self.speech_to_text()
        elif any(w in text_lower for w in ["speak", "say", "read aloud", "tts", "text to speech"]):
            content = self._extract_speech_content(text)
            response = self.text_to_speech(content)
        else:
            response = self.text_to_speech(text)

        self.history.append({"role": "assistant", "content": response})
        return response

    def _extract_speech_content(self, text: str) -> str:
        text_lower = text.lower()
        prefixes = [
            "speak", "say", "read aloud", "say that", "tell me",
            "tts", "text to speech", "voice say",
        ]
        for prefix in sorted(prefixes, key=len, reverse=True):
            idx = text_lower.find(prefix)
            if idx != -1:
                content = text[idx + len(prefix):].strip()
                content = re.sub(r"^(about|the following|this|that|:|\s)+", "", content, flags=re.IGNORECASE).strip()
                if content:
                    return content
        return text

    def text_to_speech(self, text: str) -> str:
        if not text.strip():
            return "Nothing to speak."

        if PYTTSX3_AVAILABLE and self.tts_engine is not None:
            try:
                self.tts_engine.say(text)
                self.tts_engine.runAndWait()
                return f"Speaking: {text}"
            except Exception as e:
                return f"TTS error ({e}). Would speak: {text}"

        return (
            f"Would speak: \"{text}\"\n"
            "Install pyttsx3 for actual speech output:\n"
            "  pip install pyttsx3"
        )

    def speech_to_text(self) -> str:
        if not SR_AVAILABLE:
            return (
                "Speech recognition not available. "
                "Install SpeechRecognition and PyAudio:\n"
                "  pip install SpeechRecognition pyaudio"
            )

        if self.microphone is None:
            return (
                "No microphone detected. Connect a microphone and try again.\n"
                "You can type your message instead."
            )

        try:
            with self.microphone as source:
                self.recognizer.adjust_for_ambient_noise(source, duration=0.5)
                audio = self.recognizer.listen(source, timeout=10, phrase_time_limit=15)

            text = self.recognizer.recognize_google(audio)
            return f"I heard: \"{text}\""
        except sr.WaitTimeoutError:
            return "No speech detected within timeout. Please try again."
        except sr.UnknownValueError:
            return "Could not understand the audio. Please speak clearly and try again."
        except sr.RequestError as e:
            return f"Speech recognition service error: {e}. Check your internet connection."

    def set_wake_word(self, text: str) -> str:
        text_lower = text.lower()
        match = re.search(
            r"set wake word(?:\s+to)?\s+[\"']?(.+?)[\"']?\s*$", text_lower
        )
        if not match:
            match = re.search(
                r"add wake word\s+[\"']?(.+?)[\"']?\s*$", text_lower
            )
        if not match:
            match = re.search(
                r"change wake word\s+(?:to\s+)?[\"']?(.+?)[\"']?\s*$", text_lower
            )

        if match:
            new_word = match.group(1).strip().strip("\"'")
            if new_word:
                self.wake_words.append(new_word.lower())
                return f"Wake word '{new_word}' added. Current wake words: {', '.join(self.wake_words)}"

        return "Usage: set wake word <word or phrase>"

    def voice_status(self) -> str:
        lines = [
            "=== Voice Assistant Status ===",
            f"Voice mode: {'Active' if self.enabled else 'Inactive'}",
            f"Wake words: {', '.join(self.wake_words)}",
            f"TTS (pyttsx3): {'Available' if PYTTSX3_AVAILABLE and self.tts_engine else 'Not installed'}",
            f"STT (SpeechRecognition): {'Available' if SR_AVAILABLE else 'Not installed'}",
            f"Microphone: {'Detected' if self.microphone else 'Not detected'}",
            f"Commands processed: {len(self.history) // 2}",
        ]
        return "\n".join(lines)
