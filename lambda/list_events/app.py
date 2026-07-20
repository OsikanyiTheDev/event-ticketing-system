"""GET /events handler — lists all events from DynamoDB."""
import logging
import os

import boto3

from common.errors import APIError
from common.responses import error, success

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Module-level cache for the table handle (reused across warm invocations)
_table = None


def get_table():
    """Lazily build the DynamoDB table handle."""
    global _table
    if _table is None:
        table_name = os.environ["EVENTS_TABLE"]
        _table = boto3.resource("dynamodb").Table(table_name)
    return _table


def handler(event, context):
    """List all events. GET /events has no input to validate."""
    try:
        logger.info("Listing events")
        table = get_table()

        # Scan returns up to 1MB; loop on LastEvaluatedKey to get everything
        items = []
        response = table.scan()
        items.extend(response.get("Items", []))
        while "LastEvaluatedKey" in response:
            response = table.scan(ExclusiveStartKey=response["LastEvaluatedKey"])
            items.extend(response.get("Items", []))

        logger.info("Returned %d events", len(items))
        return success({"events": items, "count": len(items)})

    except APIError as e:
        return error(e.message, e.status_code)
    except Exception:
        logger.exception("Unexpected error listing events")
        return error("Internal server error", status_code=500)