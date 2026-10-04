"""ArcGIS fetches retry transient server errors, then fail loudly (no silent gaps)."""

import http.client
import logging
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
    assert fake_arcgis["sleeps"] == [10.0, 20.0]


def test_retries_network_timeout(fake_arcgis):
    fake_arcgis["script"] = [TimeoutError("timed out"), META, PAGE]
    assert warehouse.fetch_features(URL, geometry=False) == [({"id": 1}, None)]


def test_gives_up_after_max_attempts_and_raises(fake_arcgis):
    attempts = warehouse.ARCGIS_ATTEMPTS
    fake_arcgis["script"] = [_http_error(502)] * attempts
    with pytest.raises(urllib.error.HTTPError):
        warehouse.fetch_features(URL)
    assert len(fake_arcgis["urls"]) == attempts
    # Backs off between attempts, but not after the final failure.
    assert fake_arcgis["sleeps"] == [10.0, 20.0][: attempts - 1]


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


@pytest.mark.parametrize(
    "transient",
    [
        http.client.RemoteDisconnected("Remote end closed connection"),
        ConnectionResetError(54, "Connection reset by peer"),
        http.client.IncompleteRead(b"{\"feat", 100),
        urllib.error.URLError("temporary failure"),
    ],
    ids=["remote-disconnected", "connection-reset", "incomplete-read", "url-error"],
)
def test_retries_dropped_connections(fake_arcgis, transient):
    fake_arcgis["script"] = [transient, META, PAGE]
    assert warehouse.fetch_features(URL, geometry=False) == [({"id": 1}, None)]


def test_retry_is_logged(fake_arcgis, caplog):
    fake_arcgis["script"] = [_http_error(503), META, PAGE]
    with caplog.at_level(logging.WARNING):
        warehouse.fetch_features(URL, geometry=False)
    assert "attempt 1/3 failed" in caplog.text
    assert URL in caplog.text


# --- fetch_layer (CLV org layers: crime, permits, art, fire) ------------------

LAYER_META = {"maxRecordCount": 1000, "fields": []}
LAYER_PAGE = {"features": [{"attributes": {"id": 1}}]}


def test_fetch_layer_retries_5xx(fake_arcgis):
    fake_arcgis["script"] = [LAYER_META, _http_error(502), LAYER_PAGE, {"features": []}]
    df = warehouse.fetch_layer("Svc", org="https://gis.example.test/rest")
    assert df["id"].tolist() == [1]


def test_fetch_layer_error_body_fails_instead_of_truncating(fake_arcgis):
    # Previously an ArcGIS error body read as "no more features" and silently
    # returned a truncated (here: empty) table.
    fake_arcgis["script"] = [
        LAYER_META,
        {"error": {"code": 400, "message": "Invalid query"}},
    ]
    with pytest.raises(RuntimeError, match="Invalid query"):
        warehouse.fetch_layer("Svc", org="https://gis.example.test/rest")


def test_fetch_layer_missing_features_key_fails(fake_arcgis):
    fake_arcgis["script"] = [LAYER_META, {"unexpected": True}]
    with pytest.raises(RuntimeError, match="missing features"):
        warehouse.fetch_layer("Svc", org="https://gis.example.test/rest")
