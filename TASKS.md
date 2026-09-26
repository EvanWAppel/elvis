# Tasks

## Redesign — "Neon Night on the Strip" (2026-09-26)

Visual reskin only: desert-atlas identity → classic neon/retro Las Vegas Strip.
Direction & rationale in `DECISIONS.md`. Branch: `redesign/neon-strip`.
Governing principle: **flash on the chrome, calm in the data** (legibility first).

### Phase 1 — Core palette flip (reskins ~80% at once)
- [ ] `.streamlit/config.toml`: `base="dark"`, neon `primaryColor`, dark
      backgrounds, warm-white `textColor`.
- [ ] `explorer.css` `:root`: flip tokens to night-sky palette (bg `#0b0a14`,
      panel `#16141f`, text `#f4f1e9`, accents pink/cyan/gold/purple).
- [ ] `explorer.css` lines 3–13: remove/invert the "force light in dark sessions"
      overrides — the app now embraces dark.
- [ ] `ui.py:atlas_chart()`: dark background + warm-white labels + dim grid +
      neon categorical range.
- [ ] Verify every page renders legibly on dark (local run + curl; no browser).

### Phase 2 — Neon chrome
- [x] Add Monoton font import; apply to `.elvis-brand` wordmark + the cover
      accent word (`h1 em`, "Strip."). Left full `h1` and section labels in
      DM Sans / Space Mono for legibility (Monoton is unreadable small).
- [x] Glow (`text-shadow`) on display type (wordmark, star, accent word,
      section labels); neon glow on link hover/focus.
- [x] Marquee bulb border: `.elvis-cover` framed top & bottom by glowing gold
      bulbs (pseudo-elements). Neon glow on collection-card top borders; metrics
      kept calm (data zone).
- [x] Neon marquee hero — done as a CSS bulb-frame around the existing cover
      (robust, in-DOM) rather than a separate iframe component.
- [x] Flicker animation on the wordmark + star, gated behind
      `prefers-reduced-motion` (added `animation:none` to the reduce block).

### Phase 3 — Data-zone cleanup (the legibility pass)
- [x] Basemaps → Carto `dark-matter` via `ui.MAP_STYLE` on all 6 maps
      (parks, fire, short_term_rentals, road_construction, crime, +public_art
      which had used the default basemap).
- [x] Centralized the palette in `ui.py` (`PINK/CYAN/GOLD/PURPLE/BLUE/GREEN/`
      `ORANGE/MUTED`, `SERIES`, `SEQUENTIAL`); retargeted all ~28 hardcoded
      Altair `color=`/scale hexes across 10 chart views to import from it.
      `atlas_chart` now uses `SERIES` too.
- [x] PyDeck fills retuned for dark tiles: `public_art` (pink), parks
      (cyan/green/muted), STR (pink/cyan/purple by jurisdiction), fire
      (gold→pink violation ramp), road_construction (neon phase palette),
      crime HexagonLayer (added neon `color_range`).
- [x] Sequential/continuous scales → dark-safe ramps: air quality
      (green→gold→orange→pink), desert heat (gold→pink), crime (`SEQUENTIAL`).

### Phase 4 — Polish
- [x] Contrast audit (WCAG AA): all text/bg pairs pass for their use. Purple
      was the only sub-4.5 value (4.35 as chart accent) → bumped `#8a4fff` →
      `#9866ff` (5.32) in `ui.py` + CSS token, and fixed the stale STR Henderson
      RGB that still used the old purple.
- [x] Mobile breakpoint (`@media max-width:700px`) reviewed on dark: marquee
      bulb pseudo-elements reflow with the container; `.elvis-star` repositioned
      (`top:44px`) for the new cover padding; no overlap. No change needed.
