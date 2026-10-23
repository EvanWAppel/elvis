# Elvis — session primer

## Next session — 2026-10-24 weekend

**Goal.** Elvis is a public Streamlit explorer of free Las Vegas Valley open data
(public sources → DuckDB → dbt → Altair/PyDeck), and the portfolio's dbt-depth
analytics-engineering flagship. It also hosts "Ask Tiresias", a text-to-SQL page.

**Current state (main @ 865b888, 2026-10-22).**
- Tests on `main`: `uv run pytest tests/python -q` gives **40 passed, 6 skipped**
  (the skips need local dbt artifacts). `uv run ruff check .` is clean. The
  hermetic dbt build (CI's seeds + `--select` list from `.github/workflows/ci.yml`)
  gives **49/49 PASS**. `uv run ty check` reports **37 diagnostics**, so it is not
  clean yet.
- **`main` auto-deploys to Railway** (elvis.evanappel.me). A merge is a deploy.
- **In flight, not merged:** branch `redesign-neon-phase1` (pushed, **no PR yet**).
  It adds `tests/python/test_theme.py` (a contract test covering theme tokens and
  WCAG AA contrast) and ticks off redesign Phase 1 in TASKS/BLOCKED. Don't redo
  that work. The local checkout `~/Documents/portfolio/geographic/elvis` sits on
  it, so leave that checkout alone and work in a worktree.
- No open PRs. Tract-map increment, Henderson crime, Tiresias v0.1.0 and the
  ArcGIS retry are all merged.
- There is no repo `CLAUDE.md`. The house rules come from `~/Documents/portfolio/CLAUDE.md`.
- `RECRUITER-PRIMER.md` is gitignored. It exists only in the main checkout, so read it there if you need it.

### Autonomous tasks, in order

Each task gets its own branch off `origin/main` and opens one PR. Never merge.

1. **PR for `redesign-neon-phase1`** (S). Rebase it onto `origin/main`, then run
   pytest and ruff, then open the PR. *Done:* the PR is open and CI is green.
   *Test:* `uv run pytest tests/python -q && uv run ruff check .`
2. **TASKS.md tidy** (S). Close or annotate the stale items:
   - P1 "Push branch + open PR": CI already runs on PRs.
   - P5 "Blocked on Evan: enable GitHub Pages": Pages went live 2026-09-27.
   - The "Historical deploy failure" section: superseded by DECISIONS 2026-10-04
     (retry with backoff, then fail loudly).
   - The Road Construction "Henderson/NLV" item: it duplicates Phase 4.

   Edit docs only, and leave the redesign Phase 1 section alone (task 1 changes it).
   *Done:* every open `- [ ]` in TASKS.md is actually open. *Test:* none (docs).
3. **Unit tests for the pure helpers in `build_warehouse.py`** (M). None are tested
   today: `_decode_polyline`, `_iso_date`, `_epoch_to_date`, `_nv_clean`,
   `_line_path`, `_path_centroid`, `_centroid`, `_point_in_ring`, `_parse_lvcva`
   (use a synthetic xlsx/bytes fixture) and `_read_delimited`. Use synthetic inputs
   only. Put shared fixtures in `conftest.py`. Fix a real bug only test-first, and
   say so in the PR. *Done:* a new `tests/python/test_build_helpers.py` passes
   with no network access. *Test:* `uv run pytest tests/python -q`
4. **Expand hermetic CI seed coverage** (TASKS P1/P2 open items) (L). Add
   **synthetic** seed CSVs for 2–3 more lineages (suggested: `crime_calls`,
   `building_permits`, `snhd_*`). Take the column names and types from
   `models/staging/sources.yml`, the staging SQL and `build_warehouse.py`, never
   from real data. Register them in `dbt_project.yml` with `+column_types`. Add
   `not_null`/`unique`/`accepted_values` tests, using severity by value provenance
   (DECISIONS 2026-09-26). Extend CI's `--select`.
   *Done:* the hermetic build is green with more nodes, and a TDD negative fixture
   turns it red. *Test:* `uv run dbt deps --profiles-dir . && uv run dbt seed --profiles-dir . && uv run dbt build --profiles-dir . --select <ci list>`.
   Run this **only in a worktree with no `vegas.duckdb`**. Never seed a real warehouse.
5. **Bring `ty check` to zero on app code** (M). Of the 37 diagnostics, about 25 are
   Altair `.encode` false positives in `views/*.py`. Others are in
   `build_warehouse.py` (`_ipv4_first`, HTTPError), `tests/python/*` and the
   `DataframeState.selection` calls. The legacy files `main.py`, `__init__.py` and
   `scratch.ipynb` import polars and feynman, which aren't installed. **Exclude**
   them in a `[tool.ty]` section of `pyproject.toml` and do not delete them (see
   the NOT list). Prefer real fixes over `# ty: ignore`; where an ignore is needed,
   give the reason on the same line.
   *Done:* `uv run ty check` exits 0, and you may add a `ty` step to CI's lint job.
   *Test:* `uv run ty check && uv run pytest tests/python -q`
6. **Phase 1 source discovery, metadata only** (M). For the city/topic pairs still
   missing in `docs/COVERAGE.md`, look for official Henderson and North Las Vegas
   endpoints. Use **ArcGIS `?f=json` metadata and `returnCountOnly` only**, and
   never fetch or print records. Record publisher, endpoint, fields, grain,
   date span and status, or record the reason a pair is unavailable. Don't wire
   any new source into the build; picking which sources to build is Evan's call.
   *Done:* the COVERAGE.md gaps each have a verified-source or unavailable entry.
   *Test:* none (docs).

### House rules (from portfolio CLAUDE.md, ROCRLL)
- Use uv for everything (`uv run …`). Add dependencies with `uv add` or
  `uv add --dev`, never by editing pyproject deps by hand.
- **TDD with pytest.** Write the test first, put shared fixtures in `conftest.py`,
  and lint with ruff, type-check with ty and run hooks with prek
  (`uv run prek run --all-files`).
- Use logging. Don't hide or wrap errors.
- **The agent never sees raw data.** Tests use synthetic fixtures, and source
  checks stop at metadata and counts.
- Any decision with a real trade-off gets a `DECISIONS.md` entry marked
  "drafted by Claude, awaiting Evan's confirmation".
- Before handing off, get an independent fresh-context review of each PR's diff.
  High-severity findings go to Evan; don't auto-action them.
- Anything only Evan can do goes in `BLOCKED.md` in the canonical format.
- If anything is unclear, stop and ask (prime directive).

### Do NOT
- Push to, merge into or deploy `main`. A merge to `main` **is** a Railway deploy.
  Opening PRs is fine.
- Run `railway`, deploy tools or anything that changes Railway or GitHub settings.
- Read `.env`. Don't run the live Tiresias eval or anything else that needs
  `ANTHROPIC_API_KEY` (a paid key) or `NVROADS_API_KEY`.
- Use browser automation. Verify with curl, logs and tests instead. Visual
  dark-theme or WebGL review (Phase 3 and the redesign) is Evan's job.
- Work on any of these Evan-owned items:
  - human review of the tract maps and COVERAGE.md
  - NV511 key rotation
  - the BuildKit secret mount (needs a live Railway build to verify)
  - promoting `status`/coordinate tests to hard errors (needs Evan to look at live data)
  - `docs/ANALYTICS-ENGINEERING.md` (needs Evan's voice)
  - P3 Snowflake (needs an account)
  - confirming the draft entries in DECISIONS.md
- Delete the legacy `main.py`, `__init__.py`, `scratch.ipynb` or other files whose
  purpose is unclear. Ask first.
- Run `dbt seed` against a real or full `vegas.duckdb`.
- Touch the local checkout `~/Documents/portfolio/geographic/elvis`.
- Use `git-crypt`. Nothing in this repo is encrypted (there's no `.gitattributes`).
