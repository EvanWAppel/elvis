import argparse
import os
import snowflake.connector
import polars as pl
from dotenv import load_dotenv

import __init__ as variables

load_dotenv()

SNOWFLAKE_CONFIG = {
    "account":   os.environ["SNOWFLAKE_ACCOUNT"],
    "user":      os.environ["SNOWFLAKE_USER"],
    "password":  os.environ["SNOWFLAKE_PASSWORD"],
    "warehouse": os.environ["SNOWFLAKE_WAREHOUSE"],
    "database":  os.environ["SNOWFLAKE_DATABASE"],
    "role":      os.environ["SNOWFLAKE_ROLE"],
    "schema":    os.environ["SNOWFLAKE_SCHEMA"],
}

TABLE_NAME = "SNHD_INSPECTIONS"

CREATE_TABLE_SQL = f"""
CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
    SERIAL_NUMBER       VARCHAR,
    PERMIT_NUMBER       VARCHAR,
    RESTAURANT_NAME     VARCHAR,
    LOCATION_NAME       VARCHAR,
    CATEGORY_NAME       VARCHAR,
    ADDRESS             VARCHAR,
    CITY                VARCHAR,
    STATE               VARCHAR,
    ZIP                 VARCHAR,
    CURRENT_DEMERITS    VARCHAR,
    CURRENT_GRADE       VARCHAR,
    DATE_CURRENT        VARCHAR,
    INSPECTION_DATE     VARCHAR,
    INSPECTION_TIME     VARCHAR,
    EMPLOYEE_ID         VARCHAR,
    INSPECTION_TYPE     VARCHAR,
    INSPECTION_DEMERITS VARCHAR,
    INSPECTION_GRADE    VARCHAR,
    PERMIT_STATUS       VARCHAR,
    INSPECTION_RESULT   VARCHAR,
    VIOLATIONS          VARCHAR,
    RECORD_UPDATED      VARCHAR,
    LOCATION_1          VARCHAR,
    OBJECTID            VARCHAR
)
"""

FIRE_TABLE_NAME = "FIRE_PREVENTION_INSPECTIONS"

FIRE_CREATE_TABLE_SQL = f"""
CREATE TABLE IF NOT EXISTS {FIRE_TABLE_NAME} (
    I_MOYR                       VARCHAR,
    I_FY                         VARCHAR,
    NAME                         VARCHAR,
    IMPS                         VARCHAR,
    NO_OF_UNITS                  VARCHAR,
    LAST_INSPECTED               VARCHAR,
    NO_VIOLATIONS_WRITTEN        VARCHAR,
    NO_DWELLINGS_INSP_MTD        VARCHAR,
    NO_DWELLINGS_INSP_CUMULATIVE VARCHAR,
    NO_DWELLINGS_VIOL_WRITTEN    VARCHAR,
    PCNT_DWELLINGS_VIOLATIONS    VARCHAR,
    LOCATION                     VARCHAR,
    ADDRESS                      VARCHAR,
    CITY                         VARCHAR,
    STATE                        VARCHAR,
    ZIP                          VARCHAR,
    OBJECTID                     VARCHAR
)
"""

ART_TABLE_NAME = "ART_WORK_POINTS"

ART_CREATE_TABLE_SQL = f"""
CREATE TABLE IF NOT EXISTS {ART_TABLE_NAME} (
    NAME        VARCHAR,
    DESCRIPTION VARCHAR,
    PIC_URL     VARCHAR,
    THUMB_URL   VARCHAR,
    ICON_COLOR  VARCHAR,
    LAT_1       VARCHAR,
    LONG        VARCHAR,
    OBJECTID    VARCHAR
)
"""


def table_exists(cur, table_name: str) -> bool:
    cur.execute(f"SHOW TABLES LIKE '{table_name}'")
    return len(cur.fetchall()) > 0


def load_table(cur, table_name: str, create_sql: str, csv_path: str, read_kwargs: dict, overwrite: bool):
    if table_exists(cur, table_name):
        if not overwrite:
            print(f"  {table_name} already exists — skipping. Use --overwrite to replace it.")
            return
        print(f"  {table_name} already exists — overwriting.")
        cur.execute(f"DROP TABLE {table_name}")
    else:
        print(f"  {table_name} not found — creating.")

    print(f"  Reading {csv_path}...")
    df = pl.read_csv(csv_path, infer_schema_length=None, **read_kwargs)
    df.columns = [c.upper() for c in df.columns]
    print(f"  Loaded {len(df)} rows, {len(df.columns)} columns")

    cur.execute(create_sql)
    print(f"  Table {table_name} created.")

    rows = [tuple(str(v) if v is not None else None for v in row) for row in df.iter_rows()]
    batch_size = 10000
    for i in range(0, len(rows), batch_size):
        batch = rows[i:i + batch_size]
        placeholders = ",".join(["%s"] * len(df.columns))
        cur.executemany(f"INSERT INTO {table_name} VALUES ({placeholders})", batch)
        print(f"  Inserted rows {i} - {min(i + batch_size, len(rows))}")


def main(overwrite: bool):
    print("Connecting to Snowflake...")
    conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)
    cur = conn.cursor()
    cur.execute("CREATE SCHEMA IF NOT EXISTS RAW")
    cur.execute("USE SCHEMA RAW")

    tables = [
        (TABLE_NAME,      CREATE_TABLE_SQL,      variables.SNHD_INSPECTIONS,            {"quote_char": None}),
        (FIRE_TABLE_NAME, FIRE_CREATE_TABLE_SQL,  variables.FIRE_PREVENTION_INSPECTIONS, {}),
        (ART_TABLE_NAME,  ART_CREATE_TABLE_SQL,   variables.ART_WORK_POINTS,             {}),
    ]

    for table_name, create_sql, csv_path, read_kwargs in tables:
        print(f"\n--- {table_name} ---")
        load_table(cur, table_name, create_sql, csv_path, read_kwargs, overwrite)
        conn.commit()

    cur.close()
    conn.close()
    print("\nDone.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Load CSV files into Snowflake RAW schema.")
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Drop and reload tables that already exist in Snowflake.",
    )
    args = parser.parse_args()
    main(overwrite=args.overwrite)
