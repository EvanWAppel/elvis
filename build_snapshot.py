"""Build the static data snapshot that powers the public Streamlit demo.

The deployed portfolio app (Streamlit Community Cloud) has no Snowflake
connection, so instead of querying the ``MART_ART_WORK_POINTS`` table live it
reads a committed snapshot file. This script rebuilds that snapshot straight
from the public City of Las Vegas open-data source, reproducing exactly the
transform the dbt models perform:

    stg_art_work_points  -> split the pipe-delimited DESCRIPTION field into
                            artist / medium / location_detail / address / ward,
                            cast LAT_1 and LONG to float.
    mart_art_work_points -> select the map-ready columns, ordered by
                            ward, artwork_name.

NOTE ON WARD: the source DESCRIPTION has a *variable* number of pipe parts
(4, 5, or 6), so a fixed split_part(..., 5) — as the current dbt model does —
misses the ward whenever there are fewer than 5 parts, and trips over typo
variants ("Ward 5 (CLV Collection", "Colllection"). Here we instead pull the
"Ward N" token out of the whole description by regex and normalize it to
"Ward N". Five UNLV/county pieces legitimately have no ward and stay blank.
The dbt model (stg_art_work_points.sql) mirrors this logic with FLATTEN +
REGEXP_SUBSTR so the Snowflake mart and this snapshot stay in parity.

Intentionally dependency-free (standard library only) so it runs in any
environment without touching the project's dependencies. Run with:

    python build_snapshot.py

Output: app_data/mart_art_work_points.csv (uppercase columns, matching the
Snowflake mart the original app queried).
"""

import csv
import json
import re
import urllib.request
from pathlib import Path

# Matches the "Ward N" token wherever it appears in the DESCRIPTION field.
WARD_RE = re.compile(r"Ward\s+(\d+)", re.IGNORECASE)

SOURCE_URL = (
    "https://services1.arcgis.com/F1v0ufATbBQScMtY/arcgis/rest/services/"
    "Art_Work_Points_Open_Data/FeatureServer/0/query"
    "?where=1%3D1&outFields=*&f=geojson"
)

OUTPUT_PATH = Path(__file__).parent / "app_data" / "mart_art_work_points.csv"

# Column order matches mart_art_work_points; names are upper-cased to match
# what Snowflake returned to the original get_active_session() query.
MART_COLUMNS = [
    "OBJECTID",
    "ARTWORK_NAME",
    "ARTIST",
    "MEDIUM",
    "LOCATION_DETAIL",
    "ADDRESS",
    "WARD",
    "LATITUDE",
    "LONGITUDE",
    "PIC_URL",
    "THUMB_URL",
]


def parse_description(description: str) -> dict:
    """Split the pipe-delimited DESCRIPTION into its component fields.

    The field is ``artist | medium | <location parts...> | Ward N`` but the
    number of location parts varies and the ward is sometimes absent, so the
    ward is located by regex rather than by position. Everything between the
    medium and the ward becomes location_detail (first part) + address (rest).
    """
    parts = [p.strip() for p in (description or "").split("|") if p.strip()]

    ward = ""
    ward_idx = None
    for i, part in enumerate(parts):
        match = WARD_RE.search(part)
        if match:
            ward = f"Ward {match.group(1)}"
            ward_idx = i

    middle = parts[2 : (ward_idx if ward_idx is not None else len(parts))]
    return {
        "ARTIST": parts[0] if parts else "",
        "MEDIUM": parts[1] if len(parts) > 1 else "",
        "LOCATION_DETAIL": middle[0] if middle else "",
        "ADDRESS": " ".join(middle[1:]) if len(middle) > 1 else "",
        "WARD": ward,
    }


def stage(props: dict) -> dict:
    """Reproduce stg_art_work_points for a single raw record."""
    fields = parse_description(props.get("DESCRIPTION") or "")
    return {
        "OBJECTID": props.get("ObjectId"),
        "ARTWORK_NAME": props.get("NAME"),
        "ARTIST": fields["ARTIST"],
        "MEDIUM": fields["MEDIUM"],
        "LOCATION_DETAIL": fields["LOCATION_DETAIL"],
        "ADDRESS": fields["ADDRESS"],
        "WARD": fields["WARD"],
        "LATITUDE": float(props["LAT_1"]) if props.get("LAT_1") is not None else None,
        "LONGITUDE": float(props["LONG"]) if props.get("LONG") is not None else None,
        "PIC_URL": props.get("PIC_URL"),
        "THUMB_URL": props.get("THUMB_URL"),
    }


def build() -> list[dict]:
    print(f"Fetching source data from {SOURCE_URL}")
    with urllib.request.urlopen(SOURCE_URL) as resp:
        geojson = json.load(resp)

    features = geojson["features"]
    print(f"  {len(features)} records fetched")

    rows = [stage(f["properties"]) for f in features]

    # mart_art_work_points: order by ward, artwork_name
    rows.sort(key=lambda r: (r["WARD"] or "", r["ARTWORK_NAME"] or ""))
    return rows


def write_csv(rows: list[dict]) -> None:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=MART_COLUMNS)
        writer.writeheader()
        for row in rows:
            writer.writerow({col: row.get(col) for col in MART_COLUMNS})
    print(f"  Wrote {len(rows)} rows to {OUTPUT_PATH}")


if __name__ == "__main__":
    write_csv(build())
    print("Done.")
