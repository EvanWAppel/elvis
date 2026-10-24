# Elvis — session primer

## Next session — 2026-10-24 weekend

**Goal.** Elvis is a public Streamlit explorer of free Las Vegas Valley open data
(public sources → DuckDB → dbt → Altair/PyDeck), and the portfolio's dbt-depth
analytics-engineering flagship. It also hosts "Ask Tiresias", a text-to-SQL page.

**Current state (main @ b3c798d, 2026-10-23).**
- Tests on `main` (measured 2026-10-24): `uv run pytest tests/python -q` gives
  **149 passed, 6 skipped** (the skips need local dbt artifacts). `uv run ruff check .`
  and `uv run ty check` are both clean, and CI's lint job now runs `ty check`.
  The hermetic dbt build (CI's seeds + `--select` list from `.github/workflows/ci.yml`)
  now also covers the crime, permits and SNHD lineages; its node count was not
  re-measured here (it was 49/49 PASS on 2026-10-22, before those seeds were added).
- **`main` auto-deploys to Railway** (elvis.evanappel.me). A merge is a deploy.
- No open PRs. PR #34 (weekend 2026-10-24) merged the `redesign-neon-phase1` branch
  (theme contract test) and all six weekend tasks below. PR #35 bumped Tiresias to
  v0.1.1 and confirmed the v0.1.0 ledger entry and key guardrail.
- There is no repo `CLAUDE.md`. The house rules come from `~/Documents/portfolio/CLAUDE.md`.
- `RECRUITER-PRIMER.md` is gitignored. It exists only in the main checkout, so read it there if you need it.

### Autonomous tasks

**None queued.** Every task from the 2026-10-24 weekend list merged in PR #34:
1. ~~PR for `redesign-neon-phase1`~~ (merged in #34).
2. ~~TASKS.md tidy~~ (#34).
3. ~~Unit tests for the `build_warehouse.py` pure helpers~~ (`tests/python/test_build_helpers.py`, #34;
   it also fixed water points whose centroid lacks a latitude).
4. ~~Expand hermetic CI seed coverage~~ (crime, permits, SNHD seeds + dbt tests, #34).
5. ~~Bring `ty check` to zero and gate it in CI~~ (#34).
6. ~~Phase 1 source discovery, metadata only~~ (`docs/COVERAGE.md`, #34). Choosing which
   candidates to build is Evan's call and sits in `BLOCKED.md`.

The open `- [ ]` items left in `TASKS.md` are Evan-owned (visual/source review, ledger
confirmation, live-data hardening, the analytics-engineering doc), Phase 4 source batches
that wait on his Phase 1 source pick in `BLOCKED.md`, or Phase 5 release validation.
No new autonomous list has been written; check `BLOCKED.md` and `TASKS.md` (and ask Evan)
before starting anything new.

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
