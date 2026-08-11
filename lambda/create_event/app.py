"""
POST /admin/events — create a new event (admin only).

Simple auth: checks an API key header (X-API-Key) against a server-side env var.
In production, this would be Amazon Cognito (user pools + JWT) with role-based
access. For now, the API key demonstrates "protected endpoint" cleanly.
"""

import logging
import os

import boto3

from common.errors import APIError
from common.responses import created, error
from common.validation import parse_json_body, require_fields, sanitize_string

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_table = None


def _get_table():
    global _table
    if _table is None:
        _table = boto3.resource("dynamodb").Table(os.environ["EVENTS_TABLE"])
    return _table


def handler(event, context):
    try:
        # ── Auth: validate API key ──
        provided_key = event.get("headers", {}).get("x-api-key", "")
        expected_key = os.environ.get("ADMIN_API_KEY", "")
        if not expected_key or provided_key != expected_key:
            return error("Unauthorized — invalid or missing API key", status_code=403)

        # ── Validate input ──
        body = parse_json_body(event.get("body"))
        require_fields(body, ["event_id", "name"])

        item = {
            "event_id": sanitize_string(body["event_id"]),
            "name": sanitize_string(body["name"], max_length=200),
        }

        # Optional fields
        for field, max_len in [("date", 50), ("location", 200), ("description", 500)]:
            val = body.get(field)
            if val:
                item[field] = sanitize_string(val, max_length=max_len)

        capacity = body.get("capacity")
        if capacity is not None:
            item["capacity"] = str(int(capacity))  # store as string (DynamoDB-friendly)

        # ── Write to DynamoDB ──
        _get_table().put_item(Item=item)
        logger.info("Admin created event %s", item["event_id"])
        return created({"event_id": item["event_id"], "created": True})

    except APIError as e:
        return error(e.message, e.status_code)
    except ValueError as e:
        return error(str(e), status_code=400)
    except Exception:
        logger.exception("Unexpected error in create_event")
        return error("Internal server error", status_code=500)
