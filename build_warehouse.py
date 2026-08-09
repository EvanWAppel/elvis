"""Build the Elvis DuckDB warehouse from Las Vegas open data.

Fetches the raw source datasets from the City of Las Vegas ArcGIS org and
loads them into the ``raw`` schema of ``vegas.duckdb``, which dbt then
transforms into staging + mart models. This replaces the old build_snapshot.py
CSV approach: the Streamlit app now reads the dbt-built marts from
``vegas.duckdb`` directly.

Datasets (all on the City of Las Vegas ArcGIS org F1v0ufATbBQScMtY):
    art_work_points               ~63 rows   (geocoded public art)
    fire_prevention_inspections   ~3.9k rows (City of Las Vegas only)
    snhd_inspections              ~347k rows (Clark County-wide; paginated)
    Restaurant_Inspection_Violation_Codes -> seeds/violation_codes.csv

Usage:
    uv run python build_warehouse.py                  # full load
    uv run python build_warehouse.py --sample 5000    # fast iteration
"""

import argparse
import json
import logging
import urllib.parse
import urllib.request
from pathlib import Path

import duckdb
import pandas as pd

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s"
)
log = logging.getLogger("build_warehouse")

ORG = "https://services1.arcgis.com/F1v0ufATbBQScMtY/arcgis/rest/services"
DB_PATH = Path(__file__).parent / "vegas.duckdb"
SEED_PATH = Path(__file__).parent / "seeds" / "violation_codes.csv"

PAGE_SIZE = 2000

# Columns to normalize to ISO date strings even if the source types them as
# text (ArcGIS date-typed fields are auto-detected from layer metadata).
DATE_COLUMNS = {
    "Fire_Prevention_Inspections": ["I_MOYR", "LAST_INSPECTED"],
    "Restaurant_Inspections_Open_Data": [
        "Inspection_Date",
        "Date_Current",
        "Record_Updated",
    ],
    "Art_Work_Points_Open_Data": [],
}

VIOLATION_CODES_SERVICE = "Restaurant_Inspection_Violation_Codes"
SEED_COLUMNS = [
    "Violation_ID",
    "Violation_Code",
    "Violation_Demerits",
    "Violation_Description",
    "ObjectId",
]


def _get_json(url: str) -> dict:
    with urllib.request.urlopen(url, timeout=180) as resp:
        return json.load(resp)


def _layer_metadata(service: str) -> dict:
    return _get_json(f"{ORG}/{service}/FeatureServer/0?f=json")


def fetch_layer(service: str, sample: int | None = None) -> pd.DataFrame:
    """Fetch all attribute rows of an ArcGIS FeatureServer layer, paginated."""
    meta = _layer_metadata(service)
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
        params = urllib.parse.urlencode(
            {
                "where": "1=1",
                "outFields": "*",
                "returnGeometry": "false",
                "f": "json",
                "resultOffset": offset,
                "resultRecordCount": page,
            }
        )
        data = _get_json(f"{ORG}/{service}/FeatureServer/0/query?{params}")
        feats = data.get("features", [])
        if not feats:
            break
        rows.extend(f["attributes"] for f in feats)
        offset += len(feats)
        log.info("  %s: %d rows fetched", service, len(rows))
        if sample and len(rows) >= sample:
            rows = rows[:sample]
            break
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


def load_raw(con: duckdb.DuckDBPyConnection, table: str, df: pd.DataFrame) -> None:
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")
    con.register("_df", df)
    con.execute(f"CREATE OR REPLACE TABLE raw.{table} AS SELECT * FROM _df")
    con.unregister("_df")
    log.info("Loaded raw.%s: %d rows, %d cols", table, len(df), len(df.columns))


def write_violation_codes_seed() -> None:
    """Source the SNHD violation-codes reference into the dbt seed."""
    SEED_PATH.parent.mkdir(parents=True, exist_ok=True)
    try:
        df = fetch_layer(VIOLATION_CODES_SERVICE)
        df = df[[c for c in SEED_COLUMNS if c in df.columns]]
        df.to_csv(SEED_PATH, index=False)
        log.info("Wrote violation-codes seed: %d rows", len(df))
    except Exception:
        log.warning(
            "Could not source violation codes from %s; writing header-only seed. "
            "mart_top_violations will have null descriptions.",
            VIOLATION_CODES_SERVICE,
            exc_info=True,
        )
        pd.DataFrame(columns=SEED_COLUMNS).to_csv(SEED_PATH, index=False)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--sample",
        type=int,
        default=None,
        help="Limit the restaurant fetch to N rows for fast iteration.",
    )
    args = ap.parse_args()

    con = duckdb.connect(str(DB_PATH))
    try:
        log.info("Fetching art_work_points ...")
        load_raw(con, "art_work_points", fetch_layer("Art_Work_Points_Open_Data"))

        log.info("Fetching fire_prevention_inspections ...")
        load_raw(
            con,
            "fire_prevention_inspections",
            fetch_layer("Fire_Prevention_Inspections"),
        )

        log.info("Fetching snhd_inspections (large; paginating) ...")
        load_raw(
            con,
            "snhd_inspections",
            fetch_layer("Restaurant_Inspections_Open_Data", sample=args.sample),
        )
    finally:
        con.close()

    write_violation_codes_seed()
    log.info("Done. Warehouse at %s", DB_PATH)


if __name__ == "__main__":
    main()
