# Tasks

## In progress — Valley expansion & tract choropleths (2026-09-26)

**Interview complete; development authorized. First increment implemented on
`feat/valley-tracts`; further source expansion remains open.**
Requirements: `PRD.md`, "In development: Valley coverage expansion & census-tract
choropleths." Existing completed work below remains historical context; this
section supersedes the crime HexagonLayer direction and the optional status of
Henderson/North Las Vegas road-source discovery.

Accepted: pursue as many existing topics as public data supports in both cities;
use census-tract choropleths for area comparisons; retain useful point/line maps;
default to counts with valid optional per-resident rates; open on all covered
cities with a city filter and shared scale; release incrementally with explicit
coverage gaps. Preserve the snapshot architecture and current visual identity.

### First increment — implemented and checked locally
- [x] Shared Census 2020 tract/population foundation; whole-tract city selection,
      deterministic spatial assignment, full-record accounting, and coverage states.
- [x] Crime hex columns replaced; shared tract explorer added for calls, parks,
      rentals, and art, with counts/default and eligible per-1,000 rates.
- [x] Henderson public-art and transportation CIP adapters; namespaced artwork
      IDs, road source IDs, exact geometry deduplication, separate multipart paths.
- [x] Correct Henderson permit labeling to residential scope; fix the road URL
      contract from integer to varchar and label road counts as segments/events.
- [x] Coverage matrix and source contracts in `docs/COVERAGE.md`; proposed
      implementation trade-offs drafted in `DECISIONS.md` for Evan's confirmation.
- [x] 21 pytest tests (spatial, adapter, SQL negatives, map scales and Streamlit
      controls); hermetic dbt build: 49/49 selected nodes passed, no warnings.
      New modules pass `ty`; `ruff` passes. `prek` local hooks added and run.
- [x] Isolated integration against the existing full snapshot plus live new
      sources: geographic assignment reconciles, full dbt checked, changed pages
      pass AppTest. Final local full dbt build: 131 passed, 2 upstream road
      status/date warnings, 0 errors/skips. Local warehouse/catalog refreshed;
      previous warehouse backed up at `/tmp/elvis-expansion/vegas-before-tracts.duckdb`.
      No raw records displayed; no browser automation used.
- [ ] Human source/visual review and draft-ledger confirmation before release;
      see `BLOCKED.md`. PR creation authorized; deployment remains with Evan.

### Phase 1 — Coverage and source discovery
- [x] Inventory every existing topic against Las Vegas, Henderson, North Las
      Vegas, and existing unincorporated coverage; distinguish repository
      integration from verified current source availability.
- [x] Audit existing Henderson/North Las Vegas parks and rental integrations,
      Henderson permits/licenses, and regional feeds before adding duplicates.
- [ ] Find and verify official public sources for missing city/topic pairs,
      including local road projects/ROW permits. Record publisher, endpoint,
      access/reuse requirements, fields, grain, dates, location precision, and
      source health. Record unavailable or incompatible sources with reasons.
- [x] Define comparable measures and reporting windows per topic; preserve
      differences such as calls versus crimes and missing permit valuations.
      Assess regional/station topics without inventing tract or city detail.
- [x] Publish the coverage matrix and choose incremental topic releases based
      on verified feasibility; parity across all cities is not a release gate.

### Phase 2 — Shared tract foundation
- [x] Select authoritative tract boundaries and compatible population data;
      document vintages, GEOIDs, rate units, and topic-specific rate eligibility.
- [x] Define geographic city assignment separately from source jurisdiction,
      city-filter/tract membership rules, and treatment of crossing tracts,
      boundary points, overlaps, missing coordinates, and invalid geometry.
- [x] Ingest versioned geographic/denominator data into the build-time pipeline;
      create reusable dbt tract models and deterministic spatial assignments.
- [x] Build full-snapshot tract aggregates with documented counting units;
      report unassigned/excluded records and reconcile totals to source data.
- [x] Model coverage explicitly so true zero, missing, partial, and suppressed
      values stay distinct. Guard missing/zero population and numerator/
      denominator geography mismatches; disable unsupported rates.
- [x] Add hermetic spatial/coverage fixtures and dbt tests for GEOID integrity,
      unique assignment, crossing/edge cases, aggregate reconciliation, and
      rate eligibility. Include the new lineages in CI.

### Phase 3 — Crime choropleth and reusable map behavior
- [x] Replace `views/crime.py` hex columns with flat census-tract polygons using
      full eligible snapshot aggregates, not `mart_crime_map_sample` counts.
