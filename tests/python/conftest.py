"""Synthetic geography only: no live warehouse or public records in tests."""

import json

import pandas as pd
import pytest
from shapely.geometry import Polygon, mapping


@pytest.fixture
def tract_features():
    def feature(geoid, x, population):
        return {
            "type": "Feature",
            "properties": {
                "GEOID": geoid,
                "NAME": f"Tract {geoid}",
                "POP100": population,
            },
            "geometry": mapping(Polygon([(x, 0), (x + 1, 0), (x + 1, 1), (x, 1)])),
        }

    return [
        feature("32003000100", 0, 100),
        feature("32003000200", 1, 0),
        feature("32003000300", 2, None),
    ]


@pytest.fixture
def city_features():
    return [
        {
            "type": "Feature",
            "properties": {"BASENAME": "Las Vegas"},
            "geometry": mapping(Polygon([(0, 0), (1.5, 0), (1.5, 1), (0, 1)])),
        },
        {
            "type": "Feature",
            "properties": {"BASENAME": "Henderson"},
            "geometry": mapping(Polygon([(1.5, 0), (3, 0), (3, 1), (1.5, 1)])),
        },
    ]


@pytest.fixture
def observations():
    return pd.DataFrame(
        {
            "latitude": [0.5, 0.5, 0.5, None, 0.5, 95],
            "longitude": [0.5, 0.5, 1, 0.5, 10, 0.5],
            "category": ["A", "B", "A", "A", "A", "A"],
            "observed_date": ["2026-01-01"] * 6,
        }
    )


@pytest.fixture
def map_rows():
    return pd.DataFrame(
        [
            {
                "geoid": "a",
                "tract_name": "A",
                "cities_json": json.dumps(["Las Vegas"]),
                "geometry_json": json.dumps(
                    mapping(Polygon([(0, 0), (1, 0), (1, 1), (0, 1)]))
                ),
                "record_count": 10,
                "coverage": "available",
                "population": 100,
                "rate_per_1000": 100,
                "period": "2026",
                "boundary_vintage": "2020",
            },
            {
                "geoid": "b",
                "tract_name": "B",
                "cities_json": json.dumps(["Henderson"]),
                "geometry_json": json.dumps(
                    mapping(Polygon([(1, 0), (2, 0), (2, 1), (1, 1)]))
                ),
                "record_count": 100,
                "coverage": "available",
                "population": 100,
                "rate_per_1000": 1000,
                "period": "2026",
                "boundary_vintage": "2020",
            },
            {
                "geoid": "c",
                "tract_name": "C",
                "cities_json": json.dumps(["Henderson"]),
                "geometry_json": json.dumps(
                    mapping(Polygon([(2, 0), (3, 0), (3, 1), (2, 1)]))
                ),
                "record_count": None,
                "coverage": "unavailable",
                "population": None,
                "rate_per_1000": None,
                "period": "2026",
                "boundary_vintage": "2020",
            },
        ]
    )


@pytest.fixture
def fake_arcgis(monkeypatch):
    """Script urlopen responses for build_warehouse's ArcGIS fetch; no network.

    Each scripted item is a dict (returned as the JSON body) or an exception
    (raised). Returns the state dict: ``script`` (set by the test), ``urls``
    (requested URLs), and ``sleeps`` (backoff delays, recorded rather than taken).
    """
    import io
    import urllib.request

    import build_warehouse as warehouse

    state = {"script": [], "urls": [], "sleeps": []}

    class _Resp(io.BytesIO):
        def __enter__(self):
            return self

        def __exit__(self, *exc):
            return False

    def fake_urlopen(url, timeout=None, context=None):
        state["urls"].append(url)
        item = state["script"].pop(0)
        if isinstance(item, BaseException):
            raise item
        return _Resp(json.dumps(item).encode())

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    monkeypatch.setattr(warehouse.time, "sleep", state["sleeps"].append)
    return state


@pytest.fixture
def lvcva_workbook():
    """Synthetic LVCVA-shaped XLSX as bytes; every value is made up.

    A decoy first sheet, then a "Las Vegas" sheet: title rows, a month-date
    header (values in odd columns, revision flags in even ones), three indicator
    rows, a blank row, then a "Change from Previous Year" block that must be
    ignored.
    """
    import datetime
    import io

    from openpyxl import Workbook

    # Excel cells carry no timezone, so naive datetimes are the faithful input.
    months = [datetime.datetime(2025, m, 1) for m in (1, 2, 3, 4)]  # noqa: DTZ001
    wb = Workbook()
    wb.active.title = "Notes"
    wb.active.append(["Not the sheet you want", months[0]])
    ws = wb.create_sheet("Las Vegas Summary")
    ws.append(["Synthetic Executive Summary"])
    ws.append([None])
    header = [None]
    for month in months:
        header += [month, None]
    ws.append(header)
    ws.append(["Visitor\n   Volume ", 10, "r", 20, None, 30, None, 40, None])
    ws.append(["Room Nights", 1.5, None, "n/a", None, None, None, 4.5, "p"])
    ws.append(["Gaming Win", 100, None, 200, None, 300, None, 400, None])
    ws.append([None])
    ws.append(["Change from Previous Year"])
    ws.append(header)
    ws.append(["Visitor Volume", 0.1, None, 0.2, None, 0.3, None, 0.4, None])
    buf = io.BytesIO()
    wb.save(buf)
    return buf.getvalue()


@pytest.fixture
def write_snhd(tmp_path):
    """Write synthetic semicolon-delimited SNHD-style text (cp1252) to a file."""

    def write(name: str, lines: list[str]):
        path = tmp_path / name
        path.write_bytes("\r\n".join(lines).encode("cp1252"))
        return path

    return write
