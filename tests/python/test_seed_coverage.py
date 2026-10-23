"""Guard the hermetic CI seed fixtures (P1/P2 seed expansion).

Every committed seed CSV must be (a) registered in ``dbt_project.yml`` with
explicit ``+column_types`` so CI types match the warehouse that
``build_warehouse.py`` loads, and (b) gated by CI's ``dbt build --select``.
Reads repo config files only; no warehouse or public data.
"""

import csv
from pathlib import Path

import pytest
import yaml

ROOT = Path(__file__).resolve().parents[2]
SEEDS = ROOT / "seeds"

# Lineages added by the seed expansion: seed table -> staging model CI must select.
EXPANDED = {
    "crime_calls": "stg_crime_calls",
    "building_permits": "stg_building_permits",
    "snhd_inspections": "stg_snhd_inspections",
    "snhd_inspection_types": "stg_snhd_inspections",
    "snhd_establishments": "stg_snhd_establishments",
    "snhd_violations": "stg_violation_codes",
}


@pytest.fixture(scope="module")
def seed_config():
    project = yaml.safe_load((ROOT / "dbt_project.yml").read_text())
    return project["seeds"]["elvis"]


@pytest.fixture(scope="module")
def ci_select():
    ci = yaml.safe_load((ROOT / ".github" / "workflows" / "ci.yml").read_text())
    for step in ci["jobs"]["dbt"]["steps"]:
        run = step.get("run", "")
        if "dbt build" in run and "--select" in run:
            return run.split("--select", 1)[1].split()
    raise AssertionError("ci.yml has no `dbt build --select` step")


@pytest.mark.parametrize("seed", sorted(EXPANDED))
def test_expanded_seed_exists_with_rows(seed):
    path = SEEDS / f"{seed}.csv"
    assert path.exists(), f"missing synthetic seed {path.name}"
    with path.open(newline="") as f:
        rows = list(csv.DictReader(f))
    assert len(rows) >= 3, f"{seed}: seed needs several synthetic rows"


@pytest.mark.parametrize("seed", sorted(EXPANDED))
def test_expanded_seed_types_every_column(seed, seed_config):
    header = next(csv.reader((SEEDS / f"{seed}.csv").open(newline="")))
    types = seed_config.get(seed, {}).get("+column_types", {})
    untyped = [c for c in header if c not in types]
    assert not untyped, f"{seed}: columns without +column_types: {untyped}"


@pytest.mark.parametrize("seed", sorted(EXPANDED))
def test_expanded_lineage_selected_in_ci(seed, ci_select):
    model = EXPANDED[seed]
    assert f"{model}+" in ci_select, f"CI --select does not gate {model}+"


def test_every_seed_is_registered(seed_config):
    for path in SEEDS.glob("*.csv"):
        if path.stem == "tract_assignment_audit":
            continue  # pre-existing fixture, typed by inference
        assert path.stem in seed_config, f"{path.name} not registered in dbt_project.yml"
