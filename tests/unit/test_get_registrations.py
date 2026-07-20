"""Tests for GET /registrations/{email} using moto."""
import json

import boto3
import pytest
from moto import mock_aws

import get_registrations.app as app_module
from get_registrations.app import handler


@pytest.fixture
def registrations_table(monkeypatch):
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")
    monkeypatch.setenv("REGISTRATIONS_TABLE", "test-registrations")
    app_module._table = None

    with mock_aws():
        table = boto3.resource("dynamodb", region_name="us-east-1").create_table(
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
        yield table


def _event(email):
    return {"httpMethod": "GET", "pathParameters": {"email": email}}


def test_get_registrations_empty(registrations_table):
    resp = handler(_event("nobody@example.com"), None)
    assert resp["statusCode"] == 200
    assert json.loads(resp["body"])["data"]["count"] == 0


def test_get_registrations_returns_only_that_email(registrations_table):
    registrations_table.put_item(Item={"registration_id": "r1", "email": "a@x.com", "event_id": "e1"})
    registrations_table.put_item(Item={"registration_id": "r2", "email": "a@x.com", "event_id": "e2"})
    registrations_table.put_item(Item={"registration_id": "r3", "email": "b@x.com", "event_id": "e1"})

    resp = handler(_event("a@x.com"), None)
    body = json.loads(resp["body"])
    assert body["data"]["count"] == 2
    ids = {r["registration_id"] for r in body["data"]["registrations"]}
    assert ids == {"r1", "r2"}


def test_get_registrations_normalizes_email(registrations_table):
    registrations_table.put_item(Item={"registration_id": "r1", "email": "kwesi@x.com", "event_id": "e1"})
    resp = handler(_event("KWESI@X.COM"), None)
    assert json.loads(resp["body"])["data"]["count"] == 1


def test_get_registrations_invalid_email_returns_400(registrations_table):
    resp = handler(_event("not-an-email"), None)
    assert resp["statusCode"] == 400
