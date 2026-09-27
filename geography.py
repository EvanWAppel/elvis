"""Build-time census geography. No source records are logged or sampled.

City filters select whole intersecting tracts, not clipped numerators. This keeps
counts and population on the same footprint even along municipal boundaries.
"""

from __future__ import annotations

import json
import logging
import urllib.parse
import urllib.request
from collections.abc import Callable

import numpy as np
import pandas as pd
import shapely
from shapely.geometry import box, mapping, shape
from shapely.strtree import STRtree

log = logging.getLogger(__name__)
CENSUS_BASE = "https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/tigerWMS_Census2020/MapServer"
TRACT_URL = f"{CENSUS_BASE}/6"
PLACE_URL = f"{CENSUS_BASE}/26"
VINTAGE = "2020"
UNINCORPORATED = "Unincorporated Clark County"
METRO_EXTENT = (-115.5, 35.8, -114.9, 36.4)


def get_json(url: str) -> dict:
    request = urllib.request.Request(
        url, headers={"User-Agent": "Elvis open-data explorer"}
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        return json.load(response)


def fetch_geojson(
    url: str, where: str, fields: str, *, get: Callable = get_json
) -> list[dict]:
    """Fetch complete, ordered pages; service errors must never masquerade as no data."""
    features: list[dict] = []
    seen: set[str] = set()
    while True:
        params = urllib.parse.urlencode(
            {
                "where": where,
                "outFields": fields,
                "returnGeometry": "true",
                "outSR": 4326,
                "f": "geojson",
                "resultOffset": len(features),
                "resultRecordCount": 1000,
                "orderByFields": "OBJECTID",
            }
        )
        response = get(f"{url}/query?{params}")
        if "error" in response:
            raise RuntimeError(f"ArcGIS query failed for {url}: {response['error']}")
        if "features" not in response:
            raise RuntimeError(f"ArcGIS response missing features: {url}")
        page = response["features"]
        if not page and response.get("exceededTransferLimit"):
            raise RuntimeError(f"ArcGIS returned an empty truncated page: {url}")
        for feature in page:
            identity = str(feature["properties"].get("OBJECTID", feature.get("id")))
            if identity in seen:
                raise RuntimeError(f"ArcGIS repeated an object across pages: {url}")
            seen.add(identity)
        features.extend(page)
        if not response.get("exceededTransferLimit"):
            break
    log.info("Fetched geographic layer %s (%d features)", url, len(features))
    return features


def valid_polygon(feature: dict):
    geometry = shape(feature["geometry"])
    if not geometry.is_valid and geometry.geom_type in {"Polygon", "MultiPolygon"}:
        repaired = shapely.make_valid(geometry)
        if repaired.geom_type == "GeometryCollection":
            repaired = shapely.union_all(
                [
                    part
                    for part in repaired.geoms
                    if part.geom_type in {"Polygon", "MultiPolygon"}
                ]
            )
        tolerance = max(1e-12, geometry.area * 1e-6)
        if abs(repaired.area - geometry.area) <= tolerance:
            log.warning(
                "Repaired census topology artifact with unchanged polygon area (tolerance 1 ppm)"
            )
            geometry = repaired
    if (
        geometry.is_empty
        or not geometry.is_valid
        or geometry.geom_type not in {"Polygon", "MultiPolygon"}
    ):
        raise ValueError("Invalid census polygon; source requires review")
    return geometry


def tract_dimension(tracts: list[dict], places: list[dict]) -> pd.DataFrame:
    cities = [(f["properties"]["BASENAME"], valid_polygon(f)) for f in places]
    city_union = shapely.union_all([polygon for _, polygon in cities])
    rows = []
    for feature in tracts:
        props = feature["properties"]
        polygon = valid_polygon(feature)
        # Ignore pure edge touching, but do not use centroid/majority shortcuts.
        names = [
            name for name, city in cities if polygon.intersection(city).area > 1e-12
        ]
        if polygon.difference(city_union).area > 1e-12:
            names.append(UNINCORPORATED)
        population = props.get("POP100")
        if population is not None and (
            not np.isfinite(float(population)) or float(population) < 0
        ):
            population = None
        rows.append(
            {
                "geoid": str(props["GEOID"]),
                "tract_name": props["NAME"],
                "population": population,
                "boundary_vintage": VINTAGE,
                "population_vintage": VINTAGE,
                "population_source": TRACT_URL,
                "cities_json": json.dumps(sorted(set(names))),
                "geometry_json": json.dumps(mapping(polygon)),
            }
        )
    dim = pd.DataFrame(rows)
    if dim.empty:
        raise ValueError("No census tracts returned; cannot build a tract map")
    if dim.geoid.duplicated().any():
        raise ValueError("Duplicate tract GEOIDs")
    if not dim.geoid.str.fullmatch(r"32003\d{6}").all():
        raise ValueError("Unexpected tract GEOID outside Clark County")
    return dim


def assign_points(observations: pd.DataFrame, tracts: list[dict]) -> pd.DataFrame:
    """Vectorized spatial index; edge/overlap ties choose the lowest GEOID once."""
    ordered = sorted(tracts, key=lambda f: f["properties"]["GEOID"])
    polygons = [valid_polygon(f) for f in ordered]
    tree = STRtree(polygons)
    lon = pd.to_numeric(observations.longitude, errors="coerce").to_numpy(
        dtype=float, na_value=np.nan
    )
    lat = pd.to_numeric(observations.latitude, errors="coerce").to_numpy(
        dtype=float, na_value=np.nan
    )
    valid = np.isfinite(lon) & np.isfinite(lat) & (abs(lon) <= 180) & (abs(lat) <= 90)
    result = pd.DataFrame(
        {
            "geoid": pd.Series([None] * len(lon), dtype="object"),
            "assignment": np.where(valid, "outside_tracts", "invalid_coordinates"),
            "boundary_tie": False,
        }
    )
    indices = np.flatnonzero(valid)
    # Batch to bound peak memory on multi-year call tables.
    for start in range(0, len(indices), 100_000):
        batch = indices[start : start + 100_000]
        hits = tree.query(
            shapely.points(lon[batch], lat[batch]), predicate="intersects"
        )
        if hits.shape[1] == 0:
            continue
        matched = pd.DataFrame({"row": batch[hits[0]], "polygon": hits[1]})
        minimum = matched.groupby("row").polygon.min()
        result.loc[minimum.index, "geoid"] = [
            ordered[i]["properties"]["GEOID"] for i in minimum
        ]
        result.loc[minimum.index, "assignment"] = "assigned"
        ties = matched.groupby("row").size()
        result.loc[ties.index, "boundary_tie"] = ties.gt(1)
    return result


def summarize_topic(
    topic: str,
    observations: pd.DataFrame,
    tracts: list[dict],
    dim: pd.DataFrame,
    covered_cities: set[str],
    rate_allowed: bool,
):
    assigned = assign_points(observations, tracts)
    work = observations.reset_index(drop=True).copy()
    work["geoid"] = assigned.geoid
    work["category"] = work.category.fillna("Unknown").astype(str)
    counts = (
        work.dropna(subset=["geoid"])
        .groupby(["geoid", "category"], as_index=False)
        .agg(record_count=("category", "size"))
    )
    counts.insert(0, "topic", topic)
    dates = pd.to_datetime(work.observed_date, errors="coerce")
    period = "Snapshot inventory"
    if dates.notna().any():
        period = f"{dates.min():%Y-%m-%d} to {dates.max():%Y-%m-%d}"
    coverage_rows = []
    for row in dim.to_dict("records"):
        members = set(json.loads(row["cities_json"]))
        present = members & covered_cities
        state = "unavailable"
        if not observations.empty and present:
            state = "available" if members <= covered_cities else "partial"
        coverage_rows.append(
            {
                "topic": topic,
                "geoid": row["geoid"],
                "coverage": state,
                "period": period,
                "rate_allowed": rate_allowed,
            }
        )
    audit = {
        "topic": topic,
        "source_records": len(work),
        "assigned_records": int(assigned.assignment.eq("assigned").sum()),
        "invalid_coordinates": int(assigned.assignment.eq("invalid_coordinates").sum()),
        "outside_tracts": int(assigned.assignment.eq("outside_tracts").sum()),
        "boundary_ties": int(assigned.boundary_tie.sum()),
    }
    log.info("Tract assignment %s: %s", topic, audit)
    return counts, pd.DataFrame(coverage_rows), audit


def fetch_geography() -> tuple[list[dict], pd.DataFrame]:
    tracts = fetch_geojson(
        TRACT_URL, "STATE='32' AND COUNTY='003'", "OBJECTID,GEOID,NAME,POP100"
    )
    # Full geometry for intersecting tracts: never clip their population footprint.
    extent = box(*METRO_EXTENT)
    tracts = [f for f in tracts if valid_polygon(f).intersects(extent)]
    places = fetch_geojson(PLACE_URL, "STATE='32'", "OBJECTID,BASENAME")
    if not {"Las Vegas", "North Las Vegas", "Henderson"} <= {
        f["properties"]["BASENAME"] for f in places
    }:
        raise ValueError("Census place response missing a required city")
    return tracts, tract_dimension(tracts, places)
