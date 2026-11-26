"""Guard dbt SQL against syntax the Railway image's DuckDB rejects.

The Dockerfile installs ``duckdb>=1.5`` unpinned from requirements.txt, so the
deploy picks up new majors before the local lockfile does. DuckDB 2.0 removed the
arrow lambda (``x -> expr``); every Railway build from 2026-10-24 failed on it in
``stg_art_work_points``. Use ``lambda x: expr`` instead (supported since 1.3).
Reads SQL source files only; no warehouse or public data.
"""

import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SQL_FILES = sorted(
    p for d in ("models", "macros", "tests") for p in (ROOT / d).rglob("*.sql")
)

# `x -> ...` or `(x, i) -> ...`; excludes the JSON `->>` operator.
ARROW_LAMBDA = re.compile(r"(\b\w+|\([\w\s,]+\))\s*->(?!>)")


def _code(sql: str) -> str:
    """Strip line comments so prose like 'From -> To' doesn't trip the check."""
    return "\n".join(line.split("--", 1)[0] for line in sql.splitlines())


def test_sql_files_found():
    assert SQL_FILES


@pytest.mark.parametrize("path", SQL_FILES, ids=lambda p: str(p.relative_to(ROOT)))
def test_no_arrow_lambdas(path):
    assert not ARROW_LAMBDA.search(_code(path.read_text())), (
        f"{path.relative_to(ROOT)} uses the arrow lambda DuckDB 2.0 removed; "
        "write `lambda x: expr` instead"
    )
