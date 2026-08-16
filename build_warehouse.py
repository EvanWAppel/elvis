"""Build the Elvis DuckDB warehouse from Las Vegas / Clark County open data.

Several upstream sources feed the ``raw`` schema of ``vegas.duckdb``, which dbt
then transforms into staging + mart models:

    ArcGIS — City of Las Vegas org F1v0ufATbBQScMtY
        art_work_points               ~63 rows   (geocoded public art)
        fire_prevention_inspections   ~3.9k rows
        building_permits              ~217k rows  (archived, with valuation)
        business_licenses             ~212k rows  (non-spatial registry)
        short_term_rentals            ~225 rows   (points, reprojected to WGS84)
        parks                         ~89 rows    (polygon centroids)

    ArcGIS — LVMPD org jjSk6t82vIntwDbs
        crime_calls                   ~693k rows  (calls-for-service, recent years)

    SNHD nightly developer bundle (restaurants.zip)
        snhd_inspections / snhd_establishments / snhd_violations / snhd_inspection_types

    Time-series feeds
        marriage_licenses   Clark County marriage licenses, one CSV per year
        lake_mead           USBR RISE daily reservoir elevation
        weather             NOAA NCEI GHCN-Daily, Las Vegas airport station
        lvcva_indicators    LVCVA monthly tourism / gaming / airport indicators (XLSX)

The SNHD open-data ArcGIS layer nulls out restaurant names and addresses, so the
restaurant pages source the SNHD developer bundle instead, which carries the full
establishment detail keyed on ``permit_number``.

Usage:
    uv run python build_warehouse.py
"""

import datetime
import io
import json
import logging
import os
import re
import socket
import ssl
import tempfile
import urllib.error
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


# Some upstreams (notably aqs.epa.gov) advertise an AAAA record but have broken
# IPv6, so a default connect hangs in SYN_SENT until timeout. Prefer IPv4 for all
# fetches, falling back to whatever's available if a host is IPv4-less.
_orig_getaddrinfo = socket.getaddrinfo


def _ipv4_first(*args, **kwargs):
    results = _orig_getaddrinfo(*args, **kwargs)
    return [r for r in results if r[0] == socket.AF_INET] or results


socket.getaddrinfo = _ipv4_first

ORG = "https://services1.arcgis.com/F1v0ufATbBQScMtY/arcgis/rest/services"
# LVMPD publishes calls-for-service in its own ArcGIS Online org, not the City's.
LVMPD_ORG = "https://services.arcgis.com/jjSk6t82vIntwDbs/arcgis/rest/services"
# Other Las Vegas metro jurisdictions (for metro-wide parks / rentals / permits).
HENDERSON = "https://maps.cityofhenderson.com/arcgis/rest/services"
# Clark County's ArcGIS has a mis-configured TLS cert, so its fetches skip verify.
CLARK = "https://gisgate.co.clark.nv.us/arcgis/rest/services"
# Only the two most recent LVMPD yearly layers are loaded — enough for month/hour
# /weekday patterns and a recent trend without baking millions of rows into the image.
CRIME_YEARS = [2025, 2026]
DB_PATH = Path(__file__).parent / "vegas.duckdb"

SNHD_ZIP_URL = (
    "https://www.southernnevadahealthdistrict.org/restaurants/download/restaurants.zip"
)

# City of Las Vegas Capital Improvement Program lines (MasterWorks), on the same
# org as the rest of the CLV data. Polyline geometry — active + planned street /
# utility construction projects. Keyless.
CLV_CIP_LAYER = f"{ORG}/MASTERWORKS_CIP_LINES_prd_view/FeatureServer/0"

# Nevada 511 (NDOT) live traffic events — the state-route roadwork/closure feed.
# Needs a free developer key; when NVROADS_API_KEY is unset the source is skipped,
# so the default build stays secret-free. Register at nvroads.com/developers/doc.
NVROADS_EVENTS_URL = "https://www.nvroads.com/api/v2/get/event"
NVROADS_API_KEY = os.environ.get("NVROADS_API_KEY")
# Only construction-relevant event types (drop bare accidents/incidents).
NVROADS_EVENT_TYPES = {"roadwork", "closures"}
# The 511 feed uses these placeholder tokens for missing text; treat them as null.
NVROADS_PLACEHOLDERS = {"", "unknown", "no data", "none", "n/a"}
# Las Vegas Valley bounding box — the same clip used by the crime map sample.
METRO_BBOX = {"min_lat": 35.8, "max_lat": 36.4, "min_lon": -115.5, "max_lon": -114.9}

