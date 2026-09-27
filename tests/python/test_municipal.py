import json

import pandas as pd
import pytest

import build_warehouse as warehouse


def test_henderson_art_has_namespaced_key_and_no_invented_photo(monkeypatch):
    monkeypatch.setattr(
        warehouse,
        "fetch_features",
        lambda *a, **k: [
            (
                {
                    "OBJECTID": 7,
                    "TITLE": "Synthetic sculpture",
                    "ARTIST": "Fixture",
                    "LOCATION": "Test park",
                    "URL": "https://example.test/art",
                },
                {"x": -115, "y": 36},
            )
        ],
    )
    result = warehouse.fetch_henderson_art()
    assert result.iloc[0].artwork_id == "henderson:7"
    assert result.iloc[0].jurisdiction == "Henderson"
    assert pd.isna(result.iloc[0].pic_url)


def test_henderson_road_parts_are_not_connected_by_fake_diagonals(monkeypatch):
    monkeypatch.setattr(
        warehouse,
        "fetch_features",
        lambda *a, **k: [
            (
                {
                    "OBJECTID": 1,
                    "PROJECT_NUMBER": "TEST",
                    "PROJECT_NAME": "Fixture road",
                    "PROJECT_PHASE": "Design",
                },
                {
                    "paths": [
                        [[-115, 36], [-115.1, 36]],
                        [[-115.3, 36.2], [-115.4, 36.2]],
                    ]
                },
            )
        ],
    )
    result = warehouse.fetch_henderson_cip()
    # Both symbolic line layers depict the same geometry; exact duplicates collapse.
    assert len(result) == 2
    assert result.source_record_id.nunique() == 2
    assert all(len(json.loads(path)) == 2 for path in result.path_json)
    assert set(result.source) == {"City of Henderson (CIP)"}


def test_arcgis_service_error_is_not_an_empty_dataset(monkeypatch):
    class Response:
        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass

        def read(self):
            return json.dumps(
                {"error": {"code": 400, "message": "Invalid fields"}}
            ).encode()

    monkeypatch.setattr(warehouse.urllib.request, "urlopen", lambda *a, **k: Response())
    with pytest.raises(RuntimeError, match="ArcGIS"):
        warehouse.fetch_features("https://example.test/MapServer/0")
