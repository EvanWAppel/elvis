"""Build the Elvis DuckDB warehouse from Las Vegas / Clark County open data.

Two upstream sources feed the ``raw`` schema of ``vegas.duckdb``, which dbt then
transforms into staging + mart models:

    ArcGIS (City of Las Vegas org F1v0ufATbBQScMtY)
        art_work_points               ~63 rows   (geocoded public art)
        fire_prevention_inspections   ~3.9k rows (City of Las Vegas only)

    SNHD nightly developer bundle (restaurants.zip)
        snhd_inspections        ~118k rows  restaurant inspection facts (2020+)
        snhd_establishments     ~36k rows   permit -> name / address / geo / grade
        snhd_violations         ~900 rows   violation code -> description / demerits
        snhd_inspection_types   7 rows       inspection_type_id -> label

The SNHD open-data ArcGIS layer nulls out restaurant names and addresses, so the
restaurant pages source the SNHD developer bundle instead, which carries the full
establishment detail keyed on ``permit_number``.

Usage:
    uv run python build_warehouse.py
"""

import json
import logging
import tempfile
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

import duckdb
import pandas as pd

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s"
)
log = logging.getLogger("build_warehouse")

ORG = "https://services1.arcgis.com/F1v0ufATbBQScMtY/arcgis/rest/services"
# LVMPD publishes calls-for-service in its own ArcGIS Online org, not the City's.
LVMPD_ORG = "https://services.arcgis.com/jjSk6t82vIntwDbs/arcgis/rest/services"
# Only the two most recent LVMPD yearly layers are loaded — enough for month/hour
# /weekday patterns and a recent trend without baking millions of rows into the image.
CRIME_YEARS = [2025, 2026]
DB_PATH = Path(__file__).parent / "vegas.duckdb"

SNHD_ZIP_URL = (
    "https://www.southernnevadahealthdistrict.org/restaurants/download/restaurants.zip"
)
# The SNHD exports are semicolon-delimited, unquoted, and Windows-1252 encoded.
SNHD_ENCODING = "cp1252"

PAGE_SIZE = 2000

# Columns to normalize to ISO date strings even if the source types them as
# text (ArcGIS date-typed fields are auto-detected from layer metadata).
DATE_COLUMNS = {
    "Fire_Prevention_Inspections": ["I_MOYR", "LAST_INSPECTED"],
    "Art_Work_Points_Open_Data": [],
}


# --------------------------------------------------------------------------- #
# ArcGIS (public art + fire)                                                   #
# --------------------------------------------------------------------------- #
def _get_json(url: str) -> dict:
    with urllib.request.urlopen(url, timeout=180) as resp:
        return json.load(resp)


def fetch_layer(
    service: str,
    org: str = ORG,
    layer: int = 0,
    geometry: bool = False,
    centroid: bool = False,
    out_sr: int = 4326,
) -> pd.DataFrame:
    """Fetch all attribute rows of an ArcGIS FeatureServer layer, paginated.

    Args:
        service: FeatureServer service name.
        org: ArcGIS org REST base (defaults to the City of Las Vegas org).
        layer: layer id within the service (some services put data on 1/113, not 0).
        geometry: also pull point geometry into ``longitude``/``latitude`` columns.
        centroid: for polygon layers, pull the centroid into ``longitude``/``latitude``.
        out_sr: spatial reference to reproject geometry into (4326 = WGS84 lat/long).
    """
    base = f"{org}/{service}/FeatureServer/{layer}"
    meta = _get_json(f"{base}?f=json")
    page = min(meta.get("maxRecordCount") or PAGE_SIZE, PAGE_SIZE)
    esri_date_fields = {
        f["name"]
        for f in meta.get("fields", [])
        if f.get("type") == "esriFieldTypeDate"
    }
    date_cols = set(DATE_COLUMNS.get(service, [])) | esri_date_fields

    rows: list[dict] = []
    offset = 0
    while True:
        query = {
            "where": "1=1",
            "outFields": "*",
            "returnGeometry": "true" if geometry else "false",
            "f": "json",
            "resultOffset": offset,
            "resultRecordCount": page,
        }
        if centroid:
            query["returnCentroid"] = "true"
        if geometry or centroid:
            query["outSR"] = out_sr
        params = urllib.parse.urlencode(query)
        data = _get_json(f"{base}/query?{params}")
        feats = data.get("features", [])
        if not feats:
            break
        for feat in feats:
            attrs = dict(feat["attributes"])
            point = feat.get("geometry") if geometry else feat.get("centroid")
            if point:
                attrs["longitude"] = point.get("x")
                attrs["latitude"] = point.get("y")
            rows.append(attrs)
        offset += len(feats)
        log.info("  %s: %d rows fetched", service, len(rows))
        if len(feats) < page:
            break

    df = pd.DataFrame(rows)
    for col in df.columns:
        if col in date_cols:
            s = df[col]
            if pd.api.types.is_numeric_dtype(s):
                dt = pd.to_datetime(s, unit="ms", errors="coerce")
            else:
                dt = pd.to_datetime(s, errors="coerce")
            df[col] = dt.dt.strftime("%Y-%m-%d %H:%M:%S")
    return df


