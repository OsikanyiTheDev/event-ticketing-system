"""responses — build API-Gateway-compatible HTTP responses."""

import json

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
    "Access-Control-Allow-Credentials": "true",
    "Content-Type": "application/json",
}


def _response(status_code, body, extra_headers=None):
    headers = dict(CORS_HEADERS)
    if extra_headers:
        headers.update(extra_headers)
    return {
        "statusCode": status_code,
        "headers": headers,
        "body": json.dumps(body, default=str),  # ← THE key line: string, not dict
        "isBase64Encoded": False,
    }


def success(data=None, status_code=200):
    return _response(status_code, {"success": True, "data": data})


def created(data=None, status_code=201):
    return _response(status_code, {"success": True, "data": data})


def error(message, status_code=400, details=None):
    body = {"success": False, "error": message}
    if details is not None:
        body["details"] = details
    return _response(status_code, body)
