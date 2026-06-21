# Agent Task Delegation: Project 2

## Mission

This agent owns `pgvector` IVFFlat index build and diagnostics enhancement. The goal is to help users discover unreasonable index parameters, low recall risk, slow builds, and memory pressure before these problems become production incidents.

## Inputs

- Repository: `tbase-pgvector-index-diag`
- Upstream package repo: `OpenTenBase-Packages`
- Existing report: `docs/pgvector-index-diagnostics-report.md`
- Existing SOP: `SOP.md`
- Project 1 benchmark results for recall/latency evidence
- Public submission PR: `CDUESTC-OpenAtom-Open-Source-Club/OpenTenBase-Packages#28`

## Agent Roles

### Diagnostic SQL Agent

1. Maintain SQL functions for memory parsing, build memory estimation, `lists` recommendation, risk classification, and IVFFlat index inventory.
2. Keep output fields stable enough for scripts and reports.
3. Add sample invocations for low-memory, low-probes, full-scan-risk, and healthy configurations.

### Validation Agent

1. Run the diagnostic workflow against local and OpenTenBase environments.
2. Capture positive and negative cases:
   - `maintenance_work_mem` too low
   - `probes/lists` too low
   - `probes = lists`
   - missing or invalid IVFFlat index
   - query form that fails to use the index
3. Store validation logs under `docs/`.

### Heuristic Agent

1. Improve parameter recommendations with evidence from Project 1 and new tests.
2. Label every recommendation with confidence and risk.
3. Avoid claiming deterministic recall guarantees from empirical rules.

### Report Agent

1. Maintain the tuning template and technical report.
2. Include concrete SQL commands, expected output patterns, and production response guidance.
3. Add tables or figures only when backed by validation data.

## Required Commands

```bash
git status --short --branch
docker compose up -d
psql -d postgres -f sql/pgvector_ivfflat_diagnostics.sql
DBNAME=postgres ./scripts/pgvector-index-diagnostics.sh
```

Adapt paths to the upstream package layout if the SQL file is embedded through a patch.

## Deliverables

- Diagnostic SQL or extension patch
- Diagnostic runner script
- TAP or regression tests where practical
- Local and OpenTenBase validation logs
- Parameter tuning guide
- PR link and issue notes for upstream package problems

## Acceptance Criteria

- A user can identify memory risk before index build.
- A user can identify obvious low-recall risk from `lists/probes`.
- A user can list IVFFlat indexes and confirm expected query usage.
- Every warning includes an actionable next step.

## Stop And Ask

Stop before proceeding if:

- Diagnostic output would require changing public SQL fields already used by scripts.
- A recommendation contradicts measured benchmark data.
- OpenTenBase and vanilla PostgreSQL behavior diverge in a way that affects correctness.
- The tool cannot distinguish a healthy case from a risky case.