- [x] Adversarial review (fresh-context agent) — no HIGH findings. Actioned:
      purple token consistency, standardized 5 PyDeck tooltip backgrounds to the
      panel token `#211f30` (were light leftovers: steelblue/seagreen/#b22222/
      #263238), reordered `SEQUENTIAL` to a luminance-monotonic plasma ramp
      `[PURPLE,PINK,ORANGE,GOLD]` so the crime quantitative heatmap reads
      "more = hotter" (+ matching hex `color_range`), updated stale Positron
      comment in crime.py.

## Deploy — PAUSED (upstream outage, 2026-08-15)

The "current only" filter is committed but NOT yet live. A `railway up` on
2026-08-15 **failed the build** — not from our change, but from an unrelated
upstream source going empty:

- `build_warehouse.py` fetching `Business_Licenses_OpenData` (CLV ArcGIS org
  `F1v0ufATbBQScMtY`) got **zero features**. `fetch_layer` returned a 0-column
  DataFrame → `load_raw` → `_duckdb.InvalidInputException: Need a DataFrame with
  at least one column`. Whole build exits 1, so the deploy never shipped.
- Confirmed upstream, not a network flake: the endpoint responds 200 with intact
  schema but `{"count":0}`. It had data in the Aug 13 build. Sibling sources on
  the same org are healthy (e.g. Art Work = 63 rows), so the org is up; this one
  layer is empty.
- The Aug 13 build is still live and unaffected — no regression.

Retrying as-is will fail identically until the City repopulates the layer.
Decision on how to handle deferred (per Evan): options were (a) wait & retry,
(b) make the build resilient to a transiently-empty source (build an empty typed
table from the layer's field metadata + a loud WARNING so one empty feed can't
block the other ~14 datasets — must keep dbt happy on a 0-row raw table), or
(c) retry now (will fail). **Not decided yet.**

## Roadmap shift — see `RECRUITER-PRIMER.md`

New brief reframes Elvis as the portfolio's **dbt-depth analytics-engineering
flagship** (vs. `robbins` = PNW/Seattle geo flagship). One-weekend plan, in
order: P1 CI (`dbt build` + `ruff` on every PR) → P2 data-quality test suite
(`dbt_utils`/`dbt_expectations`, `accepted_values`/`relationships`/singular) →
P5 generate+host dbt docs → P3 Snowflake dual-target + `SNOWFLAKE.md` → P8
teaching README + elvis-vs-robbins note. Second weekend: P4 intermediate layer,
P6 freshness/exposures, P7 incremental + snapshot. Honesty guardrails in §6.

### P1 — CI (`dbt build` + `ruff` on every PR)
- [x] Hermetic CI design chosen (seeds over live-network build): committed
      fixtures in `seeds/` stand in for the `raw.*` tables so `dbt build` runs
      offline, deterministic, never flaky on an upstream outage.
- [x] `macros/generate_schema_name.sql` so `+schema: raw` lands seeds in
      `vegas.raw.*` verbatim (matching `source('raw', ...)`); models with no
      custom schema stay in `main`.
- [x] `seeds/road_construction.csv` (6 rows) + `seeds/art_work_points.csv`
      (5 rows) matching the real raw schemas; `dbt_project.yml` seed config with
      `+schema: raw` + explicit `+column_types`. `!seeds/` added to `.gitignore`
      (repo-wide `*.csv` ignore would have dropped them).
- [x] Prod/local safety: `Dockerfile` + README build now use
      `dbt build --exclude-resource-type seed` so fixtures NEVER overwrite the
      full-size tables. Verified: `raw.road_construction` stays 382 rows, 105
      nodes build, zero seed activity.
- [x] `.github/workflows/ci.yml`: `ruff` job + hermetic `dbt` job (uv sync →
      `dbt seed` → `dbt build --select stg_road_construction+ stg_art_work_points+`).
      Triggers on PR + push to main; badge in README.
- [x] Verified locally end-to-end: 17 nodes PASS (2 views, 2 marts, 13 tests) in
      <1.5s; negative test (null latitude fixture) turns it red as required;
      `ruff check .` clean repo-wide (fixed a stray unused import; excluded the
      scratch notebook via `ruff.toml`).
- [ ] Push branch + open PR so the checks actually run on GitHub (needs Evan —
      not pushing without the ask).
- [ ] Expand seed coverage beyond the 2 starter domains (restaurants, crime,
      permits…) as P2 adds tests — CI currently gates only the seeded lineages.

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
- [x] "Current only" filter (drop `Closed`/past-`end_date` projects), defaulted
      on so the map opens on what's actually active. Sidebar checkbox in
      `views/road_construction.py`; parses `end_date`, hides `Closed`-phase and
      past-end projects. Snapshot counts: 382 → 160 current (222 hidden = 135
      Closed + 87 past end date, incl. 29 lapsed `Construction`-phase). ruff + ty
      clean.
- [ ] Phase 2 (optional): local surface-street construction for Henderson /
      North Las Vegas / unincorporated Clark County via their ROW-permit feeds.
- [x] Add the Road Construction dataset to the README dataset list. (Already
      done in fb0ca12 — the Datasets paragraph lists CLV CIP + Nevada 511/NDOT
      with the keyless/`NVROADS_API_KEY` note. Item was stale.)
