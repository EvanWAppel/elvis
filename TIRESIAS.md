# Tiresias

The "Ask Tiresias" page is a grounded text-to-SQL agent over the Elvis marts. It
cites its SQL and abstains when it can't ground an answer in a real row.

The engine moved to its own library: **https://github.com/EvanWAppel/tiresias**
(planning docs, decision log, and the Phase 0–3 history built here). Elvis pins a
release in `pyproject.toml` / `requirements.txt` and keeps only its city config:

- `tiresias.yml`: allowed tables, map-only columns, examples, planner notes,
  grounding threshold (with calibration notes), limits.
- `metrics.yml`: governed metric registry.
- `evals/tiresias_gold.yaml` and `evals/tiresias_retrieval_gold.yaml`: gold sets.

```
uv run tiresias check                              # config vs dbt artifacts
uv run tiresias eval --retrieval-only              # recall@k, no key needed
uv run --env-file .env tiresias eval               # + live gold set (dedicated key)
uv run tiresias calibrate                          # pick the grounding threshold
```
