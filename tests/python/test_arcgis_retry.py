"""ArcGIS fetches retry transient server errors, then fail loudly (no silent gaps)."""

import urllib.error

import pytest

import build_warehouse as warehouse

URL = "https://gis.example.test/arcgis/rest/services/X/MapServer/0"
META = {"maxRecordCount": 1000}
PAGE = {"features": [{"attributes": {"id": 1}, "geometry": None}]}


def _http_error(code):
    return urllib.error.HTTPError(URL, code, "err", {}, None)


def test_retries_http_5xx_then_succeeds(fake_arcgis):
    fake_arcgis["script"] = [_http_error(500), META, PAGE]
    rows = warehouse.fetch_features(URL, geometry=False)
    assert rows == [({"id": 1}, None)]
    assert len(fake_arcgis["urls"]) == 3
    assert len(fake_arcgis["sleeps"]) == 1


def test_retries_arcgis_error_body_5xx(fake_arcgis):
    busy = {"error": {"code": 503, "message": "User couldn't access this resource"}}
    fake_arcgis["script"] = [META, busy, busy, PAGE]
    rows = warehouse.fetch_features(URL, geometry=False)
    assert rows == [({"id": 1}, None)]
    assert fake_arcgis["sleeps"] == sorted(fake_arcgis["sleeps"])  # backoff grows


def test_retries_network_timeout(fake_arcgis):
    fake_arcgis["script"] = [TimeoutError("timed out"), META, PAGE]
    assert warehouse.fetch_features(URL, geometry=False) == [({"id": 1}, None)]


def test_gives_up_after_max_attempts_and_raises(fake_arcgis):
    attempts = warehouse.ARCGIS_ATTEMPTS
    fake_arcgis["script"] = [_http_error(502)] * attempts
    with pytest.raises(urllib.error.HTTPError):
        warehouse.fetch_features(URL)
    assert len(fake_arcgis["urls"]) == attempts


def test_arcgis_5xx_body_exhausted_raises_runtime_error(fake_arcgis):
    busy = {"error": {"code": 500, "message": "boom"}}
    fake_arcgis["script"] = [busy] * warehouse.ARCGIS_ATTEMPTS
    with pytest.raises(RuntimeError, match="ArcGIS request failed"):
        warehouse.fetch_features(URL)


def test_client_errors_are_not_retried(fake_arcgis):
    fake_arcgis["script"] = [_http_error(404)]
    with pytest.raises(urllib.error.HTTPError):
        warehouse.fetch_features(URL)
    assert len(fake_arcgis["urls"]) == 1


def test_arcgis_4xx_body_is_not_retried(fake_arcgis):
    fake_arcgis["script"] = [{"error": {"code": 400, "message": "Invalid query"}}]
    with pytest.raises(RuntimeError, match="Invalid query"):
        warehouse.fetch_features(URL)
    assert len(fake_arcgis["urls"]) == 1
