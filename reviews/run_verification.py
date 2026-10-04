"""Run the column-doc verification queries against the local warehouse (read-only).

For the human reviewer: prints each ``-- CHECK:`` claim followed by its result.
Usage: ``uv run python reviews/run_verification.py [path/to/queries.sql]``
"""

from __future__ import annotations

import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SQL = Path(__file__).with_name("column-docs-verification.sql")


def main() -> None:
    sql_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SQL
    con = duckdb.connect(str(ROOT / "vegas.duckdb"), read_only=True)
    for block in sql_path.read_text().split(";"):
        lines = block.strip().splitlines()
        checks = [ln for ln in lines if ln.startswith("-- CHECK:")]
        query = "\n".join(ln for ln in lines if not ln.lstrip().startswith("--"))
        if not query.strip():
            continue
        print("\n" + (checks[-1] if checks else "-- (query)"))
        con.sql(query).show(max_rows=40, max_width=200)


if __name__ == "__main__":
    main()
