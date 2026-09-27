# Decisions

Append-only log of decisions that carried a real trade-off (chose X, rejected Y, why).

## 2026-09-27 — Phase 4 batch 1: Henderson crime *reports* as a separate topic, count-only

*Draft for Evan's confirmation (agent drafts; human confirms). Batch and measure
choice were confirmed interactively on 2026-09-27.*

**Chose:** add City of Henderson crime **reports** (public-safety ArcGIS,
`OpenDataPublicSafety` "Crime Data {year}" layers, recent years `[2024, 2025]`)
as a **new, clearly-labeled tract topic** (`henderson_crime`) — never merged with
or scaled against LVMPD calls-for-service. Layers are resolved **by name** (not
hardcoded ids) so an appended annual layer can't silently return the wrong year;
a missing requested year raises. Dates are `esriFieldTypeDate` epoch-ms, parsed
with `_epoch_to_date`. Coverage is Henderson-only: Henderson-only tracts read
`available`, LV/Henderson crossing tracts `partial` (observed records, no zero),
others `unavailable`.

**Rejected:**
- *Merging Henderson crime into the `calls` map/metric.* A crime **report** is a
  different measure from a **call for service**; combining them (or sharing a
  color domain) would invent false comparability. Kept as a distinct topic with
  an explicit note. (Confirmed by Evan.)
- *Offering a per-1,000 resident rate (as `calls` does).* **Deferred — count-only
  (`rate: False`).** The verified feature counts are inconsistent across years
  (2024 ≈ 6,405 vs 2025 ≈ 27,168 as of the 2026-09-27 source check); a per-capita
  rate over that ragged, non-annualized window would mislead. Counts are the
  honest default until annual completeness is human-verified. Rejected `rate:True`
  parity with `calls`.
- *Loading the full 2014–2025 archive.* Mirrored the LVMPD two-recent-years window
  to keep the snapshot/image bounded; older layers remain available to add later.
- *North Las Vegas crime in this batch.* No verified bulk feed exists (portals are
  interactive-search only); left a documented gap rather than a fabricated source.

**Needs human inspection before release (per CLAUDE.md — the agent never sees raw
records):** the 2024-vs-2025 report-volume gap. A full 2024 year at ~¼ of 2025's
volume suggests a partial load, a retention change, or a real reporting shift —
Evan should confirm which before the topic is presented as complete. Recorded in
`BLOCKED.md`.

## 2026-09-26 — P5 dbt docs: static single-file, hosted on GitHub Pages, built hermetically

**Chose:** publish the dbt docs via a dedicated GitHub Actions workflow that runs
`dbt docs generate --static` (one self-contained `static_index.html`) from the
committed seed fixtures and deploys it to GitHub Pages on every push to `main`.
Linked from the landing page and README; the hand-built `site/` is untouched.

**Rejected:**
- *A second Railway static service.* GitHub Pages is free, needs no extra service,
  and a workflow keeps the docs in lockstep with `main`. Railway would add cost and
  a separate deploy surface for a static artifact.
- *Multi-file `target/` docs bundle.* `--static` emits a single 3.3M HTML file —
  one artifact to upload, no path/asset wiring. The multi-file bundle offers no
  benefit for hosting.
- *Generating docs at deploy time from the real warehouse (full catalog).* Would
  give complete column-type/stats catalog for all 45 models, but couples the docs
  build to the (currently paused) Railway deploy and the live civic feeds. Building
  hermetically from seeds keeps docs publishing independent of the data pipeline's
  health; the manifest still carries every model's lineage and yml descriptions —
  only catalog stats are limited to the seeded lineages. Docs freshness beats
  catalog completeness for a portfolio reference.

**Consequence / blocker:** GitHub Pages must be enabled with source = "GitHub
Actions" before the deploy job can publish; enabling it is a public-publish action
left to Evan (recorded in `BLOCKED.md`). The workflow builds regardless; only the
final deploy step waits on that toggle.

## 2026-09-26 — P2 data-quality tests: severity split by value provenance

**Chose:** add the P2 test suite (`accepted_values`, `dbt_expectations` range
checks, a singular date-order test) scoped to the two CI-seeded lineages
(`stg_road_construction+`, `stg_art_work_points+`), via `dbt_utils` +
`dbt_expectations` (`packages.yml` + a `dbt deps` CI step). **Severity is set by
where the value comes from:**
- **Hard error (blocks the build):** values our own code controls or structural
  invariants — `accepted_values` on `data_source` (fixed literals at
  `build_warehouse.py:907,970`), and `not_null` / `unique` on keys/coords.
- **`warn` (surfaces, never blocks):** values passed through from upstream feeds —
  `accepted_values` on `status` (CLV `PHASE/STATUS`, NDOT `EventType`), the
  `latitude`/`longitude` valley-bounds ranges, and the `end_date >= start_date`
  singular test.

**Why the split (the key trade-off):** CI runs these tests against the tiny seed
fixtures, but the **deploy** runs `dbt build --exclude-resource-type seed` over
the *full live warehouse* (Dockerfile). The `status` list and coordinate bounds
were reverse-engineered from 6/5 seed rows; the real feeds carry more status
values (Bidding, On Hold, …) and CLV centroids are not bbox-clipped upstream. As
hard errors they would abort the production Docker/Railway build the first time an
upstream value drifted. As `warn` they remain a visible data-quality signal
without coupling the deploy to upstream cleanliness. Range bounds were aligned to
the pipeline's own `METRO_BBOX` (`build_warehouse.py:102`) rather than arbitrary
seed-derived numbers.