- [x] Implement all-covered-jurisdictions default, city filtering, counts as
      default, and eligible optional rate selection with clear units/periods.
- [x] Keep a common scale for comparable city values; city filtering alone must
      not change it. Provide a readable legend and distinct no-data styling.
- [x] Add tract tooltips and selection details consistent with active filters;
      update sampling/hexagon captions and preserve useful breakdowns.
- [ ] Verify dark-theme/WebGL legibility visually. Filter/detail consistency,
      empty states, full-snapshot totals, and app execution pass automated tests;
      visual review remains with Evan per CLAUDE.md.

### Phase 4 — Incremental municipal/topic expansion
- [ ] Add verified Henderson/North Las Vegas sources in topic batches, retaining
      provenance, definitions, source IDs, and reporting periods; deduplicate
      overlapping feeds using a documented rule.
- [ ] Extend staging/marts and hermetic fixtures/tests with each batch. Keep
      incompatible measures separate and verify build-time snapshot behavior.
- [ ] Add tract comparisons where location detail supports them; retain place
      points and road paths. Expose unavailable coverage rather than zero counts.
- [ ] Publish coverage, source/vintage, and metric definitions in the app and
      update README/dbt documentation as each topic ships.

### Phase 5 — Release validation
- [ ] Verify each topic against PRD acceptance: observed zero versus missing,
      full-data counts, valid rates, city filter, stable comparative colors,
      tract selection, and documented coverage/assignment limitations.
- [ ] Run expanded hermetic CI and an end-to-end warehouse/dbt/app build;
      assess source health and existing deployment blockers before release.
- [ ] Mark assessed-but-unavailable city/topic pairs with reasons; do not mark
      unsupported coverage as implemented or hold unrelated topics for parity.

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

## Historical deploy failure (upstream outage, 2026-08-15)

Current branch: the failing CLV license feed and dependent models are disabled;
the full local build passes. The incident below is historical, not a current
deployment blocker. The PR also installs dbt packages during a clean Docker build.

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

### P2 — Data-quality test suite (`dbt_utils` / `dbt_expectations`)
- [x] Add `packages.yml` (`dbt_utils` 1.x, `dbt_expectations` 0.10.x, pinned via
      `package-lock.yml`); `dbt deps` step added to CI before seed;
      `dbt_packages/` gitignored.
- [x] Enriched the two CI-seeded lineages beyond `not_null`/`unique`, with
      **severity set by value provenance** (see DECISIONS 2026-09-26):
      - hard error: `accepted_values` on `stg_road_construction.data_source`
        (code-controlled literals); `not_null`/`unique` on keys/coords.
      - `warn`: `accepted_values` on `status` (feed passthrough),
        `expect_column_values_to_be_between` valley-bounds on lat/lon (bounds =
        `METRO_BBOX`), and the singular date test — so upstream drift can't abort
        the production `dbt build --exclude-resource-type seed` deploy.
- [x] Singular test `tests/assert_road_construction_end_after_start.sql`
      (end_date must not precede start_date; null dates out of scope; `warn`).
- [x] Dropped an inert `relationships` test (mart is a straight `select` from
      staging → can never fail); `not_null`+`unique` assert the grain instead.
- [x] Adversarial review (fresh-context agent) — its HIGH findings (feed-passthrough
      hard-asserts would break the deploy build) drove the severity split.
- [x] Verified hermetically (deps→seed→build): 29 tests PASS. TDD negatives:
      bogus `status` and off-valley latitude each **warn** (build still succeeds);
      bad `data_source` **errors**. `ruff` clean; local warehouse restored.
- [ ] Extend the same test types to more domains as seed coverage grows (see the
      open P1 seed-expansion item) — CI still gates only the 2 seeded lineages.
- [ ] (Optional, needs Evan to inspect live data) Harden `status`/coordinate
      tests to hard errors by enumerating the real distinct values + bounds.

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
- [ ] Henderson / North Las Vegas local surface-street construction: now tracked
      in the planned valley expansion above (source availability unverified).
      Additional unincorporated Clark County ROW coverage remains optional.
- [x] Add the Road Construction dataset to the README dataset list. (Already
      done in fb0ca12 — the Datasets paragraph lists CLV CIP + Nevada 511/NDOT
      with the keyless/`NVROADS_API_KEY` note. Item was stale.)
