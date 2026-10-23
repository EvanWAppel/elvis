"""Pure helpers in build_warehouse.py, exercised with synthetic inputs only."""

import logging
import math

import pandas as pd
import pytest

import build_warehouse as warehouse


# --- _decode_polyline ------------------------------------------------------ #
def test_decode_polyline_matches_google_reference():
    # Google's documented example: (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
    coords = warehouse._decode_polyline("_p~iF~ps|U_ulLnnqC_mqNvxq`@")
    expected = [[-120.2, 38.5], [-120.95, 40.7], [-126.453, 43.252]]
    assert len(coords) == len(expected)
    for (lon, lat), (elon, elat) in zip(coords, expected, strict=True):
        assert lon == pytest.approx(elon)
        assert lat == pytest.approx(elat)


@pytest.mark.parametrize("encoded", ["", None])
def test_decode_polyline_empty_is_empty(encoded):
    assert warehouse._decode_polyline(encoded) == []


def test_decode_polyline_single_origin_point():
    assert warehouse._decode_polyline("??") == [[0.0, 0.0]]


def test_decode_polyline_truncated_input_fails_loudly():
    with pytest.raises(IndexError):
        warehouse._decode_polyline("_p~iF")  # latitude only, no longitude


# --- _iso_date / _epoch_to_date -------------------------------------------- #
@pytest.mark.parametrize(
    ("value", "expected"),
    [
        ("03/15/2024", "2024-03-15"),
        ("2024-03-15T08:30:00-07:00", "2024-03-15"),
        ("2024-03-15", "2024-03-15"),
        (pd.Timestamp("2021-07-04 12:00"), "2021-07-04"),
        ("1900-01-01", None),  # sentinel
        ("1989-12-31", None),  # pre-1990 treated as sentinel
        ("1990-01-01", "1990-01-01"),
        ("not a date", None),
        ("", None),
        (None, None),
        (float("nan"), None),
    ],
)
def test_iso_date(value, expected):
    assert warehouse._iso_date(value) == expected


@pytest.mark.parametrize(
    ("ms", "expected"),
    [
        (1_710_460_800_000, "2024-03-15"),  # 2024-03-15T00:00:00Z
        (1_710_460_800_000.0, "2024-03-15"),
        (-2_208_988_800_000, None),  # 1900-01-01 sentinel
        (0, None),  # 1970 is pre-1990
        (None, None),
        (float("nan"), None),
        (pd.NA, None),
    ],
)
def test_epoch_to_date(ms, expected):
    assert warehouse._epoch_to_date(ms) == expected


# --- _nv_clean ------------------------------------------------------------- #
@pytest.mark.parametrize(
    ("value", "expected"),
    [
        ("Unknown", None),
        ("  NO DATA ", None),
        ("none", None),
        ("N/A", None),
        ("", None),
        ("   ", None),
        (None, None),
        ("  I-15 Northbound ", "I-15 Northbound"),
        (2, "2"),
    ],
)
def test_nv_clean(value, expected):
    assert warehouse._nv_clean(value) == expected


# --- geometry -------------------------------------------------------------- #
def test_line_path_flattens_parts_and_drops_short_points():
    geom = {"paths": [[[0, 0], [1, 1, 99]], [[2, 2], [3]]]}
    assert warehouse._line_path(geom) == [[0, 0], [1, 1], [2, 2]]


@pytest.mark.parametrize("geom", [None, {}, {"paths": []}, {"x": 1, "y": 2}])
def test_line_path_missing_geometry_is_empty(geom):
    assert warehouse._line_path(geom) == []


def test_path_centroid_is_vertex_average():
    assert warehouse._path_centroid([[0, 0], [2, 0], [4, 6]]) == (2, 2)


def test_path_centroid_empty():
    assert warehouse._path_centroid([]) == (None, None)


def test_centroid_point():
    assert warehouse._centroid({"x": -115.1, "y": 36.2}) == (-115.1, 36.2)


def test_centroid_point_at_zero_is_not_missing():
    assert warehouse._centroid({"x": 0, "y": 0}) == (0, 0)


def test_centroid_closed_ring_ignores_repeated_vertex():
    # Closed square: the repeated first vertex must not bias the average.
    ring = [[0, 0], [4, 0], [4, 4], [0, 4], [0, 0]]
    assert warehouse._centroid({"rings": [ring, [[9, 9], [9, 9]]]}) == (2, 2)


def test_centroid_open_ring_uses_all_vertices():
    assert warehouse._centroid({"rings": [[[0, 0], [3, 0], [0, 3]]]}) == (1, 1)


@pytest.mark.parametrize("geom", [None, {}, {"rings": []}, {"rings": [[]]}])
def test_centroid_missing_geometry(geom):
    assert warehouse._centroid(geom) == (None, None)


