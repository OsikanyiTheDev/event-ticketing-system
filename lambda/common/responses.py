"""
responses — build API-Gateway-compatible HTTP responses.

API Gateway requires Lambda to return a dict shaped EXACTLY like:
    {
        "statusCode": 200,
        "headers": {...},
        "body": "<a JSON string>",   # must be a STRING, not a dict
        "isBase64Encoded": False,
    }
If you forget to json.dumps the body, or omit a key, API Gateway returns
a confusing 502 to the caller. These helpers make that impossible to get wrong.
"""

import json

# CORS headers: let a web frontend (different origin) call our API.
# "*" = any origin. For prod you'd restrict this to your real frontend domain.
CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization,X-API-Key",
    "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
    "Access-Control-Allow-Credentials": "true",
    "Content-Type": "application/json",
}


def _response(status_code, body, extra_headers=None):
    """Low-level builder. Every public helper funnels through here."""
    headers = dict(CORS_HEADERS)
    if extra_headers:
        headers.update(extra_headers)
    return {
        "statusCode": status_code,
        "headers": headers,
        # json.dumps is THE key step — API Gateway needs a string body.
        "body": json.dumps(body, default=str),
        "isBase64Encoded": False,
    }


def success(data=None, status_code=200):
    """200 OK (or override status_code) wrapping data."""
    return _response(status_code, {"success": True, "data": data})


def created(data=None, status_code=201):
    """201 Created — use for successful POST that creates a resource."""
    return _response(status_code, {"success": True, "data": data})


def error(message, status_code=400, details=None):
    """Error response with optional details."""
    body = {"success": False, "error": message}
    if details is not None:
        body["details"] = details
    return _response(status_code, body)
