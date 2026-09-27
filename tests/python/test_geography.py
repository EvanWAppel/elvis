import json

import pandas as pd
import pytest
from shapely.geometry import Polygon, mapping

from geography import assign_points, fetch_geojson, summarize_topic, tract_dimension


def test_crossing_tract_membership_does_not_clip_population(
    tract_features, city_features
):
    dim = tract_dimension(tract_features, city_features)
    assert json.loads(dim.iloc[1].cities_json) == ["Henderson", "Las Vegas"]
    assert dim.iloc[0].population == 100
    assert dim.iloc[0].boundary_vintage == "2020"


def test_edge_tie_is_stable_and_bad_coordinates_are_accounted(
    tract_features, observations
):
    assigned = assign_points(observations, tract_features[::-1])
    assert assigned.geoid.tolist()[:3] == ["32003000100"] * 3
    assert assigned.assignment.tolist()[3:] == [
        "invalid_coordinates",
        "outside_tracts",
        "invalid_coordinates",
    ]
    assert assigned.iloc[2].boundary_tie


def test_polygon_holes_are_not_assigned(tract_features):
    tract_features[0]["geometry"] = mapping(
        Polygon(
            [(0, 0), (1, 0), (1, 1), (0, 1)],
            holes=[[(0.2, 0.2), (0.8, 0.2), (0.8, 0.8), (0.2, 0.8)]],
        )
    )
    points = pd.DataFrame({"latitude": [0.5], "longitude": [0.5]})
    assert assign_points(points, tract_features).iloc[0].assignment == "outside_tracts"


def test_invalid_geometry_fails_instead_of_silently_dropping(
    tract_features, city_features
):
    tract_features[0]["geometry"] = mapping(Polygon([(0, 0), (1, 1), (0, 1), (1, 0)]))
    with pytest.raises(ValueError, match="Invalid"):
        tract_dimension(tract_features, city_features)


def test_full_counts_reconcile_including_unmapped_records(
    tract_features, city_features, observations
):
    dim = tract_dimension(tract_features, city_features)
    counts, coverage, audit = summarize_topic(
        "calls", observations, tract_features, dim, {"Las Vegas"}, rate_allowed=True
    )
    assert counts.record_count.sum() == 3
    assert audit["source_records"] == 6
    assert (
        audit["assigned_records"]
        + audit["invalid_coordinates"]
        + audit["outside_tracts"]
        == 6
    )
    assert coverage.coverage.tolist() == ["available", "partial", "unavailable"]
    assert counts.groupby("geoid").record_count.sum().to_dict() == {"32003000100": 3}


def test_empty_source_never_becomes_zero(tract_features, city_features, observations):
    _, coverage, _ = summarize_topic(
        "calls",
        observations.iloc[:0],
        tract_features,
        tract_dimension(tract_features, city_features),
        {"Las Vegas"},
        True,
    )
    assert set(coverage.coverage) == {"unavailable"}


def test_duplicate_geoids_rejected(tract_features, city_features):
    with pytest.raises(ValueError, match="Duplicate"):
        tract_dimension(tract_features + tract_features[:1], city_features)


def test_fetch_geojson_paginates_and_rejects_arcgis_errors():
    calls = []

    def get(url):
        calls.append(url)
        return {
            "features": [{"properties": {"OBJECTID": len(calls)}}],
            "exceededTransferLimit": len(calls) == 1,
        }

    assert len(fetch_geojson("https://example.test/0", "1=1", "*", get=get)) == 2
    assert "resultOffset=1" in calls[1]
    with pytest.raises(RuntimeError, match="ArcGIS"):
        fetch_geojson(
            "https://example.test/0", "1=1", "*", get=lambda _: {"error": {"code": 400}}
        )


def test_fetch_geojson_rejects_truncated_empty_page():
    with pytest.raises(RuntimeError, match="empty"):
        fetch_geojson(
            "https://example.test/0",
            "1=1",
            "*",
            get=lambda _: {"features": [], "exceededTransferLimit": True},
        )


def test_zero_area_polygon_spike_can_be_repaired_without_changing_area():
    from geography import valid_polygon

    feature = {
        "geometry": mapping(
            Polygon([(0, 0), (1, 0), (1, 1), (0.5, 1), (0.5, 1.5), (0.5, 1), (0, 1)])
        )
    }
    result = valid_polygon(feature)
    assert result.is_valid
    assert result.area == 1
