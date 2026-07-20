"""validation — input validation & sanitization. NEVER trust user input."""
import json
import re

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")

def sanitize_string(value, max_length=500):
    if value is None or not isinstance(value, str):
        raise ValueError("Expected a string")
    return value.strip()[:max_length]

def validate_email(email):
    if not email or not isinstance(email, str):
        raise ValueError("Email is required")
    email = email.strip().lower()
    if not EMAIL_REGEX.match(email):
        raise ValueError("Invalid email format")
    return email

def parse_json_body(raw_body):
    if not raw_body:
        raise ValueError("Request body is empty")
    try:
        return json.loads(raw_body)
    except (json.JSONDecodeError, TypeError):
        raise ValueError("Request body is not valid JSON")

def require_fields(data, fields):
    missing = [f for f in fields if not data.get(f)]
    if missing:
        raise ValueError(f"Missing required field(s): {', '.join(missing)}")
    return data