# Some hosts 403 a bare urllib agent; send a browser-ish UA where needed.
USER_AGENT = {"User-Agent": "Mozilla/5.0 (compatible; elvis-data/1.0)"}

# Clark County marriage licenses — one record-level CSV per year (rehosted from
# the County Clerk). Schema is stable across years.
MARRIAGE_URL = "https://weddings.vegas/wp-content/uploads/2025/05/{year}-marriage.csv"
MARRIAGE_YEARS = range(2007, 2026)  # 2007–2025

# Lake Mead daily elevation, USBR RISE catalog item 6123 (CSV download form).
LAKE_MEAD_URL = (
    "https://data.usbr.gov/rise/api/result/download"
    "?itemId=6123&type=csv&after=1935-01-01&before={before}"
)

# NOAA NCEI GHCN-Daily, Harry Reid International Airport station (no key needed).
WEATHER_URL = (
    "https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/"
    "access/USW00023169.csv"
)

# LVCVA "Executive Summary of Southern Nevada Tourism Indicators" — the report
# page links one wide-format monthly XLSX per year (visitor volume, occupancy,
# ADR, airport passengers, and gaming revenue by area).
LVCVA_REPORT_URL = (
    "https://www.lvcva.com/research/reports/post/"
    "lvcva-executive-summary-of-southern-nevada-tourism-indicators/"
)

# EPA AQS pre-generated daily files: keyless, static, nationwide. We download one
# file per pollutant-year and filter to Clark County (FIPS 32/003), which spans
# the Las Vegas metro. No API key needed, and no rate limits.
AQS_FILE_URL = "https://aqs.epa.gov/aqsweb/airdata/daily_{param}_{year}.zip"
AQS_STATE, AQS_COUNTY = "32", "003"
AQS_PARAMS = {"88101": "PM2.5", "44201": "Ozone"}  # param code -> label
AQS_START_YEAR = 2015
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
# Generic ArcGIS fetch (FeatureServer or MapServer, any org, optional TLS skip) #
# --------------------------------------------------------------------------- #
def _ssl_ctx(verify: bool) -> ssl.SSLContext | None:
    if verify:
        return None
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def fetch_features(
    base_url: str,
    where: str = "1=1",
    out_fields: str = "*",
    geometry: bool = True,
    out_sr: int = 4326,
    ssl_verify: bool = True,
) -> list[tuple[dict, dict | None]]:
    """Paginate any ArcGIS layer URL, returning (attributes, geometry) per feature.

    Works for FeatureServer and MapServer layers across orgs; ``ssl_verify=False``
    tolerates the Clark County server's broken certificate.
    """
    ctx = _ssl_ctx(ssl_verify)

    def get(url: str) -> dict:
        with urllib.request.urlopen(url, timeout=180, context=ctx) as r:
            return json.load(r)

    meta = get(f"{base_url}?f=json")
    page = min(meta.get("maxRecordCount") or PAGE_SIZE, PAGE_SIZE)
    out: list[tuple[dict, dict | None]] = []
    offset = 0
    while True:
        params = urllib.parse.urlencode(
            {
                "where": where,
                "outFields": out_fields,
                "returnGeometry": "true" if geometry else "false",
                "outSR": out_sr,
                "f": "json",
                "resultOffset": offset,
                "resultRecordCount": page,
            }
        )
        feats = get(f"{base_url}/query?{params}").get("features", [])
        if not feats:
            break
        out.extend((f.get("attributes", {}), f.get("geometry")) for f in feats)
        offset += len(feats)
        if len(feats) < page:
            break
    log.info("  %s: %d features", base_url.rsplit("/services/", 1)[-1], len(out))
    return out


def _centroid(geom: dict | None) -> tuple[float | None, float | None]:
    """(lon, lat) for a point, or the vertex-average of a polygon's outer ring."""
    if not geom:
        return (None, None)
    if "x" in geom:
        return (geom.get("x"), geom.get("y"))
    rings = geom.get("rings")
    if rings:
        ext = rings[0]
        pts = ext[:-1] if len(ext) > 1 and ext[0] == ext[-1] else ext
        if pts:
            return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))
    return (None, None)


