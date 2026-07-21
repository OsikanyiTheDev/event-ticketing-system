"""
GET /registrations/{email} — list all of a person's registrations.

Flow
  API Gateway ──► Lambda(event) ──► validate email from path ──►
     query the email-index GSI ──► return matching registrations

The email arrives in event["pathParameters"]["email"] (API Gateway extracts
the {email} part of the URL path). We re-validate it — path params are user
input too, so the "never trust input" rule applies.
"""

import logging
import os
from urllib.parse import unquote

import boto3
from boto3.dynamodb.conditions import Key

from common.errors import APIError
from common.responses import error, success
from common.validation import validate_email

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
        # Path params can arrive URL-encoded (e.g. %40 for @) — decode first.
        raw_email = unquote(event.get("pathParameters", {}).get("email", ""))
        email = validate_email(raw_email)  # validates + normalizes to lowercase

        # Query the email GSI — same index the register handler uses for dup checks.
        table = _get_table()
        items = []
        response = table.query(
            IndexName="email-index",
            KeyConditionExpression=Key("email").eq(email),
        )
        items.extend(response.get("Items", []))
        while "LastEvaluatedKey" in response:
            response = table.query(
                IndexName="email-index",
                KeyConditionExpression=Key("email").eq(email),
                ExclusiveStartKey=response["LastEvaluatedKey"],
            )
            items.extend(response.get("Items", []))

        logger.info("Found %d registrations for %s", len(items), email)
        return success({"email": email, "registrations": items, "count": len(items)})

    except APIError as e:
        return error(e.message, e.status_code)
    except ValueError as e:
        return error(str(e), status_code=400)
    except Exception:
        logger.exception("Unexpected error in get_registrations")
        return error("Internal server error", status_code=500)
