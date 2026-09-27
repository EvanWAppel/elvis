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
    for table, frame in [
        ("census_tracts", dim),
        ("tract_counts", pd.concat([counts, more_counts])),
        ("tract_coverage", pd.concat([coverage, more_coverage])),
        ("tract_assignment_audit", pd.DataFrame([audit, more_audit])),
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
    assert len(con.sql(sql).fetchall()) == 2
