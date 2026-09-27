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

## In development: Valley coverage expansion & census-tract choropleths

**Interview decisions accepted 2026-09-26; development subsequently authorized.** This extends the existing app and retains its snapshot architecture,
Streamlit stack, and neon visual identity with calm, legible data displays.

### Current implementation increment

Implemented locally on `feat/valley-tracts`: full-snapshot census-tract maps for
calls, parks, rentals, and art; Henderson art and transportation CIP ingestion;
shared color scales, counts/default and eligible rates; coverage matrix; spatial,
SQL, and app regression tests. Existing place/road maps remain. This is the first
increment, not a claim of full municipal parity or a deployed release.

Implementation uses matching Census 2020 tract/place boundaries and `POP100`.
City filters select whole intersecting tracts; no clipped numerator/denominator
mismatch. `docs/COVERAGE.md` documents limitations and source discovery;
`DECISIONS.md` holds draft trade-offs awaiting human confirmation. Further
Henderson/North Las Vegas source integration and human source/visual review remain
open in `TASKS.md` and `BLOCKED.md`.

### Goal and scope

Expand **North Las Vegas and Henderson across as many existing topics as public
data supports**, alongside Las Vegas and existing unincorporated Clark County
coverage. Pursue breadth through incremental releases; complete three-city parity
is not a release prerequisite. Do not imply equivalent coverage merely because
a regional source includes some records in a city.

The repository already ingests parks and short-term rentals for both cities, and
Henderson permits and business licenses. Audit and extend these integrations
rather than rebuilding them. Inventory all existing topics: public art,
restaurant inspections, fire inspections, calls for service, building permits,
business licenses, short-term rentals, parks, road construction, marriage
licenses, tourism/gaming, Lake Mead, weather, and air quality. Regional and
station-based topics retain their natural geography when city or tract detail is
unavailable; do not fabricate local breakdowns.

Before implementing each source, record its official publisher, endpoint,
access requirements, reuse terms, jurisdiction, record grain, historical span,
update cadence, location precision, and available fields. New source availability
is **unverified** at planning time. Prefer public, keyless sources; document any
access dependency before selecting a source. Missing or incompatible sources
become explicit coverage gaps, not blockers for unrelated datasets.

Normalize comparable fields while retaining source IDs, source jurisdiction,
definitions, dates, and provenance. Deduplicate overlapping regional/municipal
records where evidence supports doing so. Keep incompatible measures separate
(for example, calls for service versus reported crimes, or permits with versus
without valuation). Do not present them as equivalent city comparisons.

### Map behavior

- **Census-tract choropleths** become the area-comparison map pattern. Replace
  the crime page's 3D hex columns with flat filled tract polygons first, then
  apply the pattern to other topics with suitable geographic detail and metrics.
- Retain point maps for individual places and line maps for road projects.
  Choropleths complement these where useful; not every topic needs a tract map.
- Open on all covered jurisdictions for the selected topic, with a city filter
  and clearly labeled existing unincorporated coverage. Filters must not imply
  coverage in an unavailable city.
- Default to **counts**, with a defined counting unit for each topic (such as
  calls, distinct permits, or establishments). Offer per-resident rates only
  when population is a meaningful denominator and compatible population data
  exists. Show the denominator source, vintage, and rate unit.
- Use a shared color scale across cities for the same metric and reporting
  period. City filtering alone must not rescale the colors. Label the legend,
  units, period, and coverage limitations; separate incomparable series.
- Distinguish observed **zero** from unavailable, incomplete, suppressed, or
  unassignable data. Never fill missing coverage with zero. Tooltips show tract
  ID/name, value, reporting period, coverage, and population when used.
- Preserve useful map exploration: tract selection exposes a summary and
  relevant breakdowns consistent with the selected metric and filters. Keep
  polygons, borders, legends, and no-data states readable on the dark basemap.

### Geographic and analytical requirements

Use authoritative census-tract boundaries with stable GEOIDs and a documented
boundary vintage. Aggregate the **full eligible snapshot**, not the current
random crime-map sample. Store tract assignments and aggregates in the build-time
warehouse/dbt pipeline; avoid repeated spatial joins during interactive use.
Document exclusions and reconcile assigned totals to eligible source records.

Select a compatible population dataset and document its vintage during source
discovery. Missing or zero denominators produce unavailable rates, never infinity
or a misleading zero. Preserve the distinction between incident location and
resident population; rates are contextual measures, not individual risk scores.

Tracts can cross city boundaries. Before implementation, document a deterministic
city-filter and tract-membership policy, including edge points, overlaps, invalid
coordinates, and records lacking locations. Do not divide city-filtered counts by
whole-tract population when the numerator covers only part of that tract. Disable
rates for such combinations unless a defensible matching denominator is available.
Keep source jurisdiction separate from geographic city assignment.

### Delivery and acceptance

1. Audit coverage and source feasibility, including time-window and definition
   compatibility. Publish a topic-by-jurisdiction coverage matrix with available,
   partial, unavailable, and incompatible states and reasons.
2. Build the shared tract foundation and replace the crime hex map using existing
   eligible data; do not wait for every new municipal source.
3. Add verified Henderson/North Las Vegas sources and appropriate choropleths in
   incremental topic releases. Retain useful location and road maps.
4. Verify tract assignments, deduplication, aggregate reconciliation, denominator
   handling, coverage states, consistent scales, and filter/detail behavior.
   Expand hermetic CI fixtures and dbt tests with each new lineage.

Acceptance requires no hex columns on the crime map; full-data tract totals;
counts by default; valid optional rates; all-covered-cities default and city
filter; shared scales; visible missing coverage; and documented source/geometry
vintages. Each topic release must satisfy these requirements where applicable.
Completeness means every existing topic is assessed for both cities and every
gap has a recorded reason, not a promise that every dataset exists.

**Further discovery:** additional municipal source endpoints, harmonization of
Henderson crime/permit candidates, and release grouping based on verified source
feasibility. First-increment geography/metric policies are documented above.

**Out of scope:** real-time feeds, fabricated geographic detail, forced
cross-city comparability, replacing all point/line maps, and frontend migration.

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

3. **City of Henderson — transportation CIP lines**
   `public/CIP/MapServer/7` and `/8` on the city's official GIS server. Keyless
   transportation-project geometry with phase/status and schedule. Exact duplicate
   project/path pairs are collapsed; separate parts stay separate, with original
   layer/object/part IDs retained in raw data. This does not provide every local
   ROW permit or closure.

The three feeds are harmonized into one `raw.road_construction` table (a `data_source`
column distinguishes them) → `stg_road_construction` → `mart_road_construction`
→ `views/road_construction.py`, which draws a deck.gl **PathLayer** (a first for
this codebase — every prior layer was points) colored by phase, orange for
active construction.

**Coverage / known gaps**

- CLV CIP covers Las Vegas capital projects; Henderson CIP adds transportation
  projects; optional 511 covers state routes. These are project/event segments,
  not an exhaustive inventory of active construction.
- North Las Vegas local-road work and comprehensive Henderson ROW-permit/closure
  coverage remain gaps. Additional unincorporated Clark County local-road
  coverage remains a future extension.

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
