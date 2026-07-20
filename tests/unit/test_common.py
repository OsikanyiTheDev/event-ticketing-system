"""
Tests for the shared common library.
These need NO AWS — pure Python. (Handler tests later will use moto.)
"""
import json

import pytest

from common.responses import CORS_HEADERS, created, error, success
from common.errors import APIError, ConflictError, NotFoundError, ValidationError
from common.validation import (
    parse_json_body,
    require_fields,
    sanitize_string,
    validate_email,
)


# ───────────────────────── responses ────────────────────────
def test_success_wraps_data_and_returns_200():
    resp = success({"event_id": "123"})
    assert resp["statusCode"] == 200
    # body is a JSON STRING — verify it round-trips back to a dict
    assert json.loads(resp["body"]) == {"success": True, "data": {"event_id": "123"}}


def test_created_returns_201():
    assert created({"id": "abc"})["statusCode"] == 201


def test_error_includes_message_and_status():
    resp = error("Bad input", status_code=400)
    assert resp["statusCode"] == 400
    assert json.loads(resp["body"])["error"] == "Bad input"


def test_every_response_has_cors_headers():
    for resp in (success(), created(), error("x")):
        assert "Access-Control-Allow-Origin" in resp["headers"]


def test_response_shape_is_api_gateway_compatible():
    resp = success({"a": 1})
    # API Gateway needs ALL of these keys, and body must be a string
    assert set(resp) >= {"statusCode", "headers", "body"}
    assert isinstance(resp["body"], str)


# ───────────────────────── validation ───────────────────────
def test_validate_email_normalizes_to_lowercase():
    assert validate_email("Kwesi@Example.COM") == "kwesi@example.com"


def test_validate_email_rejects_garbage():
    for bad in ("not-an-email", "", None, "a@b"):
        with pytest.raises(ValueError):
            validate_email(bad)


def test_sanitize_string_trims_and_caps_length():
    assert sanitize_string("  hello  ") == "hello"
    assert sanitize_string("a" * 1000, max_length=10) == "a" * 10


def test_parse_json_body_parses_string():
    assert parse_json_body('{"a": 1}') == {"a": 1}


def test_parse_json_body_rejects_garbage():
    for bad in ("not json", "", None):
        with pytest.raises(ValueError):
            parse_json_body(bad)


def test_require_fields_flags_missing():
    assert require_fields({"a": 1, "b": 2}, ["a", "b"]) == {"a": 1, "b": 2}
    with pytest.raises(ValueError):
        require_fields({"a": 1}, ["a", "b"])


# ───────────────────────── errors ───────────────────────────
def test_error_classes_carry_status_codes():
    assert ValidationError("x").status_code == 400
    assert NotFoundError("x").status_code == 404
    assert ConflictError("x").status_code == 409


def test_errors_are_api_errors():
    # all of them subclass APIError so one except clause catches them all
    assert issubclass(ValidationError, APIError)
    assert issubclass(NotFoundError, APIError)
    assert issubclass(ConflictError, APIError)
