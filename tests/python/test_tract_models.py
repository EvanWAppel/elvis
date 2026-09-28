from pathlib import Path

import duckdb
import pandas as pd
import pytest
from jinja2 import Environment

from geography import summarize_topic, tract_dimension


@pytest.fixture
def modeled_tracts(tract_features, city_features, observations):
    from build_warehouse import load_raw

    con = duckdb.connect(":memory:")
    dim = tract_dimension(tract_features, city_features)
    counts, coverage, audit = summarize_topic(
        "calls", observations, tract_features, dim, {"Las Vegas"}, True
    )
    # Also exercise covered zero with a valid denominator and zero/NULL population.
    more_counts, more_coverage, more_audit = summarize_topic(
        "rentals",
        observations.iloc[:1],
        tract_features,
        dim,
        {"Las Vegas", "Henderson"},
        True,
    )
    # Count-only Henderson topic: reports land in the Henderson-only tract (x=2..3);
    # rate_allowed=False must suppress any per-1,000 even where coverage is available.
    hend_obs = pd.DataFrame(
        {
            "latitude": [0.5, 0.5],
            "longitude": [2.5, 2.5],
            "category": ["BURGLARY", "THEFT"],
            "observed_date": ["2025-01-01", "2025-02-01"],
        }
    )
    crime_counts, crime_coverage, crime_audit = summarize_topic(
        "henderson_crime", hend_obs, tract_features, dim, {"Henderson"}, False
    )
    for table, frame in [
        ("census_tracts", dim),
        ("tract_counts", pd.concat([counts, more_counts, crime_counts])),
        ("tract_coverage", pd.concat([coverage, more_coverage, crime_coverage])),
        (
            "tract_assignment_audit",
            pd.DataFrame([audit, more_audit, crime_audit]),
        ),
    ]:
        load_raw(con, table, frame)
    env = Environment()
    env.globals.update(source=lambda _, table: f"raw.{table}", ref=lambda model: model)
    for name in [
        "stg_census_tracts",
        "stg_tract_counts",
        "stg_tract_coverage",
        "mart_tract_metrics",
        "mart_tract_assignment_audit",
    ]:
        folder = "staging" if name.startswith("stg_") else "marts"
        sql = env.from_string(Path(f"models/{folder}/{name}.sql").read_text()).render()
        con.execute(f"create table {name} as {sql}")
    yield con, env
    con.close()


def test_counts_rates_and_unknowns(modeled_tracts):
    con, _ = modeled_tracts
    rows = con.sql(
        "select geoid, record_count, rate_per_1000 from mart_tract_metrics where topic='calls' order by geoid"
    ).fetchall()
    assert rows == [
        ("32003000100", 3, 30.0),
        ("32003000200", None, None),
        ("32003000300", None, None),
    ]
    rows = con.sql(
        "select record_count, rate_per_1000 from mart_tract_metrics where topic='rentals' order by geoid"
    ).fetchall()
    assert rows == [(1, 10.0), (0, None), (0, None)]


def test_henderson_crime_is_count_only_and_separate_from_calls(modeled_tracts):
    con, _ = modeled_tracts
    rows = con.sql(
        "select geoid, record_count, rate_per_1000 from mart_tract_metrics "
        "where topic='henderson_crime' order by geoid"
    ).fetchall()
    # 100 (Las Vegas) unavailable → no count; 200 (crossing) partial → no count here;
    # 300 (Henderson-only) available → the two reports, and never a rate.
    assert rows == [
        ("32003000100", None, None),
        ("32003000200", None, None),
        ("32003000300", 2, None),
    ]
    assert all(rate is None for _, _, rate in rows)
    # The LVMPD calls topic is untouched — the two measures stay distinct.
    assert (
        con.sql(
            "select count(*) from mart_tract_metrics where topic='calls'"
        ).fetchone()[0]
        == 3
    )


def test_reconciliation_assertion_detects_dropped_counts(modeled_tracts):
    con, env = modeled_tracts
    sql = env.from_string(
        Path("tests/assert_tract_reconciliation.sql").read_text()
    ).render()
    assert con.sql(sql).fetchall() == []
    con.execute("delete from stg_tract_counts where topic='calls'")
    assert con.sql(sql).fetchall() == [("calls",)]


def test_rate_assertion_detects_invalid_denominator(modeled_tracts):
    con, env = modeled_tracts
    sql = env.from_string(Path("tests/assert_tract_rates.sql").read_text()).render()
    assert con.sql(sql).fetchall() == []
    con.execute("update mart_tract_metrics set rate_per_1000=100 where population=0")
    # calls, rentals, and henderson_crime each have a row on the pop-0 crossing
    # tract; forcing a rate there must trip the assertion for all three.
    assert len(con.sql(sql).fetchall()) == 3
