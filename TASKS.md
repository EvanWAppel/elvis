# Tasks

## Road Construction (🚧)

### Done
- [x] Identify sources; reject `Project_Boundaries` (NDOT survey data) and the
      Colorado "ConeZone" org (wrong city). See PRD "Source traps".
- [x] `fetch_clv_cip()` — City of Las Vegas MasterWorks CIP lines (keyless).
- [x] `fetch_nvroads_roadwork()` — Nevada 511 events, env-gated on
      `NVROADS_API_KEY`, bbox-clipped, encoded-polyline decode.
- [x] Harmonize both into `raw.road_construction`; wire into `main()`.
- [x] Geometry/date helpers: `_line_path`, `_path_centroid`, `_iso_date`,
      `_decode_polyline` (polyline decoder verified against the Google reference).
- [x] dbt: `stg_road_construction`, `mart_road_construction`; source + mart docs
      with not_null tests. `dbt build --select …` green (PASS=6).
- [x] `views/road_construction.py` — PathLayer (first line layer) + centroid dots,
      phase colors, source/status filters, active-only toggle. Registered in nav.
- [x] `ruff` clean; new code passes `ty` (2 remaining `ty` diagnostics are
      pre-existing, unrelated to this change).

- [x] `NVROADS_API_KEY` set in Railway (production) and 511 branch verified live
      via `railway run`: 24 valley roadwork/closure events (23 roadwork, 1 closure,
      1 full closure), placeholder tokens ('Unknown'/'No Data') scrubbed. Combined
      mart = 358 CLV + 24 NDOT = 382 rows; dbt green.

- [x] Dockerfile: declare `ARG NVROADS_API_KEY` and pass it inline to the build
      `RUN` — Railway service vars reach runtime but NOT a Dockerfile RUN unless
      declared as a build arg. First deploy shipped CLV-only for this reason.
- [x] Deployed (`railway up`); build log confirms `nvroads: 24 events` and
      `road_construction: 382 rows`. Live at elvis-production-e07a.up.railway.app.

### Next / open
- [ ] Security: the inline build `RUN` prints the key into Railway build logs.
      Low risk (free, rate-limited, rotatable key) but consider a BuildKit
      `--mount=type=secret` to keep it out of logs; rotate the key if it matters.
- [x] Confirm the PathLayer renders as expected in the running app
      (`uv run streamlit run streamlit_app.py`) and tune width/zoom.
      Verified 2026-08-13: 382 projects / 71 active / 127 corridors, PathLayer +
      centroid dots + hover tooltip all render on the Positron basemap; width
      (get_width=5, width_scale=20, min 3px) and zoom 10.5 read well — no tuning
      needed. Long diagonal lines are legit multi-corridor CLV programs (High
      Injury Network, Rancho Drive), not bad geometry.
- [ ] Consider a "current only" filter (drop `Closed`/past-`end_date` projects)
      so the map defaults to what's actually active.
- [ ] Phase 2 (optional): local surface-street construction for Henderson /
      North Las Vegas / unincorporated Clark County via their ROW-permit feeds.
- [ ] Add the Road Construction dataset to the README dataset list.