def _line_path(geom: dict | None) -> list[list[float]]:
    """[[lon, lat], ...] for an ArcGIS polyline, flattening multi-part paths.

    Returns an empty list for missing/degenerate geometry so callers can filter.
    """
    paths = (geom or {}).get("paths")
    if not paths:
        return []
    return [[pt[0], pt[1]] for part in paths for pt in part if len(pt) >= 2]


def _path_centroid(path: list[list[float]]) -> tuple[float | None, float | None]:
    """(lon, lat) vertex-average of a polyline path, for map anchoring/tooltips."""
    if not path:
        return (None, None)
    return (sum(p[0] for p in path) / len(path), sum(p[1] for p in path) / len(path))


def _point_in_ring(lon: float, lat: float, ring: list) -> bool:
    """Ray-casting test: is (lon, lat) inside the polygon exterior ``ring``?"""
    inside = False
    j = len(ring) - 1
    for i in range(len(ring)):
        xi, yi = ring[i][0], ring[i][1]
        xj, yj = ring[j][0], ring[j][1]
        if (yi > lat) != (yj > lat) and lon < (xj - xi) * (lat - yi) / (yj - yi) + xi:
            inside = not inside
        j = i
    return inside


def _epoch_to_date(ms) -> str | None:
    """ArcGIS epoch-millisecond timestamp -> ISO date string (None if missing)."""
    if ms is None or (isinstance(ms, float) and pd.isna(ms)):
        return None
    dt = pd.to_datetime(ms, unit="ms", errors="coerce")
    # AQS/ArcGIS use a 1900 sentinel for "no date"; treat pre-1990 as null.
    if pd.isna(dt) or dt.year < 1990:
        return None
    return dt.strftime("%Y-%m-%d")


def _iso_date(value) -> str | None:
    """Best-effort parse of any date string / epoch to an ISO ``YYYY-MM-DD``.

    The CLV CIP layer stores dates as free-form strings (``MM/DD/YYYY``) and the
    Nevada 511 feed uses ISO 8601; both flow through here so staging can plain
    ``try_cast`` the result. Missing or sentinel (pre-1990) dates become null.
    """
    if value is None or value == "" or (isinstance(value, float) and pd.isna(value)):
        return None
    dt = pd.to_datetime(value, errors="coerce", utc=False)
    if pd.isna(dt) or dt.year < 1990:
        return None
    return dt.strftime("%Y-%m-%d")


def _nv_clean(value) -> str | None:
    """Nevada 511 placeholder tokens ('Unknown', 'No Data', …) -> None."""
    if value is None:
        return None
    text = str(value).strip()
    return None if text.lower() in NVROADS_PLACEHOLDERS else text


def _decode_polyline(encoded: str) -> list[list[float]]:
    """Decode a Google-encoded polyline (precision 5) to ``[[lon, lat], ...]``.

    Nevada 511 returns event geometry as an encoded polyline; deck.gl's PathLayer
    wants lon/lat pairs, so we decode here rather than add a dependency.
    """
    if not encoded:
        return []
    coords: list[list[float]] = []
    lat = lon = index = 0
    length = len(encoded)
    while index < length:
        for is_lon in (False, True):
            shift = result = 0
            while True:
                byte = ord(encoded[index]) - 63
                index += 1
                result |= (byte & 0x1F) << shift
                shift += 5
                if byte < 0x20:
                    break
            delta = ~(result >> 1) if result & 1 else (result >> 1)
            if is_lon:
                lon += delta
            else:
                lat += delta
        coords.append([lon / 1e5, lat / 1e5])
    return coords


# --------------------------------------------------------------------------- #
# Metro-wide datasets (parks / short-term rentals / Henderson permits+licenses) #
# --------------------------------------------------------------------------- #
def _clv_water_points() -> list[tuple[float, float]]:
    """CLV water-feature locations: pools, water bodies, and water-play areas."""
    layers = [
        f"{ORG}/Pools_View/FeatureServer/0",
        f"{ORG}/Water_Body_View/FeatureServer/82",
        f"{ORG}/Water_Play_Poly_View/FeatureServer/73",
        f"{ORG}/Water_Play_Pts_View/FeatureServer/72",
    ]
    pts = []
    for url in layers:
        for _attrs, geom in fetch_features(url, out_fields="OBJECTID"):
            lon, lat = _centroid(geom)
            if lon is not None:
                pts.append((lon, lat))
    return pts


