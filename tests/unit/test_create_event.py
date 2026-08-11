"""Tests for POST /admin/events (create_event handler)."""

import json

import boto3
import create_event.app as app_module
import pytest
from create_event.app import handler
from moto import mock_aws


@pytest.fixture
def events_table(monkeypatch):
    """Create a mocked Events table + set the admin API key."""
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")
    monkeypatch.setenv("EVENTS_TABLE", "test-events")
    monkeypatch.setenv("ADMIN_API_KEY", "secret-key-123")

    app_module._table = None

    with mock_aws():
        table = boto3.resource("dynamodb", region_name="us-east-1").create_table(
            TableName="test-events",
            KeySchema=[{"AttributeName": "event_id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "event_id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        yield table


def _event(body, api_key="secret-key-123"):
    return {
        "httpMethod": "POST",
        "headers": {"x-api-key": api_key},
        "body": json.dumps(body),
    }


def test_create_event_success(events_table):
    resp = handler(
        _event(
            {"event_id": "new-conf", "name": "AI Conference", "date": "2026-12-01", "capacity": 150}
        ),
        None,
    )
    assert resp["statusCode"] == 201
    body = json.loads(resp["body"])
    assert body["data"]["event_id"] == "new-conf"
    # verify it was written
    item = events_table.get_item(Key={"event_id": "new-conf"})["Item"]
    assert item["name"] == "AI Conference"
    assert item["capacity"] == "150"


def test_create_event_wrong_api_key(events_table):
    resp = handler(_event({"event_id": "x", "name": "X"}, api_key="wrong-key"), None)
    assert resp["statusCode"] == 403


def test_create_event_missing_api_key(events_table):
    resp = handler({"headers": {}, "body": json.dumps({"event_id": "x", "name": "X"})}, None)
    assert resp["statusCode"] == 403


def test_create_event_missing_fields(events_table):
    resp = handler(_event({"event_id": "x"}), None)  # missing name
    assert resp["statusCode"] == 400


def test_create_event_optional_fields(events_table):
    resp = handler(
        _event(
            {
                "event_id": "mini",
                "name": "Mini Talk",
                "location": "Online",
                "description": "Quick talk",
            }
        ),
        None,
    )
    assert resp["statusCode"] == 201
    item = events_table.get_item(Key={"event_id": "mini"})["Item"]
    assert item["location"] == "Online"
    assert item["description"] == "Quick talk"