SQUARE = [[0, 0], [4, 0], [4, 4], [0, 4], [0, 0]]
# A "U" shape: the notch between x=1..3 above y=1 is outside.
U_SHAPE = [[0, 0], [4, 0], [4, 4], [3, 4], [3, 1], [1, 1], [1, 4], [0, 4], [0, 0]]


@pytest.mark.parametrize(
    ("ring", "lon", "lat", "inside"),
    [
        (SQUARE, 2, 2, True),
        (SQUARE, 5, 2, False),
        (SQUARE, -1, 2, False),
        (SQUARE, 2, 5, False),
        (SQUARE[:-1], 2, 2, True),  # unclosed ring behaves the same
        (U_SHAPE, 0.5, 3, True),
        (U_SHAPE, 3.5, 3, True),
        (U_SHAPE, 2, 3, False),  # in the notch
        (U_SHAPE, 2, 0.5, True),  # in the base
    ],
)
def test_point_in_ring(ring, lon, lat, inside):
    assert warehouse._point_in_ring(lon, lat, ring) is inside


def test_point_in_ring_degenerate_ring():
    assert warehouse._point_in_ring(0, 0, []) is False


# --- _parse_lvcva ---------------------------------------------------------- #
def test_parse_lvcva_melts_absolute_block(lvcva_workbook):
    df = warehouse._parse_lvcva(lvcva_workbook)
    assert list(df.columns) == ["metric", "month", "value"]
    rows = set(df.itertuples(index=False, name=None))
    assert rows == {
        ("Visitor Volume", "2025-01-01", 10.0),
        ("Visitor Volume", "2025-02-01", 20.0),
        ("Visitor Volume", "2025-03-01", 30.0),
        ("Visitor Volume", "2025-04-01", 40.0),
        ("Room Nights", "2025-01-01", 1.5),
        ("Room Nights", "2025-04-01", 4.5),
        ("Gaming Win", "2025-01-01", 100.0),
        ("Gaming Win", "2025-02-01", 200.0),
        ("Gaming Win", "2025-03-01", 300.0),
        ("Gaming Win", "2025-04-01", 400.0),
    }


def test_parse_lvcva_values_are_floats(lvcva_workbook):
    df = warehouse._parse_lvcva(lvcva_workbook)
    assert all(isinstance(v, float) and not math.isnan(v) for v in df["value"])


def test_parse_lvcva_without_las_vegas_sheet_fails_loudly():
    import io

    from openpyxl import Workbook

    buf = io.BytesIO()
    Workbook().save(buf)
    with pytest.raises(StopIteration):
        warehouse._parse_lvcva(buf.getvalue())


# --- _read_delimited ------------------------------------------------------- #
def test_read_delimited_parses_and_drops_trailing_column(write_snhd):
    path = write_snhd(
        "establishments.csv",
        [
            "permit_number;name;city;",
            "PR001;Café Uno;Las Vegas;",
            "",
            "PR002;Diner Two;;",
        ],
    )
    df = warehouse._read_delimited(path)
    assert list(df.columns) == ["permit_number", "name", "city"]
    assert df["permit_number"].tolist() == ["PR001", "PR002"]
    assert df.loc[0, "name"] == "Café Uno"  # cp1252 decoded
    assert pd.isna(df.loc[1, "city"])  # empty -> NA


def test_read_delimited_skips_and_logs_shifted_rows(write_snhd, caplog):
    path = write_snhd(
        "inspections.csv",
        [
            "id;note;",
            "1;fine;",
            "2;stray ; semicolon;",
            "3;ok;",
        ],
    )
    with caplog.at_level(logging.WARNING, logger="build_warehouse"):
        df = warehouse._read_delimited(path)
    assert df["id"].tolist() == ["1", "3"]
    assert "skipped 1 malformed rows" in caplog.text


def test_read_delimited_header_only(write_snhd):
    df = warehouse._read_delimited(write_snhd("empty.csv", ["a;b;"]))
    assert list(df.columns) == ["a", "b"]
    assert df.empty


# --- _clv_water_points ----------------------------------------------------- #
def test_clv_water_points_drops_half_missing_coordinates(monkeypatch):
    # A point geometry with an x but no y must not leak a (lon, None) pair.
    geoms = [{"x": -115.1, "y": 36.1}, {"x": -115.2, "y": None}, None]
    monkeypatch.setattr(
        warehouse,
        "fetch_features",
        lambda url, out_fields="*": [({}, g) for g in geoms],
    )
    pts = warehouse._clv_water_points()
    assert pts and all(lat is not None and lon is not None for lon, lat in pts)
    assert set(pts) == {(-115.1, 36.1)}
