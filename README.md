# Elvis — Las Vegas Open-Data Explorer

Named after the most recognizable figure in Las Vegas, **Elvis** is an
interactive, multi-page [Streamlit](https://streamlit.io) app that explores free
public datasets about the Las Vegas Valley (Clark County metro: Las Vegas,
Henderson, North Las Vegas, and unincorporated Clark County).

It's a portfolio piece demonstrating end-to-end data engineering: multi-source
ingestion, a reproducible warehouse, dbt modeling, and an interactive front end.

## Stack

- **DuckDB** — single-file embedded warehouse (no server).
- **dbt-duckdb** — SQL modeling: `staging/` views normalize raw sources,
  `marts/` tables aggregate and denormalize for the app.
- **Streamlit** + **Altair** (charts) + **PyDeck** (maps).
- **uv** for Python; **Docker** → **Railway** for deploy.

## How it works

```
build_warehouse.py   # fetch every public source -> raw.* tables in vegas.duckdb
        │
     dbt build       # raw -> staging views -> marts tables
        │
streamlit_app.py     # views/*.py pages query marts via cached app_db.query()
```

The DuckDB warehouse is **baked at Docker build time** (`build_warehouse.py`
then `dbt build`), so the running container serves a ready warehouse. The
`vegas.duckdb` file is a build artifact and is **not** committed to git — it's
rebuilt from public sources on every deploy.

## Datasets

Public art, restaurant inspections (SNHD), fire inspections, LVMPD calls for
service, building permits, business licenses, short-term rentals, parks, road
construction (City of Las Vegas Capital Improvement Program + Nevada 511 / NDOT
state-route roadwork), marriage licenses, LVCVA tourism & gaming, Lake Mead
elevation, NOAA weather extremes, and EPA air quality — sourced from ArcGIS
FeatureServers, the Nevada 511 API, health-district bulk files, EPA AQS bulk
files, NOAA GHCN-Daily, and USBR RISE. All configuration lives near the top of
`build_warehouse.py`. Every source is public and keyless except the optional
Nevada 511 roadwork feed, which uses a free developer key from `NVROADS_API_KEY`;
when it's unset that one source is skipped and everything else still builds.

## Run locally

```bash
uv sync
uv run python build_warehouse.py            # fetch sources into vegas.duckdb
uv run dbt build --profiles-dir .           # build staging + marts
uv run streamlit run streamlit_app.py       # http://localhost:8501
```

## Deploy

Railway builds the `Dockerfile` (which runs `build_warehouse.py && dbt build`),
then serves Streamlit on the injected `$PORT`. No Procfile or `railway.toml`
needed — the Dockerfile is the source of truth.

## Goal

A portfolio project showcasing analytics/data-engineering skills. See the
`groening` (Portland) and `robbins` (Seattle) sibling folders for handoff primers
that port this same architecture to other cities.
