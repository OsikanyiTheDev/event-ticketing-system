"""
Seed the Events table with sample events so the API has data to serve.

USAGE
  # with the venv active + AWS creds configured:
  python scripts/seed_events.py                            # uses EVENTS_TABLE env or default
  python scripts/seed_events.py event-ticketing-dev-events # explicit table name

IDEMPOTENT: uses put_item, so re-running overwrites safely (no duplicates).
"""

import os
import sys

import boto3
from botocore.exceptions import ClientError

SAMPLE_EVENTS = [
    {
        "event_id": "aws-bootcamp",
        "name": "AWS Cloud Bootcamp",
        "date": "2026-09-15",
        "location": "Accra, Ghana",
        "capacity": 200,
        "description": "Hands-on intro to core AWS services.",
    },
    {
        "event_id": "devops-meetup",
        "name": "DevOps & CI/CD Meetup",
        "date": "2026-10-01",
        "location": "Online",
        "capacity": 500,
        "description": "Pipelines, containers, and automation deep-dive.",
    },
    {
        "event_id": "serverless-workshop",
        "name": "Serverless Workshop",
        "date": "2026-10-20",
        "location": "Kumasi, Ghana",
        "capacity": 100,
        "description": "Build a serverless app with Lambda + DynamoDB.",
    },
    {
        "event_id": "data-eng-conf",
        "name": "Data Engineering Conference",
        "date": "2026-11-05",
        "location": "Accra, Ghana",
        "capacity": 300,
        "description": "Pipelines, warehousing, and analytics at scale.",
    },
]


def main() -> None:
    table_name = (
        sys.argv[1]
        if len(sys.argv) > 1
        else os.environ.get("EVENTS_TABLE", "event-ticketing-dev-events")
    )
    table = boto3.resource("dynamodb").Table(table_name)

    try:
        for event in SAMPLE_EVENTS:
            table.put_item(Item=event)
            print(f"  ✓ seeded {event['event_id']:<20} ({event['name']})")
    except ClientError as e:
        print(f"✗ Failed: {e.response['Error']['Message']}", file=sys.stderr)
        sys.exit(1)

    print(f"\n✅ Seeded {len(SAMPLE_EVENTS)} events into '{table_name}'")


if __name__ == "__main__":
    main()