def fetch_parks_metro() -> pd.DataFrame:
    """Parks across the metro's jurisdictions, flagged with a water feature.

    Henderson carries native swimming/water-play flags. For the City of Las Vegas
    we spatial-join the dedicated water-feature layers into each park polygon.
    Clark County (unincorporated) and North Las Vegas publish no water attribute.
    """
    log.info("Collecting CLV water features ...")
    water = _clv_water_points()

    def clv_has_water(geom: dict | None) -> bool:
        rings = (geom or {}).get("rings")
        if not rings:
            return False
        ring = rings[0]
        return any(_point_in_ring(lon, lat, ring) for lon, lat in water)

    rows: list[dict] = []

    log.info("Fetching City of Las Vegas parks ...")
    for attrs, geom in fetch_features(
        f"{ORG}/CLV_Parks/FeatureServer/113", out_fields="NAME,ADDRESS,ACRES,WARD"
    ):
        lon, lat = _centroid(geom)
        rows.append(
            {
                "jurisdiction": "Las Vegas",
                "park_name": attrs.get("NAME"),
                "address": attrs.get("ADDRESS"),
                "acres": attrs.get("ACRES"),
                "has_water": clv_has_water(geom),
                "latitude": lat,
                "longitude": lon,
            }
        )

    log.info("Fetching Henderson parks ...")
    for attrs, geom in fetch_features(
        f"{HENDERSON}/public/OpenDataRecreation/MapServer/6",
        out_fields="NAME,ADDRESS,ACRES,SWIMMING,WATERPLAY",
    ):
        lon, lat = _centroid(geom)
        wet = "yes" in (
            f"{attrs.get('SWIMMING')}{attrs.get('WATERPLAY')}".lower()
        )
        rows.append(
            {
                "jurisdiction": "Henderson",
                "park_name": attrs.get("NAME"),
                "address": attrs.get("ADDRESS"),
                "acres": attrs.get("ACRES"),
                "has_water": wet,
                "latitude": lat,
                "longitude": lon,
            }
        )

    for label, url in [
        ("Clark County", f"{CLARK}/OpenData/Recreation/MapServer/6"),
        ("North Las Vegas", f"{CLARK}/OpenData/Recreation/MapServer/10"),
    ]:
        log.info("Fetching %s parks ...", label)
        for attrs, geom in fetch_features(
            url, out_fields="PKNAME,ADDRESS", ssl_verify=False
        ):
            lon, lat = _centroid(geom)
            rows.append(
                {
                    "jurisdiction": label,
                    "park_name": attrs.get("PKNAME"),
                    "address": attrs.get("ADDRESS"),
                    "acres": None,
                    "has_water": None,  # no water attribute published
                    "latitude": lat,
                    "longitude": lon,
                }
            )

    return pd.DataFrame(rows)


def fetch_str_metro() -> pd.DataFrame:
    """Short-term rental registrations across Las Vegas, North Las Vegas, Henderson."""
    rows: list[dict] = []

    log.info("Fetching Las Vegas short-term rentals ...")
    for attrs, geom in fetch_features(
        f"{CLARK}/OpenData/ShortTermRentalData/MapServer/0",
        out_fields="BUS_NAME,LICSTATUS,BUS_TYPE,ISSDTTM,BUS_ADDRES",
        ssl_verify=False,
    ):
        lon, lat = _centroid(geom)
        rows.append(
            {
                "jurisdiction": "Las Vegas",
                "business_name": attrs.get("BUS_NAME"),
                "status": attrs.get("LICSTATUS"),
                "category": attrs.get("BUS_TYPE"),
                "address": attrs.get("BUS_ADDRES"),
                "issued_date": _epoch_to_date(attrs.get("ISSDTTM")),
                "latitude": lat,
                "longitude": lon,
            }
        )

    log.info("Fetching North Las Vegas short-term rentals ...")
    for attrs, geom in fetch_features(
        f"{CLARK}/OpenData/ShortTermRentalData/MapServer/1",
        out_fields="ADDRESS,OWNER,APPROVAL_D",
        ssl_verify=False,
    ):
        lon, lat = _centroid(geom)
        rows.append(
            {
                "jurisdiction": "North Las Vegas",
                "business_name": attrs.get("OWNER"),
                "status": "Approved",
                "category": None,
                "address": attrs.get("ADDRESS"),
                "issued_date": _epoch_to_date(attrs.get("APPROVAL_D")),
                "latitude": lat,
                "longitude": lon,
            }
        )

    log.info("Fetching Henderson short-term rentals ...")
    for attrs, geom in fetch_features(
        f"{HENDERSON}/public/OpenDataDevelopment/MapServer/14",
        out_fields="BUSINESS_NAME,STATUS,REGISTERED_ADDRESS,LICENSE_ISSUE_DATE,MAX_OCCUPANCY",
    ):
        lon, lat = _centroid(geom)
        occ = attrs.get("MAX_OCCUPANCY")
        rows.append(
            {
                "jurisdiction": "Henderson",
                "business_name": attrs.get("BUSINESS_NAME"),
                "status": attrs.get("STATUS"),
                "category": f"Max occupancy {int(occ)}" if occ else None,
                "address": attrs.get("REGISTERED_ADDRESS"),
                "issued_date": _epoch_to_date(attrs.get("LICENSE_ISSUE_DATE")),
                "latitude": lat,
                "longitude": lon,
            }
        )

    return pd.DataFrame(rows)


