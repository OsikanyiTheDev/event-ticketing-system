"""Tests for DELETE /registration/{id} using moto."""
import json

import boto3
import pytest
from moto import mock_aws

import cancel_registration.app as app_module
from cancel_registration.app import handler


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
            AttributeDefinitions=[{"AttributeName": "registration_id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        yield table


def _event(reg_id):
    return {"httpMethod": "DELETE", "pathParameters": {"id": reg_id}}


def test_cancel_success(registrations_table):
    registrations_table.put_item(Item={"registration_id": "r1", "email": "a@x.com"})
    resp = handler(_event("r1"), None)
    assert resp["statusCode"] == 200
    assert json.loads(resp["body"])["data"]["deleted"] is True
    # really gone
    assert "Item" not in registrations_table.get_item(Key={"registration_id": "r1"})


def test_cancel_unknown_returns_404(registrations_table):
    resp = handler(_event("nonexistent"), None)
    assert resp["statusCode"] == 404


def test_cancel_missing_id_returns_400(registrations_table):
    resp = handler({"pathParameters": {}}, None)
    assert resp["statusCode"] == 400


def test_cancel_safe_if_already_deleted(registrations_table):
    registrations_table.put_item(Item={"registration_id": "r1", "email": "a@x.com"})
    handler(_event("r1"), None)            # first delete → 200
    resp = handler(_event("r1"), None)     # second delete → 404 (no crash)
    assert resp["statusCode"] == 404
