"""DELETE /admin/events/{id} — delete an event (admin only, API-key protected)."""
import logging
import os

import boto3

from common.errors import APIError, NotFoundError
from common.responses import error, success
from common.validation import sanitize_string

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
            return error("Unauthorized — invalid or missing admin password", status_code=403)

        event_id = sanitize_string(event.get("pathParameters", {}).get("id", ""))
        if not event_id:
            raise ValueError("Event ID is required")

        table = _get_table()
        if not table.get_item(Key={"event_id": event_id}).get("Item"):
            raise NotFoundError(f"Event '{event_id}' not found")

        table.delete_item(Key={"event_id": event_id})
        logger.info("Admin deleted event %s", event_id)
        return success({"event_id": event_id, "deleted": True})

    except APIError as e:
        return error(e.message, e.status_code)
    except ValueError as e:
        return error(str(e), status_code=400)
    except Exception:
        logger.exception("Unexpected error in delete_event")
        return error("Internal server error", status_code=500)