# --------------------------------------------------------------------------- #
# SNHD developer bundle                                                        #
# --------------------------------------------------------------------------- #
def _read_delimited(path: Path) -> pd.DataFrame:
    """Read a semicolon-delimited SNHD export into a string DataFrame.

    The files are unquoted, so a stray semicolon in a free-text field shifts the
    row's columns. Those rows (a handful of establishments) are logged and
    skipped rather than silently mis-parsed. The trailing empty column produced
    by the terminal ``;`` is dropped.
    """
    with path.open(encoding=SNHD_ENCODING) as f:
        header = f.readline().rstrip("\r\n").split(";")
        width = len(header)
        rows: list[list[str]] = []
        skipped = 0
        for line in f:
            line = line.rstrip("\r\n")
            if not line:
                continue
            parts = line.split(";")
            if len(parts) != width:
                skipped += 1
                continue
            rows.append(parts)

    df = pd.DataFrame(rows, columns=header)
    df = df.loc[:, [c for c in df.columns if c != ""]]
    df = df.replace("", pd.NA)
    if skipped:
        log.warning("%s: skipped %d malformed rows", path.name, skipped)
    return df


def _read_violations(path: Path) -> pd.DataFrame:
    """Read the violation reference, whose descriptions contain unescaped
    semicolons. Everything between the demerits field and the trailing empty
    field is the description.
    """
    rows: list[tuple[str, str, str]] = []
    with path.open(encoding=SNHD_ENCODING) as f:
        next(f)  # header
        for line in f:
            line = line.rstrip("\r\n")
            if not line:
                continue
            p = line.split(";")
            if len(p) < 5:
                continue
            description = ";".join(p[4:-1]) if len(p) > 5 else p[4]
            rows.append((p[1], p[3], description))  # code, demerits, description
    df = pd.DataFrame(
        rows, columns=["violation_code", "violation_demerits", "violation_description"]
    )
    return df.replace("", pd.NA)


def load_snhd(con: duckdb.DuckDBPyConnection) -> None:
    """Download the SNHD nightly bundle and load the tables the warehouse needs."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        zip_path = tmp_path / "restaurants.zip"
        log.info("Downloading SNHD bundle from %s ...", SNHD_ZIP_URL)
        urllib.request.urlretrieve(SNHD_ZIP_URL, zip_path)
        with zipfile.ZipFile(zip_path) as zf:
            zf.extractall(tmp_path)

        load_raw(
            con, "snhd_inspections", _read_delimited(tmp_path / "restaurant_inspections.csv")
        )
        load_raw(
            con,
            "snhd_establishments",
            _read_delimited(tmp_path / "restaurant_establishments.csv"),
        )
        load_raw(
            con,
            "snhd_inspection_types",
            _read_delimited(tmp_path / "restaurant_inspection_types.csv"),
        )
        load_raw(
            con, "snhd_violations", _read_violations(tmp_path / "restaurant_violations.csv")
        )


# --------------------------------------------------------------------------- #
def load_raw(con: duckdb.DuckDBPyConnection, table: str, df: pd.DataFrame) -> None:
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")
    con.register("_df", df)
    con.execute(f"CREATE OR REPLACE TABLE raw.{table} AS SELECT * FROM _df")
    con.unregister("_df")
    log.info("Loaded raw.%s: %d rows, %d cols", table, len(df), len(df.columns))


def fetch_crime() -> pd.DataFrame:
    """Concatenate LVMPD calls-for-service across the configured recent years."""
    frames = []
    for year in CRIME_YEARS:
        log.info("Fetching LVMPD calls-for-service %d ...", year)
        frames.append(
            fetch_layer(f"LVMPD_Calls_For_Service_{year}", org=LVMPD_ORG)
        )
    return pd.concat(frames, ignore_index=True)


def main() -> None:
    con = duckdb.connect(str(DB_PATH))
    try:
        log.info("Fetching art_work_points (ArcGIS) ...")
        load_raw(con, "art_work_points", fetch_layer("Art_Work_Points_Open_Data"))

        log.info("Fetching fire_prevention_inspections (ArcGIS) ...")
        load_raw(
            con,
            "fire_prevention_inspections",
            fetch_layer("Fire_Prevention_Inspections"),
        )

        log.info("Fetching crime / calls-for-service (LVMPD ArcGIS) ...")
        load_raw(con, "crime_calls", fetch_crime())

        log.info("Fetching building_permits (ArcGIS) ...")
        load_raw(con, "building_permits", fetch_layer("Archived_Building_Permits"))

        log.info("Fetching business_licenses (ArcGIS) ...")
        load_raw(con, "business_licenses", fetch_layer("Business_Licenses_OpenData"))

        log.info("Fetching short_term_rentals (ArcGIS) ...")
        load_raw(
            con,
            "short_term_rentals",
            fetch_layer("CLV_Short_Term_Rental", layer=1, geometry=True),
        )

        log.info("Fetching parks (ArcGIS) ...")
        load_raw(
            con,
            "parks",
            fetch_layer("CLV_Parks", layer=113, centroid=True),
        )

        log.info("Loading SNHD restaurant bundle ...")
        load_snhd(con)
    finally:
        con.close()

    log.info("Done. Warehouse at %s", DB_PATH)


if __name__ == "__main__":
    main()
