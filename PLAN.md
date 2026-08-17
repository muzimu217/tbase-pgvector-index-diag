# OpenTenBase pgvector Index Diagnostics Hardening Plan

## Selected idea

Harden the existing diagnostic package before replacing its inaccurate IVFFlat
memory model. W0 fixes public documentation, PostgreSQL memory-unit semantics,
shell-to-SQL input validation, function search paths, schema version tracking,
and delivery hygiene without changing the diagnostic output contract.

## Run contract

- Run ID: `index-diag-w0-hardening-v1`
- Tier: `auxiliary/dev`
- Branch: `muzimu217/index-diagnostics-hardening`
- Baseline: repository commit `191d9f3` plus the separately committed TAP
  baseline `3780054`
- Question: can the existing tool reject unsafe inputs and interpret PostgreSQL
  memory settings correctly while preserving its four-column diagnostic output?
- Null hypothesis: the fixes do not prevent unsafe SQL construction or still
  misclassify bare PostgreSQL memory values.
- Alternative hypothesis: invalid numeric inputs are rejected before `psql`, a
  bare value such as `65536` is interpreted as 64 MB, and all SQL functions use
  a fixed trusted search path.
- Primary acceptance signals: shell syntax passes; injection input is rejected
  without invoking `psql`; SQL patch parses and applies; static assertions find
  the corrected unit branch, fixed search paths, and schema version table.
- Stop condition: all T2.0.1 through T2.0.8 checks pass, or a public output field
  must change and requires a separate design decision.
- Runtime budget: bounded local validation only; no performance claim or main
  benchmark is produced in W0.

## Planned changes

| Requirement | File | Validation |
|---|---|---|
| T2.0.1-T2.0.3 | `README.md`, `docs/pgvector-index-diagnostics-report.md` | referenced paths exist and PR history is accurate |
| T2.0.4-T2.0.5 | `patches/pgvector-ivfflat-diagnostics-tools.patch` | bare `65536` maps to 64 MB; lowercase unit branches only |
| T2.0.6 | `scripts/pgvector-index-diagnostics.sh` | numeric whitelist tests, including SQL injection rejection |
| T2.0.7 | SQL patch | fixed `search_path`; schema version table and row |
| T2.0.8 | repository root | agent configuration files are no longer tracked |

## Evidence boundary

W0 establishes correctness and security preconditions only. The old build-memory
formula remains deprecated and must not support a production accuracy claim;
W1 will replace it from the 11 source allocations in `ivfkmeans.c` and validate
it against measured pgvector errors.

## Revision log

| Date | Change | Reason |
|---|---|---|
| 2026-08-18 | Create W0 hardening contract | R006 requires project two to start immediately after R-1 through R-3 |
| 2026-08-18 | Complete W0 validation | Input rejection, SQL patch application, and transactional OpenTenBase checks passed |
