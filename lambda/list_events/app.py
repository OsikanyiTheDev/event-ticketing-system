"""
GET /events handler — lists all events from DynamoDB.

FLOW
  API Gateway ──► Lambda(event, context) ──► scan DynamoDB ──► JSON response

KEY IDEAS
  • The table name comes from the EVENTS_TABLE environment variable, which
    Terraform injects when it creates the Lambda (Stage 3). This keeps the
    code environment-agnostic — the SAME code runs in dev and prod, pointed
    at different tables purely via config.
  • boto3 resource is built ONCE at module level and reused. AWS Lambda
    reuses the execution environment across "warm" invocations, so caching
    the client avoids rebuilding it every call (faster + cheaper).
  • We never leak internal errors to the caller. Real errors go to logs;
    the client gets a generic 500.
"""

import logging
import os

import boto3

from common.errors import APIError
from common.responses import error, success

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Module-level cache for the table handle (see "KEY IDEAS").
_table = None
_registrations_table = None


def get_table():
    """Lazily build the DynamoDB table handle.

    Kept as a function (not done at import time) so that:
      (a) the env var is read at runtime, not import time, and
      (b) unit tests can reset `_table` and run under `moto`.
    """
    global _table
    if _table is None:
        table_name = os.environ["EVENTS_TABLE"]
        _table = boto3.resource("dynamodb").Table(table_name)
    return _table


def _get_registrations_table():
    global _registrations_table
    if _registrations_table is None:
        _registrations_table = boto3.resource("dynamodb").Table(os.environ["REGISTRATIONS_TABLE"])
    return _registrations_table


def handler(event, context):
    """List all events. GET /events has no input to validate."""
    try:
        logger.info("Listing events")
        table = get_table()

        # A single Scan returns up to 1 MB. To avoid silently dropping events
        # once the table grows, we loop on LastEvaluatedKey until exhausted.
        items = []
        response = table.scan()
        items.extend(response.get("Items", []))
        while "LastEvaluatedKey" in response:
            response = table.scan(ExclusiveStartKey=response["LastEvaluatedKey"])
            items.extend(response.get("Items", []))

        # Count registrations per event (one scan, group in Python)
        reg_counts = {}
        reg_resp = _get_registrations_table().scan(ProjectionExpression="event_id")
        for item in reg_resp.get("Items", []):
            eid = item.get("event_id")
            if eid:
                reg_counts[eid] = reg_counts.get(eid, 0) + 1

        for ev in items:
            ev["registered_count"] = reg_counts.get(ev.get("event_id"), 0)

        logger.info("Returned %d events", len(items))
        return success({"events": items, "count": len(items)})

    except APIError as e:
        # Typed business errors → their specific status code
        return error(e.message, e.status_code)
    except Exception:
        # Anything unexpected → log the real traceback, return generic 500
        logger.exception("Unexpected error listing events")
        return error("Internal server error", status_code=500)
