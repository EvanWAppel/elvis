# BLOCKED — what I need from Evan

- [x] **Historical CLV business-license build failure bypassed** — the current code disables that empty feed and its dependent models. The full local build passes; missing Las Vegas license coverage remains documented in `docs/COVERAGE.md`.
- [x] **CI PR push authorized** — Evan requested the valley-expansion PR; its branch includes the expanded hermetic checks. Earlier CI work is already present on `main`.

- [ ] 🔴 **Enable GitHub Pages for the dbt docs site (P5)** — the `dbt docs` workflow (`.github/workflows/docs.yml`) builds and deploys the docs, but Pages isn't enabled yet (I'm blocked from enabling it — it's a public-publish action). Turn it on with source = "GitHub Actions", either in the repo UI (Settings → Pages → Source: GitHub Actions) or in one command:
      `gh api -X POST repos/EvanWAppel/elvis/pages -f build_type=workflow`
      Once enabled, the next push to `main` publishes to <https://evanwappel.github.io/elvis/> (the URL already linked from the landing page + README). Safe: the repo is already public and the docs contain only model/column metadata.
- [ ] 🟡 **Nevada 511 API key for local dev (`NVROADS_API_KEY`)** — already set in Railway prod and verified live (24 events). For local testing, request a free rate-limited key at https://nvroads.com/developer. Optional if a keyless build is acceptable.

- [ ] 🟡 **Review the first tract-map increment before release** — per portfolio `CLAUDE.md` (“The human inspects the data” and “The agent drafts the entry; the human confirms it”), review `docs/COVERAGE.md` against its linked official sources and the new Compare Census Tracts page, then confirm or amend the 2026-09-26 draft entry in `DECISIONS.md`. Check the 2020 population/municipal vintage, whole-tract city filtering, incomplete police coverage, and source status/date warnings. Automated tests process data without displaying raw records; this review is required before release, not a blocker for continued local source work.
