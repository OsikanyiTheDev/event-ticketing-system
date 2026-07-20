"""DELETE /registration/{id} — cancel (remove) a registration."""

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
        _table = boto3.resource("dynamodb").Table(os.environ["REGISTRATIONS_TABLE"])
    return _table


def handler(event, context):
    try:
        raw_id = event.get("pathParameters", {}).get("id", "")
        registration_id = sanitize_string(raw_id)
        if not registration_id:
            raise ValueError("Registration id is required")

        table = _get_table()

        # Existence check → 404 if missing (correct REST behaviour)
        if not table.get_item(Key={"registration_id": registration_id}).get("Item"):
            raise NotFoundError(f"Registration '{registration_id}' not found")

        table.delete_item(Key={"registration_id": registration_id})
        logger.info("Deleted registration %s", registration_id)
        return success({"registration_id": registration_id, "deleted": True})

    except APIError as e:
        return error(e.message, e.status_code)
    except ValueError as e:
        return error(str(e), status_code=400)
    except Exception:
        logger.exception("Unexpected error in cancel_registration")
        return error("Internal server error", status_code=500)