def fetch_henderson_permits() -> pd.DataFrame:
    """City of Henderson building permits (counts by type/date; no valuation)."""
    log.info("Fetching Henderson building permits ...")
    rows = []
    for attrs, _geom in fetch_features(
        f"{HENDERSON}/public/OpenDevPermits/MapServer/1",
        out_fields="CASETYPE,STATUS,ISSUEDATE,DESCRIPTION,MAIN_ADDRESS_LINE1",
        geometry=False,
    ):
        rows.append(
            {
                "case_type": attrs.get("CASETYPE"),
                "status": attrs.get("STATUS"),
                "issue_date": _epoch_to_date(attrs.get("ISSUEDATE")),
                "description": attrs.get("DESCRIPTION"),
                "address": attrs.get("MAIN_ADDRESS_LINE1"),
            }
        )
    return pd.DataFrame(rows)


def fetch_henderson_licenses() -> pd.DataFrame:
    """City of Henderson business licenses."""
    log.info("Fetching Henderson business licenses ...")
    rows = []
    for attrs, _geom in fetch_features(
        f"{HENDERSON}/public/BusLicense/MapServer/4",
        out_fields="DESCRIPTION,CASETYPE,STATUS,ISSUEDATE,MAIN_ADDRESS_LINE1",
        geometry=False,
    ):
        rows.append(
            {
                "business_name": attrs.get("DESCRIPTION"),
                "license_type": attrs.get("CASETYPE"),
                "status": attrs.get("STATUS"),
                "issue_date": _epoch_to_date(attrs.get("ISSUEDATE")),
                "address": attrs.get("MAIN_ADDRESS_LINE1"),
            }
        )
    return pd.DataFrame(rows)


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
# Time-series sources (marriage / weather / Lake Mead / LVCVA)                 #
# --------------------------------------------------------------------------- #
def _urlopen(url: str, headers: dict | None = None, timeout: int = 300):
    return urllib.request.urlopen(
        urllib.request.Request(url, headers=headers or {}), timeout=timeout
    )


def fetch_marriage() -> pd.DataFrame:
    """Clark County marriage licenses, concatenated across years (subset of cols)."""
    keep = {
        "LicenseIssueDate",
        "MailingState",
        "MailingCountry",
        "Party1Gender",
        "Party2Gender",
    }
    frames = []
    for year in MARRIAGE_YEARS:
        log.info("Fetching marriage licenses %d ...", year)
        try:
            resp = _urlopen(MARRIAGE_URL.format(year=year), USER_AGENT)
        except urllib.error.HTTPError as exc:
            if exc.code == 404:  # a year not (yet) posted at this path
                log.warning("marriage: %d not available (404), skipping", year)
                continue
            raise
        with resp as r:
            frames.append(
                pd.read_csv(
                    io.BytesIO(r.read()),
                    usecols=lambda c: c in keep,
                    dtype=str,
                    encoding="cp1252",
                    encoding_errors="replace",
                )
            )
    return pd.concat(frames, ignore_index=True)


