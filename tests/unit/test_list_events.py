"""
Tests for the GET /events handler using moto (AWS mock).

WHAT IS MOTO?
  moto intercepts boto3 calls and simulates AWS in-memory — so these tests
  run with NO real AWS account, NO network, and NO cost. It creates a fake
  DynamoDB table, our handler scans it, and we assert on the result. This is
  exactly what CI will run in Stage 4.
"""

import json

import boto3

# conftest.py puts lambda/ on sys.path, so these resolve:
import list_events.app as app_module
import pytest
from list_events.app import handler
from moto import mock_aws


@pytest.fixture
def events_table(monkeypatch):
    """Create mocked Events + Registrations tables."""
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")
    monkeypatch.setenv("EVENTS_TABLE", "test-events")
    monkeypatch.setenv("REGISTRATIONS_TABLE", "test-registrations")

    app_module._table = None
    app_module._registrations_table = None

    with mock_aws():
        dynamo = boto3.resource("dynamodb", region_name="us-east-1")
        table = dynamo.create_table(
            TableName="test-events",
            KeySchema=[{"AttributeName": "event_id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "event_id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        dynamo.create_table(
            TableName="test-registrations",
            KeySchema=[{"AttributeName": "registration_id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "registration_id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        yield table


def test_list_events_empty_table(events_table):
    """An empty table returns count 0 and an empty list."""
    resp = handler({}, None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["data"]["count"] == 0
    assert body["data"]["events"] == []


def test_list_events_returns_all(events_table):
    """All inserted events come back."""
    events_table.put_item(Item={"event_id": "e1", "name": "Tech Meetup"})
    events_table.put_item(Item={"event_id": "e2", "name": "Cloud Workshop"})

    resp = handler({}, None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["data"]["count"] == 2
    ids = {e["event_id"] for e in body["data"]["events"]}
    assert ids == {"e1", "e2"}


def test_list_events_response_shape(events_table):
    """Response is API-Gateway-compatible (string body, has status/headers)."""
    resp = handler({}, None)
    assert set(resp) >= {"statusCode", "headers", "body"}
    assert isinstance(resp["body"], str)


def test_list_events_missing_env_returns_500(monkeypatch):
    """If the table env var is unset, the handler fails gracefully (500)."""
    monkeypatch.delenv("EVENTS_TABLE", raising=False)
    app_module._table = None
    resp = handler({}, None)
    assert resp["statusCode"] == 500
