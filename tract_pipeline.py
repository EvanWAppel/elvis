"""Build tract inputs from the complete raw snapshot, without logging records."""

import logging
from typing import NotRequired, TypedDict

import pandas as pd

from geography import UNINCORPORATED, fetch_geography, summarize_topic

log = logging.getLogger(__name__)


# Static, source-specific projections. Counts mean source records, not inferred
# distinct incidents. Municipal inventories retain their published scope.
class TopicSpec(TypedDict):
    sql: str
    rate: bool
    cities: NotRequired[set[str]]
    city_column: NotRequired[bool]


TOPICS: dict[str, TopicSpec] = {
    "calls": {
        "sql": """select try_cast("Latitude" as double) latitude,
                  try_cast("Longitude" as double) longitude,
                  "IncidentTypeDescription" category, "IncidentDate" observed_date
                  from raw.crime_calls""",
        "cities": {"Las Vegas", UNINCORPORATED},
        "rate": True,
    },
    "parks": {
        "sql": """select latitude, longitude, jurisdiction category,
                  null::varchar observed_date from raw.parks""",
        "city_column": True,
        "rate": False,
    },
    "rentals": {
        "sql": """select latitude, longitude, jurisdiction category,
                  null::varchar observed_date from raw.short_term_rentals""",
        "city_column": True,
        "rate": True,
    },
    "henderson_crime": {
        "sql": """select latitude, longitude, category,
                  observed_date from raw.henderson_crime""",
        "cities": {"Henderson"},
        # Count-only: 2024 vs 2025 report volumes are inconsistent, so a per-1,000
        # rate over the ragged period would mislead until annual completeness is
        # human-verified. A distinct measure from LVMPD calls; never combined.
        "rate": False,
    },
    "public_art": {
        "sql": """select try_cast(LAT_1 as double) latitude,
                  try_cast("LONG" as double) longitude, 'Las Vegas' category,
                  null::varchar observed_date from raw.art_work_points
                  union all select latitude, longitude, jurisdiction category,
                  null::varchar observed_date from raw.henderson_art""",
        "city_column": True,
        "rate": False,
    },
}


def build_tract_tables(con, geography=None):
    # Inject geography for hermetic tests; production downloads only at build time.
    from build_warehouse import load_raw

    tracts, dim = geography if geography is not None else fetch_geography()
    counts, coverage, audits = [], [], []
    for topic, spec in TOPICS.items():
        records = con.execute(spec["sql"]).df()
        cities = spec.get("cities", set())
        if spec.get("city_column"):
            cities = set(
                records.category.dropna().replace({"Clark County": UNINCORPORATED})
            )
        topic_counts, topic_coverage, audit = summarize_topic(
            topic,
            records,
            tracts,
            dim,
            cities,
            spec["rate"],
        )
        counts.append(topic_counts)
        coverage.append(topic_coverage)
        audits.append(audit)
    # Write a coherent set atomically. An upstream/spatial failure leaves the
    # previous set intact, never a mixture of vintages.
    con.execute("BEGIN TRANSACTION")
    try:
        load_raw(con, "census_tracts", dim)
        load_raw(con, "tract_counts", pd.concat(counts, ignore_index=True))
        load_raw(con, "tract_coverage", pd.concat(coverage, ignore_index=True))
        load_raw(con, "tract_assignment_audit", pd.DataFrame(audits))
        con.execute("COMMIT")
    except Exception:
        con.execute("ROLLBACK")
        raise
    log.info("Tract inputs ready for dbt (full snapshot, no map sampling)")
