"""POST /register handler — register a person for an event."""
import logging
import os
import uuid
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Attr, Key

from common.errors import APIError, ConflictError, NotFoundError
from common.responses import created, error
from common.validation import parse_json_body, require_fields, sanitize_string, validate_email

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_registrations_table = None
_events_table = None


def _get_registrations_table():
    global _registrations_table
    if _registrations_table is None:
        _registrations_table = boto3.resource("dynamodb").Table(os.environ["REGISTRATIONS_TABLE"])
    return _registrations_table


def _get_events_table():
    global _events_table
    if _events_table is None:
        _events_table = boto3.resource("dynamodb").Table(os.environ["EVENTS_TABLE"])
    return _events_table


def handler(event, context):
    try:
        # 1. Parse & validate input
        body = parse_json_body(event.get("body"))
        require_fields(body, ["event_id", "email", "name"])
        event_id = sanitize_string(body["event_id"])
        email = validate_email(body["email"])           # also lowercases
        name = sanitize_string(body["name"], max_length=200)

        # 2. Confirm the event exists
        event_item = _get_events_table().get_item(Key={"event_id": event_id}).get("Item")
        if not event_item:
            raise NotFoundError(f"Event '{event_id}' not found")

        # 3. Confirm not already registered (uses the email GSI from Stage 1!)
        existing = _get_registrations_table().query(
            IndexName="email-index",
            KeyConditionExpression=Key("email").eq(email),
            FilterExpression=Attr("event_id").eq(event_id),
        )
        if existing.get("Items"):
            raise ConflictError("You are already registered for this event")

        # 4. Create the registration
        registration_id = str(uuid.uuid4())
        item = {
            "registration_id": registration_id,
            "event_id": event_id,
            "email": email,
            "name": name,
            "status": "confirmed",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        _get_registrations_table().put_item(Item=item)

        logger.info("Created registration %s for %s", registration_id, email)
        return created({"registration_id": registration_id, "status": "confirmed"})

    except APIError as e:
        return error(e.message, e.status_code)
    except ValueError as e:
        return error(str(e), status_code=400)     # validation errors → 400
    except Exception:
        logger.exception("Unexpected error in register")
        return error("Internal server error", status_code=500)