# Elvis — Product Requirements & Decisions

Elvis is a portfolio Streamlit app exploring free Las Vegas Valley open data
(Clark County metro). Public sources → DuckDB (`raw.*`) → dbt (staging → marts)
→ PyDeck/Altair pages. The warehouse is **baked at Docker build time**, so the
running container serves a point-in-time snapshot rebuilt from public sources on
every deploy.

## Guiding principle: snapshot, not live

This is a **snapshot of a point in time**, not a live operations dashboard.
Data freshness is bounded by the last build/deploy, and that is acceptable in
the current scope. Real-time feeds are explicitly **out of scope** for now — we
optimize for reproducibility and a self-contained image over up-to-the-minute
accuracy. Any source with live characteristics is captured at build time and
treated as a snapshot.

## Feature: Road Construction (🚧)

**Goal:** show where the metro is under road construction, on a map, colored by
project phase.

**Sources**

1. **City of Las Vegas — Capital Improvement Program lines (MasterWorks)**
   `MASTERWORKS_CIP_LINES_prd_view/FeatureServer/0` on the City's ArcGIS org
   (`F1v0ufATbBQScMtY`, the **same org** the rest of the CLV data already uses).
   Keyless, polyline geometry. ~358 projects with `STATUS`/`PHASE`
   (Construction / Design / Bidding / Planned / Closed…), schedule, road extent,
   contractor, and a project website. This is the primary layer.

2. **Nevada 511 / NDOT roadwork events** (`nvroads.com/api/v2/get/event`)
   State-maintained routes (I-15, US-95, I-215, Beltway). Adds live-style
   roadwork/closure events with lane impact and full-closure flags. **Requires a
   free developer key** (`NVROADS_API_KEY`). When the key is unset the source is
   skipped and the build stays secret-free (see Decisions). Clipped to the LV
   Valley bbox; encoded polylines decoded to lon/lat paths.

Both feeds are harmonized into one `raw.road_construction` table (a `data_source`
column distinguishes them) → `stg_road_construction` → `mart_road_construction`
→ `views/road_construction.py`, which draws a deck.gl **PathLayer** (a first for
this codebase — every prior layer was points) colored by phase, orange for
active construction.

**Coverage / known gaps**

- CLV CIP covers City of Las Vegas capital projects; 511 covers state routes.
- Purely local surface-street work in **other** municipalities (Henderson,
  North Las Vegas, unincorporated Clark County) is **not** covered — those are
  per-jurisdiction ROW-permit systems and are a possible phase 2.

## Decisions

- **Staleness accepted (snapshot).** Baking the 511 feed at build time undercuts
  its real-time value, but that is fine in current scope. No scheduled rebuild is
  planned yet; revisit if/when "live" becomes a goal.
- **511 key is optional and env-gated.** The repo's README states there are no
  secrets (all data is public). To preserve that for the default build, the 511
  fetch is skipped with a warning when `NVROADS_API_KEY` is absent, so the
  keyless CLV layer always ships. Set the key in the Railway env to include
  state-route events.
- **Line geometry stored as JSON path string.** `path_json` (a JSON array of
  `[lon, lat]` vertices) travels through DuckDB/dbt and is parsed in the view for
  the PathLayer; a centroid lat/long is also stored for map anchoring and to keep
  short/point-only features clickable.

## Source traps discovered (do not reuse)

- **NDOT `Project_Boundaries` (`gis.dot.nv.gov`) is NOT construction.** It's the
  NDOT Location Division's **survey / lidar / mapping** boundaries, dated
  1994–2011. Looks relevant by name; isn't. Rejected.
- **The ArcGIS org `6Y56Ohy0RCFlntCT` "CityworksConeZone" is the WRONG CITY.**
  Its road names (Falcon Hwy, Judge Orr Rd, Meridian Rd, Hodgen Rd) are in
  **El Paso County, Colorado** — "Cone Zone" is a Colorado Springs-area program.
  It surfaced under a Las Vegas search but is not Las Vegas data. Rejected.
