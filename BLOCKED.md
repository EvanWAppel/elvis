# BLOCKED — what I need from Evan

- [ ] 🔴 **Paused-deploy decision (TASKS "Deploy — PAUSED")** — the City of Las Vegas `Business_Licenses_OpenData` ArcGIS layer returned zero rows on the 2026-08-15 build (had data Aug 13; sibling sources healthy). Decide: (a) wait for the City to repopulate, (b) make the build resilient to empty sources (type metadata + WARNING, keep dbt happy on 0-row raw), or (c) retry now (will fail identically). The Aug 13 live deploy is unaffected.
- [ ] 🔴 **Authorize the CI PR push (P1)** — the CI branch with hermetic `dbt seed` + `ruff` checks is written but not pushed. Confirm/push and open the PR so GitHub Actions runs the checks (currently only local manual verification).
- [ ] 🟡 **Nevada 511 API key for local dev (`NVROADS_API_KEY`)** — already set in Railway prod and verified live (24 events). For local testing, request a free rate-limited key at https://nvroads.com/developer. Optional if a keyless build is acceptable.