def fetch_lake_mead() -> pd.DataFrame:
    """Daily Lake Mead elevation from the RISE CSV (skip the comment/preamble block)."""
    before = datetime.datetime.now(tz=datetime.UTC).date().isoformat()
    with _urlopen(LAKE_MEAD_URL.format(before=before)) as r:
        text = r.read().decode("utf-8")
    lines = text.splitlines()
    start = next(i for i, ln in enumerate(lines) if "#SERIES DATA#" in ln)
    df = pd.read_csv(io.StringIO("\n".join(lines[start + 1 :])))
    return df.rename(
        columns={"Datetime (UTC)": "datetime_utc", "Result": "elevation_ft"}
    )[["datetime_utc", "elevation_ft"]]


def fetch_weather() -> pd.DataFrame:
    """GHCN-Daily observations for the Las Vegas airport station."""
    keep = {"STATION", "DATE", "TMAX", "TMIN", "TAVG", "PRCP"}
    with _urlopen(WEATHER_URL) as r:
        return pd.read_csv(io.BytesIO(r.read()), usecols=lambda c: c in keep)


def _parse_lvcva(data: bytes) -> pd.DataFrame:
    """Melt one LVCVA summary workbook's Las Vegas sheet to (metric, month, value).

    The sheet is wide: a month-date header row, then one indicator per row with
    values in the odd columns and revision flags in the even columns. We take the
    first date-header row (absolute values) and stop at the first blank label,
    which excludes the "Change from Previous Year" section further down.

    Date cells are matched as ``datetime.datetime`` (which ``pd.Timestamp``
    subclasses): pandas types a month column as datetime64 only when every value
    below the header is empty, so populated months arrive as plain datetimes.
    """
    xl = pd.ExcelFile(io.BytesIO(data))
    sheet = next(s for s in xl.sheet_names if s.lower().startswith("las vegas"))
    raw = pd.read_excel(io.BytesIO(data), sheet_name=sheet, header=None)

    def is_date(v) -> bool:
        # pd.Timestamp subclasses datetime; pd.NaT also passes isinstance, so
        # exclude missing values explicitly.
        return isinstance(v, datetime.datetime) and not pd.isna(v)

    header_idx = next(
        i for i in range(len(raw)) if sum(is_date(v) for v in raw.iloc[i]) >= 4
    )
    month_cols = [
        (c, raw.iat[header_idx, c])
        for c in range(raw.shape[1])
        if is_date(raw.iat[header_idx, c])
    ]

    records = []
    for i in range(header_idx + 1, len(raw)):
        label = raw.iat[i, 0]
        if pd.isna(label) or not str(label).strip():
            break  # end of the absolute-values block
        metric = re.sub(r"\s+", " ", str(label)).strip()
        for col, month in month_cols:
            val = raw.iat[i, col]
            if pd.notna(val) and not isinstance(val, str):
                records.append((metric, month.date().isoformat(), float(val)))
    return pd.DataFrame(records, columns=["metric", "month", "value"])


def fetch_lvcva() -> pd.DataFrame:
    """Scrape the per-year XLSX links off the report page and melt each one."""
    with _urlopen(LVCVA_REPORT_URL, USER_AGENT, timeout=120) as r:
        html = r.read().decode("utf-8", "replace")
    links = sorted(
        set(re.findall(r'https://assets\.simpleviewcms\.com/[^"\']+?\.xlsx', html))
    )
    log.info("LVCVA: %d yearly workbooks found", len(links))
    frames = []
    for url in links:
        name = url.rsplit("/", 1)[-1]
        try:
            with _urlopen(url, USER_AGENT, timeout=120) as r:
                frames.append(_parse_lvcva(r.read()))
        except Exception as exc:  # noqa: BLE001 — skip an unparseable year, keep the rest
            log.warning("LVCVA: skipping %s (%s)", name, exc)
    combined = pd.concat(frames, ignore_index=True)
    # Overlapping years (revised vs. year-end) can repeat a month; keep the last.
    return combined.drop_duplicates(subset=["metric", "month"], keep="last")


