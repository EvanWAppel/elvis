# Elvis

Elvis is a personal analytics engineering portfolio project built around free, publicly available datasets from the Las Vegas Valley. It's named after the city's most recognizable cultural figure.

The project demonstrates a modern data stack — raw data lands as CSVs, gets loaded into Snowflake via Python, transformed through a dbt pipeline, and surfaced through Snowflake-native notebooks and Streamlit apps.

The goal is to build a portfolio that showcases analytics engineering skills: data modeling, SQL transformations, pipeline design, and data visualization — in support of a job search for Analytics Engineering roles.

## Architecture Overview

```
┌─────────────┐     ┌─────────────────────────┐     ┌─────────────────────┐
│  Data       │     │  Python                 │     │  Snowflake          │
│  Sources    │     │                         │     │                     │
│             │     │  main.py                │     │  RAW schema         │
│  /data      │────▶│  · LazyFrame readers    │────▶│  · SNHD_INSPECTIONS │
│  *.csv      │     │                         │     │  · FIRE_PREVENTION  │
│             │     │  load_to_snowflake.py   │     │  · ART_WORK_POINTS  │
│             │     │  · Existence checks     │     │  · EMPLOYEE_COMP    │
│             │     │  · Batch inserts        │     │                     │
└─────────────┘     └─────────────────────────┘     └──────────┬──────────┘
                                                               │
                                                               │ dbt
                                                               ▼
                                                    ┌─────────────────────┐
                                                    │  Snowflake          │
                                                    │  DBT_EAPPEL schema  │
                                                    │                     │
                                                    │  Staging (views)    │
                                                    │  · stg_*            │
                                                    │                     │
                                                    │  Marts (tables)     │
                                                    │  · mart_*           │
                                                    └──────────┬──────────┘
                                                               │
                                                    ┌──────────┴──────────┐
                                                    │                     │
                                          ┌─────────▼──────┐   ┌─────────▼──────┐
                                          │ Snowflake       │   │ Streamlit in   │
                                          │ Python Notebooks│   │ Snowflake      │
                                          └────────────────┘   └────────────────┘
```

**Each layer's role:**

- **`/data`** — Raw CSVs. The source of truth for reconstruction if Snowflake is lost.
- **`main.py`** — Defines a LazyFrame reader function per dataset. Documents how each file is read.
- **`load_to_snowflake.py`** — Loads CSVs into the Snowflake RAW schema. Skips tables that already exist unless `--overwrite` is passed.
- **dbt staging** — One model per source table. Renames columns, casts types, and parses fields. Materialized as views.
- **dbt marts** — Analytical models built on top of staging. Aggregated, joined, and ready to query. Materialized as tables.
- **Snowflake notebooks / Streamlit** — Consume mart tables directly for analysis and visualization.

## Data Sources

All source data is free and publicly available. Files live in `/data` and are loaded into the Snowflake `RAW` schema before any transformation.

| Table | Source | Description |
|---|---|---|
| `SNHD_INSPECTIONS` | Southern Nevada Health District | Restaurant health inspection records with grades, demerits, and violation codes |
| `FIRE_PREVENTION_INSPECTIONS` | City of Las Vegas Open Data | Fire prevention inspection records for multi-unit residential properties |
| `ART_WORK_POINTS` | City of Las Vegas Open Data | Public art collection with geospatial coordinates and metadata |
| `EMPLOYEE_COMPENSATION` | City of Las Vegas Open Data | City employee compensation by fiscal year — base salary, overtime, benefits, and org |

## dbt Models

### Staging

One model per source. Renames columns to snake_case, casts types, and parses dates. All staging models are materialized as views.

| Model | Description |
|---|---|
| `stg_snhd_inspections` | SNHD restaurant inspections — cleaned and typed |
| `stg_fire_prevention_inspections` | Fire prevention inspections — parsed with fiscal year derived from inspection period |
| `stg_art_work_points` | Public art locations — coordinates and metadata |
| `stg_employee_compensation` | City employee records — salary, overtime, benefits, org, and job title |

### Marts

Analytical models built on top of staging. Materialized as tables.

| Model | Description |
|---|---|
| `mart_restaurant_grades` | One row per restaurant — current grade, compliance rate, and total inspections |
| `mart_inspections_over_time` | Monthly inspection counts and compliance rates by inspection type |
| `mart_top_violations` | Violation code frequency by category and inspection type |
| `mart_fire_prevention_inspections` | One row per property — inspection history and violation totals |
| `mart_art_work_points` | Public art collection ready for mapping |
| `mart_org_compensation_summary` | Headcount, total payroll, and overtime burden by organization and fiscal year |
| `mart_compensation_trends` | City-wide payroll, headcount, and overtime trends by fiscal year |
| `mart_overtime_analysis` | Overtime burden broken down by organization and work group |
| `mart_job_pay_bands` | Min/avg/max base salary by job title, work group, and fiscal year |
| `mart_fire_dept_staffing_vs_inspections` | Fire department headcount and payroll joined to fire prevention inspection volume |
| `mart_city_payroll_vs_inspection_compliance` | City-wide payroll trends alongside SNHD inspection volume and compliance rates |

## Why dbt?

For a solo project with four source tables, dbt adds real ceremony — `profiles.yml`, `.yml` schema files alongside every model, a compiled `target/` directory. It would be straightforward to write these mart tables directly in Snowflake. The tradeoffs are worth understanding.

**What dbt actually provides here:**

- **Dependency ordering.** `dbt run` resolves that `mart_compensation_trends` depends on `stg_employee_compensation` and builds them in the right sequence. Without it, you manage and sequence `CREATE OR REPLACE` statements manually.
- **No hardcoded paths.** Models reference each other with `{{ ref('stg_employee_compensation') }}` instead of `PC_DBT_DB.DBT_EAPPEL.STG_EMPLOYEE_COMPENSATION`. If the database or schema changes, one update to `profiles.yml` propagates everywhere.
- **Testing built in.** The `not_null` and `unique` tests in `.yml` files run with `dbt test`. Without dbt you'd write those assertions yourself or skip them.
- **Free documentation.** `dbt docs generate && dbt docs serve` produces a browsable data catalog and lineage graph from the descriptions already written in `.yml` files.

**The honest reason:** dbt is the industry standard for this layer of the stack, and analytics engineering job postings ask for it by name. Using it here means the project looks and behaves like a production analytics codebase, and the skills transfer directly.

## Setup

### Prerequisites

- Python 3.11+
- A Snowflake account with a `PC_DBT_DB` database and `RAW` schema
- dbt Core with the Snowflake adapter (`dbt-snowflake`)
- Snowflake credentials configured in `~/.dbt/profiles.yml`

### Load raw data

```bash
python load_to_snowflake.py
```

Pass `--overwrite` to drop and reload tables that already exist.

### Run dbt

```bash
dbt run        # build all models
dbt test       # run schema tests
dbt docs serve # browse docs locally
```

To run a specific model and its dependencies:

```bash
dbt run --select +mart_compensation_trends
```
