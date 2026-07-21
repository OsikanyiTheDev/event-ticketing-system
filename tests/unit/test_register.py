"""Tests for the POST /register handler using moto."""

import json
from unittest.mock import MagicMock

import boto3
import pytest
import register.app as app_module
from moto import mock_aws
from register.app import handler


@pytest.fixture
def tables(monkeypatch):
    """Create mocked Events + Registrations tables (with the email GSI)."""
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")
    monkeypatch.setenv("EVENTS_TABLE", "test-events")
    monkeypatch.setenv("REGISTRATIONS_TABLE", "test-registrations")

    app_module._events_table = None
    app_module._registrations_table = None
    app_module._sns_client = None
    app_module._ses_client = None

    with mock_aws():
        dynamo = boto3.resource("dynamodb", region_name="us-east-1")
        events = dynamo.create_table(
            TableName="test-events",
            KeySchema=[{"AttributeName": "event_id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "event_id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        registrations = dynamo.create_table(
            TableName="test-registrations",
            KeySchema=[{"AttributeName": "registration_id", "KeyType": "HASH"}],
            AttributeDefinitions=[
                {"AttributeName": "registration_id", "AttributeType": "S"},
                {"AttributeName": "email", "AttributeType": "S"},
            ],
            GlobalSecondaryIndexes=[
                {
                    "IndexName": "email-index",
                    "KeySchema": [{"AttributeName": "email", "KeyType": "HASH"}],
                    "Projection": {"ProjectionType": "ALL"},
                }
            ],
            BillingMode="PAY_PER_REQUEST",
        )
        # seed one valid event
        events.put_item(Item={"event_id": "e1", "name": "Tech Meetup", "capacity": 100})
        yield {"events": events, "registrations": registrations}


def _event(body):
    """Build an API-Gateway-style event with a JSON body."""
    return {"httpMethod": "POST", "body": json.dumps(body)}


def test_register_success_creates_record(tables):
    resp = handler(_event({"event_id": "e1", "email": "kwesi@example.com", "name": "Kwesi"}), None)
    assert resp["statusCode"] == 201
    body = json.loads(resp["body"])
    assert "registration_id" in body["data"]
    assert body["data"]["status"] == "confirmed"
    # it was actually persisted
    items = tables["registrations"].scan()["Items"]
    assert len(items) == 1
    assert items[0]["email"] == "kwesi@example.com"


def test_register_normalizes_email_lowercase(tables):
    handler(_event({"event_id": "e1", "email": "KWESI@Example.COM", "name": "Kwesi"}), None)
    items = tables["registrations"].scan()["Items"]
    assert items[0]["email"] == "kwesi@example.com"


def test_register_rejects_missing_fields(tables):
    resp = handler(_event({"event_id": "e1"}), None)  # missing email + name
    assert resp["statusCode"] == 400


def test_register_rejects_invalid_email(tables):
    resp = handler(_event({"event_id": "e1", "email": "not-an-email", "name": "Kwesi"}), None)
    assert resp["statusCode"] == 400


def test_register_unknown_event_returns_404(tables):
    resp = handler(
        _event({"event_id": "nope", "email": "kwesi@example.com", "name": "Kwesi"}), None
    )
    assert resp["statusCode"] == 404


def test_register_duplicate_returns_409(tables):
    payload = {"event_id": "e1", "email": "kwesi@example.com", "name": "Kwesi"}
    handler(_event(payload), None)  # first time → 201
    resp = handler(_event(payload), None)  # second time → 409
    assert resp["statusCode"] == 409
    # still only ONE registration
    assert len(tables["registrations"].scan()["Items"]) == 1


def test_register_same_email_different_events_ok(tables):
    tables["events"].put_item(Item={"event_id": "e2", "name": "Cloud Workshop"})
    payload = {"email": "kwesi@example.com", "name": "Kwesi"}
    r1 = handler(_event({**payload, "event_id": "e1"}), None)
    r2 = handler(_event({**payload, "event_id": "e2"}), None)
    assert r1["statusCode"] == 201 and r2["statusCode"] == 201
    assert len(tables["registrations"].scan()["Items"]) == 2


def test_register_rejects_garbage_body(tables):
    resp = handler({"body": "not json"}, None)
    assert resp["statusCode"] == 400


def test_register_publishes_sns_when_configured(tables, monkeypatch):
    """When SNS_TOPIC_ARN is set, a confirmation message is published."""
    monkeypatch.setenv("SNS_TOPIC_ARN", "arn:aws:sns:us-east-1:123456789012:test-topic")
    mock_sns = MagicMock()
    app_module._sns_client = mock_sns  # inject a fake SNS client

    resp = handler(_event({"event_id": "e1", "email": "kwesi@example.com", "name": "Kwesi"}), None)
    assert resp["statusCode"] == 201
    # publish was called exactly once with the registration details
    mock_sns.publish.assert_called_once()
    kwargs = mock_sns.publish.call_args.kwargs
    assert kwargs["TopicArn"] == "arn:aws:sns:us-east-1:123456789012:test-topic"
    assert "Kwesi" in kwargs["Message"]
    assert "e1" in kwargs["Message"]


def test_register_succeeds_without_sns_configured(tables):
    """No SNS_TOPIC_ARN → registration still succeeds (SNS is optional)."""
    resp = handler(_event({"event_id": "e1", "email": "kwesi@example.com", "name": "Kwesi"}), None)
    assert resp["statusCode"] == 201
