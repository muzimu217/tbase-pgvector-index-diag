# Repository Guidelines

## Project Structure & Module Organization

This repository contains project-two pgvector index diagnostics materials. `README.md` gives the project overview, and `SOP.md` defines the repeatable diagnostic workflow. Reports and tuning guidance live in `docs/`, validation logs in `docs/diagnostic-results/`, source patches in `patches/`, and runnable helpers in `scripts/`.

## Build, Test, and Development Commands

Apply diagnostics to an OpenTenBase source tree:

```bash
git apply patches/pgvector-ivfflat-diagnostics-tools.patch
```

Load the SQL diagnostics:

```bash
psql -d postgres -f contrib/pgvector/bench/ivfflat_diagnostics.sql
```

Run the wrapper:

```bash
DBNAME=postgres ROW_COUNT=100000 DIMS=128 LISTS=1000 PROBES=10 \
  TARGET_RECALL=0.90 MAINTENANCE_WORK_MEM=64MB \
  scripts/pgvector-index-diagnostics.sh
```

Check scripts with `bash -n scripts/pgvector-index-diagnostics.sh`.

## Coding Style & Naming Conventions

Use lowercase SQL function names under `pgvector_bench`. Return diagnostic rows with `check_name`, `status`, `detail`, and `recommendation`. Shell scripts should use `set -euo pipefail` and environment-variable configuration.

## Testing Guidelines

Cover low-memory, reasonable-memory, low-probes, and index-inventory scenarios. Save validation output under `docs/diagnostic-results/`. Do not mark heuristic recommendations as guaranteed performance.

## Commit & Pull Request Guidelines

Use imperative commit messages, for example `Add pgvector index diagnostics`. PRs must include SQL loaded, commands run, expected risk states, and whether validation used OpenTenBase or local PostgreSQL.

## Security & Configuration Tips

Never commit credentials. Use `PGHOST`, `PGPORT`, `PGUSER`, and `PGPASSWORD` only through the runtime environment.

