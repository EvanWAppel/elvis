# Review — ArcGIS retry + Dockerfile key-log fix (2026-10-04)

**Change under review:** commit `6744d98`, branch `fix/build-retry-and-key-leak`.
**Reviewer:** Claude Opus, fresh context, read-only (no `.env`, no data, no
live build). **Adjudication:** Evan, 2026-10-04. No high-severity findings.

| # | Sev | Finding | Decision | Outcome |
|---|---|---|---|---|
| 1 | med | Removing the inline `VAR=${VAR}` stops the key printing in **logs**, but a declared `ARG` value is still recorded in the image's history metadata (`RUN \|1 NVROADS_API_KEY=… …`) in Railway's private registry. A BuildKit secret mount would remove it. | Wording fixed; secret mount not attempted (only a live Railway build could verify it) | BLOCKED/DECISIONS/Dockerfile comment now say "logs fixed, image history still holds it"; rotation still recommended |
| 2 | med | `RemoteDisconnected` / `ConnectionResetError` (raised outside urllib's `URLError` wrapper) and `IncompleteRead` were not retried. | Fix | Added `ConnectionError` and `http.client.IncompleteRead` to the transient set, with tests |
| 3 | low | Some permanent `URLError`s (DNS, SSL) are retried (bounded ~30s); ArcGIS "Unable to complete operation" (code 400) is not. | Accepted as-is | — |
| 4 | low | `fetch_layer` / `_get_json` (crime, permits, art, fire) had no retry **and** treated an ArcGIS error body as "no more pages", silently truncating the table. | Fix | `_get_json` routes through `_arcgis_get`; `fetch_layer` fails when `features` is missing; tests for retry, error body, missing key |
| 5 | low | DECISIONS wording didn't match the code's retry scope. | Fix | Reworded |
| 6 | low | HTTPError response socket not closed before backoff; worst-case time not stated. | Fix (close) | `exc.close()`; worst case (~9.5 min/request when a source is already failing) noted in DECISIONS |
| 7 | low | Tests didn't pin the 10s/20s schedule, missed URLError/connection cases and the log line; fixture docstring wrong. | Fix | Exact schedule, no sleep after final failure, connection cases, `caplog`, docstring |