**Rejected:**
- *Hard-assert `status`/coords against the real distinct values.* Would require
  inspecting the live warehouse to enumerate every status and coordinate bound,
  and would still break future deploys whenever a feed adds a new status. Deferred
  to Evan (human inspects the data) if hard gates are later wanted.
- *Add tests across all ~30 marts now.* CI seeds only two lineages, so tests on
  unseeded models would never run in CI. Grow tests and seeds together (tracked as
  the open P1 seed-expansion item).
- *A `relationships` test on `mart_art_work_points.ObjectId` → staging.* The mart
  is a straight `select` from staging with no filter/join, so the relationship can
  never fail — it's inert. Dropped; `not_null` + `unique` already assert the grain.
  A real FK relationships test awaits seeding a multi-table lineage (restaurants).

**Verification:** hermetic CI flow (deps→seed→build) is green (29 tests). TDD
negatives confirm each type fires: a bogus `status` and an out-of-valley latitude
each **warn** (build still succeeds, proving the deploy stays unblocked); a bad
`data_source` **errors**. Reviewed by a fresh-context adversarial agent, whose
HIGH findings (feed-passthrough hard-asserts breaking the deploy) drove this split.

## 2026-09-26 — Visual identity: "Neon Night on the Strip" (redesign)

**Chose:** reskin the explorer from the current *desert atlas* identity (warm beige
paper, charcoal ink, terra-cotta red, light mode) to a **classic neon/retro Las
Vegas Strip** identity — near-black night sky, warm-white text, hot-pink / cyan /
gold / purple neon accents, Monoton neon-tube display font on the wordmark & hero,
glow + marquee-bulb treatments on the chrome.

**Scope:** visual reskin only. Page structure, navigation, data pipeline, and IA
are unchanged. No migration off Streamlit.

**Rejected:**
- *Keep the desert-atlas identity.* It's clean and legible but doesn't answer the
  brief ("encapsulate a Las Vegas Strip experience") and is less memorable for a
  recruiter-facing portfolio piece.
- *Modern-luxury-Strip or maximalist-casino aesthetics.* Neon/retro ties directly
  to the app's "Elvis" name (Elvis-era Vegas) and reads unmistakably as "the Strip"
  without the restraint of luxury-minimal or the noise of maximalism.
- *Migrating the frontend off Streamlit* (e.g. Next.js over DuckDB) for full
  creative control. Far larger effort; the token-driven Streamlit design already
  centralizes ~80% of the look, so a reskin captures most of the value cheaply.
- *Full experiential "walk down the Strip" IA redesign.* Higher ambition but higher
  risk to the data legibility that a portfolio piece depends on.

**Governing principle — "flash on the chrome, calm in the data":** neon and the
display font are confined to the marquee zone (hero, wordmark, section labels,
collection cards, link/hover states). The data zone (charts, maps, tables, metrics)
stays a calm low-chroma dark surface with neon only as accent, so *legibility wins*
wherever flash and readability conflict (explicit priority set by Evan).

**Font:** Monoton (neon-tube) for display, chosen over Bungee (signage) and a
script face (Elvis-era). Restricted to large display type only; body stays DM Sans,
mono labels stay Space Mono — both kept for readability.

**Consequence:** the recent "dark session contrast" work (commits fixing the CSS
that *forced* a light palette in dark browser sessions) is inverted by this change —
the app now embraces dark. Those overrides in `explorer.css` are removed/reversed.

## 2026-09-26 — DRAFT, awaiting Evan's confirmation: tract maps and first municipal increment

**Interview-confirmed product direction:** expand Henderson/North Las Vegas as
far as public data supports; census-tract choropleths for area comparisons;
retain useful point/line maps; counts by default, optional defensible population
rates; shared city scales; incremental releases with explicit coverage gaps.

**Implementation trade-offs proposed in this branch:**

- Use the Census 2020 tract/place layers and their matching `POP100` field. This
  avoids mismatching boundary/population vintages or adding an API-key dependency.
  Rejected a current-population claim: the denominator and city limits are from
  2020, and the app labels this. A newer matched vintage remains a later upgrade.
- City selection retains whole intersecting tracts, including boundary-crossing
  tracts. Rejected clipped numerators divided by full-tract population. The app
  explicitly says these are tract totals, not city totals; partial source
  footprints cannot produce population rates.
- Compute spatial assignments with Shapely's spatial index at build time and
  model the aggregates in dbt. Rejected runtime joins and sample-derived counts.
  Edge/overlap ties use the lowest GEOID once and are audited. Known source-scope
  gaps remain unavailable/partial, not zeros.
- Permit a logged topology repair only when polygon area changes by at most one
  part per million (absolute floor 1e-12 square degrees). Material changes still
  fail. Synthetic tests exercise holes, ties, invalid coordinates, harmless
  zero-area artifacts, and rejected material repairs.
- Add Henderson art and transportation lines from verified city schemas; retain
  separate road segments and namespace artwork IDs. Henderson crime-report
  layers are not silently merged into LVMPD calls. North Las Vegas source gaps
  and further Henderson permit/crime candidates remain explicitly documented.

These implementation choices are a draft ledger entry for human confirmation,
not a claim that source meaning has received human review. See `docs/COVERAGE.md`
for official source links and `TASKS.md` for verified implementation status.
