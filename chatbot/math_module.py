import math
import re
from typing import Optional

class MathCalculator:
    """Handles mathematical calculations safely."""

    def __init__(self):
        self.safe_operations = {
            'abs': abs,
            'round': round,
            'min': min,
            'max': max,
            'sum': sum,
            'sqrt': math.sqrt,
            'pow': pow,
            'log': math.log,
            'log10': math.log10,
            'sin': math.sin,
            'cos': math.cos,
            'tan': math.tan,
            'pi': math.pi,
            'e': math.e,
        }

    def is_math_expression(self, text: str) -> bool:
        """Check if the input looks like a math expression."""
        math_patterns = [
            r'[\d\+\-\*\/\(\)]+',
            r'(calculate|compute|solve|what is|what\'s)\s+[\d\+\-\*\/\(\)]+',
            r'\d+\s*[\+\-\*\/\^]\s*\d+',
            r'(sqrt|sin|cos|tan|log|abs|pow)\s*\(',
        ]
        text_lower = text.lower()
        return any(re.search(pattern, text_lower) for pattern in math_patterns)

    def clean_math_expression(self, text: str) -> str:
        """Extract and clean the math expression from text."""
        text = text.lower()
        prefixes = ['calculate', 'compute', 'solve', 'what is', "what's", 'find']
        for prefix in prefixes:
            if text.startswith(prefix):
                text = text[len(prefix):].strip()
                break
        
        text = text.replace('^', '**')
        text = text.replace('x', '*').replace('X', '*')
        
        allowed_chars = set('0123456789+-*/().,% ')
        allowed_functions = ['sqrt', 'sin', 'cos', 'tan', 'log', 'log10', 'abs', 'pow', 'min', 'max', 'sum', 'round', 'pi', 'e']
        
        result = []
        i = 0
        while i < len(text):
            if text[i] in allowed_chars:
                result.append(text[i])
                i += 1
            else:
                found_function = False
                for func in allowed_functions:
                    if text[i:].startswith(func):
                        result.append(func)
                        i += len(func)
                        found_function = True
                        break
                if not found_function:
                    i += 1
        
        return ''.join(result).strip()

    def calculate(self, expression: str) -> Optional[float]:
        """Safely calculate a math expression."""
        try:
            cleaned = self.clean_math_expression(expression)
            
            if not cleaned:
                return None
            
            allowed_names = {k: v for k, v in self.safe_operations.items()}
            allowed_names['__builtins__'] = {}
            
            result = eval(cleaned, allowed_names, {})
            return result
            
        except Exception:
            return None

    def format_result(self, result: float) -> str:
        """Format the calculation result nicely."""
        if result == int(result):
            return str(int(result))
        return f"{result:.6g}"
