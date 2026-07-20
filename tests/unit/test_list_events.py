"""Tests for the GET /events handler using moto (AWS mock)."""
import json

import boto3
import pytest
from moto import mock_aws

# conftest.py puts lambda/ on sys.path, so these resolve:
import list_events.app as app_module
from list_events.app import handler


@pytest.fixture
def events_table(monkeypatch):
    """Create a mocked Events table and point the handler at it."""
    # moto needs dummy creds + region to avoid real credential lookups
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")
    monkeypatch.setenv("EVENTS_TABLE", "test-events")

    app_module._table = None  # reset cache so it rebuilds under moto

    with mock_aws():
        table = boto3.resource("dynamodb", region_name="us-east-1").create_table(
            TableName="test-events",
            KeySchema=[{"AttributeName": "event_id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "event_id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        yield table


def test_list_events_empty_table(events_table):
    resp = handler({}, None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["data"]["count"] == 0
    assert body["data"]["events"] == []


def test_list_events_returns_all(events_table):
    events_table.put_item(Item={"event_id": "e1", "name": "Tech Meetup"})
    events_table.put_item(Item={"event_id": "e2", "name": "Cloud Workshop"})
    resp = handler({}, None)
    body = json.loads(resp["body"])
    assert body["data"]["count"] == 2
    ids = {e["event_id"] for e in body["data"]["events"]}
    assert ids == {"e1", "e2"}


def test_list_events_response_shape(events_table):
    resp = handler({}, None)
    assert set(resp) >= {"statusCode", "headers", "body"}
    assert isinstance(resp["body"], str)


def test_list_events_missing_env_returns_500(monkeypatch):
    monkeypatch.delenv("EVENTS_TABLE", raising=False)
    app_module._table = None
    resp = handler({}, None)
    assert resp["statusCode"] == 500