# Decisions

Append-only log of decisions that carried a real trade-off (chose X, rejected Y, why).

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