def fetch_air_quality() -> pd.DataFrame:
    """EPA AQS daily PM2.5 / ozone for Clark County from the keyless bulk files.

    Downloads one pre-generated nationwide file per pollutant-year and filters to
    Clark County (FIPS 32/003), which spans the Las Vegas metro. No API key.
    """
    this_year = datetime.datetime.now(tz=datetime.UTC).year
    rename = {
        "Date Local": "date_local",
        "Arithmetic Mean": "arithmetic_mean",
        "AQI": "aqi",
        "Local Site Name": "local_site_name",
    }
    frames = []
    for param, label in AQS_PARAMS.items():
        for year in range(AQS_START_YEAR, this_year + 1):
            log.info("Fetching air quality %s %d ...", label, year)
            try:
                with _urlopen(AQS_FILE_URL.format(param=param, year=year)) as r:
                    data = r.read()
            except urllib.error.HTTPError as exc:
                if exc.code == 404:  # current-year file not published yet
                    log.warning("air quality: %s %d not available (404)", label, year)
                    continue
                raise
            zf = zipfile.ZipFile(io.BytesIO(data))
            df = pd.read_csv(
                zf.open(zf.namelist()[0]),
                usecols=["State Code", "County Code", *rename],
                dtype={"State Code": str, "County Code": str},
            )
            df = df[(df["State Code"] == AQS_STATE) & (df["County Code"] == AQS_COUNTY)]
            df = df.rename(columns=rename)[list(rename.values())]
            df["parameter"] = label
            frames.append(df)
    if not frames:
        raise RuntimeError("air quality: no AQS bulk files could be downloaded")
    return pd.concat(frames, ignore_index=True)[
        ["parameter", "date_local", "arithmetic_mean", "aqi", "local_site_name"]
    ]


# --------------------------------------------------------------------------- #
# --------------------------------------------------------------------------- #
# Road construction — CLV Capital Improvement lines + Nevada 511 roadwork       #
# --------------------------------------------------------------------------- #
# Harmonized schema both sources fill; keeps the mart/view source-agnostic.
ROAD_CONSTRUCTION_COLUMNS = [
    "source",
    "project_name",
    "description",
    "status",
    "category",
    "road_name",
    "extent",
    "start_date",
    "end_date",
    "contractor",
    "is_full_closure",
    "url",
    "path_json",
    "latitude",
    "longitude",
]


def fetch_clv_cip() -> pd.DataFrame:
    """City of Las Vegas Capital Improvement Program construction lines.

    Streamed from the City's MasterWorks system: street, sewer, and safety
    projects with schedule, status/phase, and polyline extents. Keyless.
    """
    rows: list[dict] = []
    for attrs, geom in fetch_features(
        CLV_CIP_LAYER,
        out_fields=(
            "NAME,DESCRIPTION,STATUS,PHASE,CATEGORY,ProjType,StreetName,"
            "FromStreet,ToStreet,LOCATION,CONTRACTOR,WEBSITE,WARD,"
            "STARTDATE,ENDDATE,ConstStart,ConstEnd"
        ),
    ):
        path = _line_path(geom)
        lon, lat = _path_centroid(path)
        from_st, to_st = attrs.get("FromStreet"), attrs.get("ToStreet")
        extent = f"{from_st} → {to_st}" if from_st and to_st else attrs.get("LOCATION")
        rows.append(
            {
                "source": "City of Las Vegas (CIP)",
                "project_name": attrs.get("NAME"),
                "description": attrs.get("DESCRIPTION"),
                # Prefer the fine-grained PHASE (Design/Bidding/Construction/…),
                # falling back to the coarser STATUS when phase is blank.
                "status": attrs.get("PHASE") or attrs.get("STATUS"),
                "category": attrs.get("CATEGORY") or attrs.get("ProjType"),
                "road_name": attrs.get("StreetName"),
                "extent": extent,
                # Construction dates when populated, else the overall project span.
                "start_date": _iso_date(attrs.get("ConstStart") or attrs.get("STARTDATE")),
                "end_date": _iso_date(attrs.get("ConstEnd") or attrs.get("ENDDATE")),
                "contractor": attrs.get("CONTRACTOR"),
                "is_full_closure": None,
                "url": attrs.get("WEBSITE"),
                "path_json": json.dumps(path),
                "latitude": lat,
                "longitude": lon,
            }
        )
    return pd.DataFrame(rows, columns=ROAD_CONSTRUCTION_COLUMNS)


