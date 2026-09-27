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


def test_henderson_crime_namespaces_year_and_parses_offense_and_point(monkeypatch):
    # Only the configured recent years are pulled, resolved by layer name so a
    # reordered service cannot silently return the wrong year.
    monkeypatch.setattr(warehouse, "HENDERSON_CRIME_YEARS", [2025])
    monkeypatch.setattr(
        warehouse, "_henderson_crime_layer_ids", lambda years: {2025: 17}
    )
    monkeypatch.setattr(
        warehouse,
        "fetch_features",
        lambda *a, **k: [
            (
                {
                    "OBJECTID": 4,
                    "EVENT__": "LLV250001",
                    "CITY": "HENDERSON",
                    "BEAT": "H12",
                    "INC_PRIMAR": "BURGLARY",
                    "INC_ADDRESS": "100 WATER ST",
                    "OCCURRED_S": 1735732800000,  # 2025-01-01, epoch ms
                    "PROC_DATE": 1735819200000,
                },
                {"x": -114.98, "y": 36.03},
            )
        ],
    )
    result = warehouse.fetch_henderson_crime()
    row = result.iloc[0]
    assert row.crime_id == "henderson:2025:4"
    assert row.jurisdiction == "Henderson"
    assert row.category == "BURGLARY"
    assert row.observed_date == "2025-01-01"
    assert (row.longitude, row.latitude) == (-114.98, 36.03)
    # No LVMPD call-record fields are fabricated onto a crime-report record.
    assert list(result.columns) == warehouse.HENDERSON_CRIME_COLUMNS


def test_henderson_crime_missing_year_layer_fails_loudly(monkeypatch):
    monkeypatch.setattr(
        warehouse,
        "_get_json",
        lambda url: {"layers": [{"id": 17, "name": "Crime Data 2025"}]},
    )
    with pytest.raises(RuntimeError, match="Crime Data 2099"):
        warehouse._henderson_crime_layer_ids([2099])


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
