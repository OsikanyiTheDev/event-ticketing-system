"""Tests for DELETE /admin/events/{id} (delete_event handler)."""
import json

import boto3
import pytest
from moto import mock_aws

import delete_event.app as app_module
from delete_event.app import handler


@pytest.fixture
def events_table(monkeypatch):
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
        table.put_item(Item={"event_id": "e1", "name": "Test"})
        yield table


def _event(event_id, api_key="secret-key-123"):
    return {"httpMethod": "DELETE", "headers": {"x-api-key": api_key}, "pathParameters": {"id": event_id}}


def test_delete_event_success(events_table):
    resp = handler(_event("e1"), None)
    assert resp["statusCode"] == 200
    assert "Item" not in events_table.get_item(Key={"event_id": "e1"})


def test_delete_event_wrong_key(events_table):
    resp = handler(_event("e1", api_key="wrong"), None)
    assert resp["statusCode"] == 403


def test_delete_event_unknown(events_table):
    resp = handler(_event("nonexistent"), None)
    assert resp["statusCode"] == 404


def test_delete_event_missing_id(events_table):
    resp = handler({"headers": {"x-api-key": "secret-key-123"}, "pathParameters": {}}, None)
    assert resp["statusCode"] == 400