def fetch_nvroads_roadwork() -> pd.DataFrame:
    """Nevada 511 (NDOT) roadwork + closure events, clipped to the LV Valley.

    Covers state-maintained routes (I-15, US-95, I-215, etc.). Requires a free
    developer key in ``NVROADS_API_KEY``; returns empty (and logs) when unset so
    the default build needs no secret.
    """
    if not NVROADS_API_KEY:
        log.warning(
            "NVROADS_API_KEY not set — skipping Nevada 511 roadwork "
            "(state-route construction). Register at nvroads.com/developers/doc."
        )
        return pd.DataFrame(columns=ROAD_CONSTRUCTION_COLUMNS)

    params = urllib.parse.urlencode({"key": NVROADS_API_KEY, "format": "json"})
    req = urllib.request.Request(f"{NVROADS_EVENTS_URL}?{params}", headers=USER_AGENT)
    with urllib.request.urlopen(req, timeout=180) as resp:
        payload = json.load(resp)
    events = payload if isinstance(payload, list) else payload.get("data", [])

    rows: list[dict] = []
    for ev in events:
        if str(ev.get("EventType", "")).lower() not in NVROADS_EVENT_TYPES:
            continue
        lat, lon = ev.get("Latitude"), ev.get("Longitude")
        if lat is None or lon is None:
            continue
        if not (METRO_BBOX["min_lat"] <= lat <= METRO_BBOX["max_lat"]):
            continue
        if not (METRO_BBOX["min_lon"] <= lon <= METRO_BBOX["max_lon"]):
            continue
        path = _decode_polyline(ev.get("EncodedPolyline") or "")
        if not path:
            path = [[lon, lat]]
        subtype = _nv_clean(ev.get("EventSubType"))
        roadway = _nv_clean(ev.get("RoadwayName"))
        direction = _nv_clean(ev.get("DirectionOfTravel"))
        lanes = _nv_clean(ev.get("LanesAffected"))
        rows.append(
            {
                "source": "NDOT 511 (state routes)",
                "project_name": subtype or ev.get("EventType"),
                "description": _nv_clean(ev.get("Description")),
                "status": ev.get("EventType"),
                "category": subtype,
                "road_name": roadway,
                "extent": " · ".join(filter(None, [direction, lanes])) or None,
                "start_date": _iso_date(ev.get("StartDate")),
                "end_date": _iso_date(ev.get("PlannedEndDate")),
                "contractor": _nv_clean(ev.get("Organization")),
                "is_full_closure": bool(ev.get("IsFullClosure")),
                "url": None,
                "path_json": json.dumps(path),
                "latitude": lat,
                "longitude": lon,
            }
        )
    log.info("  nvroads: %d roadwork/closure events in the valley", len(rows))
    return pd.DataFrame(rows, columns=ROAD_CONSTRUCTION_COLUMNS)


def fetch_road_construction() -> pd.DataFrame:
    """Metro road construction: CLV capital projects + NDOT 511 state-route work."""
    log.info("Fetching City of Las Vegas CIP construction lines ...")
    clv = fetch_clv_cip()
    log.info("Fetching Nevada 511 roadwork events ...")
    nvroads = fetch_nvroads_roadwork()
    return pd.concat([clv, nvroads], ignore_index=True)


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

        log.info("Fetching short_term_rentals (metro-wide, ArcGIS) ...")
        load_raw(con, "short_term_rentals", fetch_str_metro())

        log.info("Fetching Henderson building permits (ArcGIS) ...")
        load_raw(con, "henderson_permits", fetch_henderson_permits())

        log.info("Fetching Henderson business licenses (ArcGIS) ...")
        load_raw(con, "henderson_licenses", fetch_henderson_licenses())

        log.info("Fetching parks (metro-wide, ArcGIS) ...")
        load_raw(con, "parks", fetch_parks_metro())

        log.info("Fetching road construction (CLV CIP + Nevada 511) ...")
        load_raw(con, "road_construction", fetch_road_construction())

        log.info("Fetching marriage licenses (Clark County) ...")
        load_raw(con, "marriage_licenses", fetch_marriage())

        log.info("Fetching Lake Mead elevation (USBR RISE) ...")
        load_raw(con, "lake_mead", fetch_lake_mead())

        log.info("Fetching weather (NOAA NCEI GHCN-Daily) ...")
        load_raw(con, "weather", fetch_weather())

        log.info("Fetching LVCVA tourism / gaming / airport indicators ...")
        load_raw(con, "lvcva_indicators", fetch_lvcva())

        log.info("Fetching air quality (EPA AQS) ...")
        load_raw(con, "air_quality", fetch_air_quality())

        log.info("Loading SNHD restaurant bundle ...")
        load_snhd(con)
    finally:
        con.close()

    log.info("Done. Warehouse at %s", DB_PATH)


if __name__ == "__main__":
    main()
